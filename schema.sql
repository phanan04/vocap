-- ==============================================================================
-- VOCAP DATABASE SCHEMA (SUPABASE POSTGRESQL)
-- Version: 1.0.0
-- Master Data: Oxford 5000 (5,943 words, 19 fields, US Audio)
-- Algorithm: SuperMemo-2 (SM-2) Spaced Repetition System (SRS)
-- ==============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ------------------------------------------------------------------------------
-- 1. MASTER TABLE: WORDS (5,943 Oxford 5000 records)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.words (
    id SERIAL PRIMARY KEY,
    word TEXT NOT NULL,
    type TEXT NOT NULL,
    cefr TEXT NOT NULL,
    ielts_band TEXT NOT NULL,
    phon_br TEXT,
    phon_n_am TEXT,
    meaning_vi TEXT NOT NULL,
    definition TEXT NOT NULL,
    example TEXT NOT NULL,
    example_vi TEXT NOT NULL,
    collocations TEXT[] DEFAULT '{}',
    synonyms TEXT[] DEFAULT '{}',
    antonyms TEXT[] DEFAULT '{}',
    word_family JSONB DEFAULT '{}'::jsonb,
    uk TEXT,
    us TEXT,
    topic TEXT NOT NULL,
    subtopic TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Indexes for lightning-fast search and filtering
CREATE INDEX IF NOT EXISTS idx_words_word ON public.words (word);
CREATE INDEX IF NOT EXISTS idx_words_topic ON public.words (topic);
CREATE INDEX IF NOT EXISTS idx_words_subtopic ON public.words (subtopic);
CREATE INDEX IF NOT EXISTS idx_words_cefr ON public.words (cefr);
CREATE INDEX IF NOT EXISTS idx_words_ielts_band ON public.words (ielts_band);
CREATE INDEX IF NOT EXISTS idx_words_trgm ON public.words USING gin (word gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_words_meaning_trgm ON public.words USING gin (meaning_vi gin_trgm_ops);

-- ------------------------------------------------------------------------------
-- 2. USER PROFILES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    target_band TEXT DEFAULT '6.5',
    current_band TEXT DEFAULT '5.5',
    daily_target INT DEFAULT 10 CHECK (daily_target > 0),
    preferred_topics TEXT[] DEFAULT '{}',
    streak_count INT DEFAULT 0 CHECK (streak_count >= 0),
    last_active_date DATE,
    xp_points INT DEFAULT 0 CHECK (xp_points >= 0),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Trigger to create profile automatically on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 3. USER WORDS (SPACED REPETITION ENGINE - SM-2)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    word_id INT NOT NULL REFERENCES public.words(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'learning' CHECK (status IN ('new', 'learning', 'reviewing', 'mastered')),
    ease_factor NUMERIC(4,2) DEFAULT 2.50 CHECK (ease_factor >= 1.30),
    interval_days INT DEFAULT 0 CHECK (interval_days >= 0),
    repetitions INT DEFAULT 0 CHECK (repetitions >= 0),
    next_review_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    last_reviewed_at TIMESTAMPTZ,
    is_bookmarked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(user_id, word_id)
);

CREATE INDEX IF NOT EXISTS idx_user_words_due ON public.user_words (user_id, next_review_at);
CREATE INDEX IF NOT EXISTS idx_user_words_status ON public.user_words (user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_words_bookmarked ON public.user_words (user_id, is_bookmarked);

-- ------------------------------------------------------------------------------
-- 4. DAILY STUDY LOGS & STREAK TRACKING
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.study_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    study_date DATE DEFAULT CURRENT_DATE NOT NULL,
    words_reviewed INT DEFAULT 0,
    words_learned INT DEFAULT 0,
    xp_earned INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(user_id, study_date)
);

CREATE INDEX IF NOT EXISTS idx_study_logs_date ON public.study_logs (user_id, study_date);

-- ------------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_logs ENABLE ROW LEVEL SECURITY;

-- Words: Public readable by everyone
CREATE POLICY "Words are readable by all authenticated and anon users"
    ON public.words FOR SELECT
    USING (true);

-- Profiles: Users can view and update their own profile
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- User Words: Users can view, insert, update their own progress
CREATE POLICY "Users can view own learning words"
    ON public.user_words FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own learning words"
    ON public.user_words FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own learning words"
    ON public.user_words FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own learning words"
    ON public.user_words FOR DELETE
    USING (auth.uid() = user_id);

-- Study Logs: Users can view and manage their own logs
CREATE POLICY "Users can manage own study logs"
    ON public.study_logs FOR ALL
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 6. RPC FUNCTION: SUBMIT SRS REVIEW (SM-2 ALGORITHM)
-- Rating scale:
-- 1 = Again (Forgot)
-- 2 = Hard
-- 3 = Good
-- 4 = Easy
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_srs_review(
    p_word_id INT,
    p_rating INT
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_rec RECORD;
    v_ease NUMERIC(4,2);
    v_interval INT;
    v_reps INT;
    v_status TEXT;
    v_next_review TIMESTAMPTZ;
    v_today DATE := CURRENT_DATE;
    v_xp INT := 10;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_rating < 1 OR p_rating > 4 THEN
        RAISE EXCEPTION 'Invalid rating. Expected 1 (Again), 2 (Hard), 3 (Good), 4 (Easy).';
    END IF;

    -- Fetch current progress
    SELECT * INTO v_rec FROM public.user_words
    WHERE user_id = v_user_id AND word_id = p_word_id;

    IF NOT FOUND THEN
        -- First time learning this word
        v_ease := 2.50;
        v_reps := 0;
        v_interval := 0;
    ELSE
        v_ease := v_rec.ease_factor;
        v_reps := v_rec.repetitions;
        v_interval := v_rec.interval_days;
    END IF;

    -- Apply SM-2 calculation
    IF p_rating = 1 THEN
        -- Again: Reset repetitions, review again in 10 minutes (or same day)
        v_reps := 0;
        v_interval := 0;
        v_next_review := NOW() + INTERVAL '10 minutes';
        v_status := 'learning';
        v_ease := GREATEST(1.30, v_ease - 0.20);
        v_xp := 2;
    ELSE
        -- Rating 2, 3, 4: Successful recall
        -- Update Ease Factor: EF' = EF + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))
        -- Mapping: 4 (Easy) -> grade 5; 3 (Good) -> grade 4; 2 (Hard) -> grade 3
        IF p_rating = 4 THEN
            v_ease := v_ease + 0.15;
            v_xp := 15;
        ELSIF p_rating = 3 THEN
            v_ease := v_ease + 0.00;
            v_xp := 10;
        ELSIF p_rating = 2 THEN
            v_ease := GREATEST(1.30, v_ease - 0.15);
            v_xp := 5;
        END IF;

        IF v_reps = 0 THEN
            v_interval := 1;
        ELSIF v_reps = 1 THEN
            v_interval := 3;
        ELSIF v_reps = 2 THEN
            v_interval := 6;
        ELSE
            v_interval := ROUND(v_interval * v_ease);
        END IF;

        -- Hard rating penalty to interval
        IF p_rating = 2 AND v_interval > 1 THEN
            v_interval := GREATEST(1, ROUND(v_interval * 0.8));
        ELSIF p_rating = 4 THEN
            v_interval := ROUND(v_interval * 1.3);
        END IF;

        v_reps := v_reps + 1;
        v_next_review := NOW() + (v_interval || ' days')::INTERVAL;

        IF v_interval >= 30 THEN
            v_status := 'mastered';
        ELSE
            v_status := 'reviewing';
        END IF;
    END IF;

    -- Upsert user_words
    INSERT INTO public.user_words (
        user_id, word_id, status, ease_factor, interval_days, repetitions,
        next_review_at, last_reviewed_at, updated_at
    )
    VALUES (
        v_user_id, p_word_id, v_status, v_ease, v_interval, v_reps,
        v_next_review, NOW(), NOW()
    )
    ON CONFLICT (user_id, word_id) DO UPDATE SET
        status = EXCLUDED.status,
        ease_factor = EXCLUDED.ease_factor,
        interval_days = EXCLUDED.interval_days,
        repetitions = EXCLUDED.repetitions,
        next_review_at = EXCLUDED.next_review_at,
        last_reviewed_at = EXCLUDED.last_reviewed_at,
        updated_at = NOW();

    -- Update daily study log
    INSERT INTO public.study_logs (user_id, study_date, words_reviewed, xp_earned)
    VALUES (v_user_id, v_today, 1, v_xp)
    ON CONFLICT (user_id, study_date) DO UPDATE SET
        words_reviewed = public.study_logs.words_reviewed + 1,
        xp_earned = public.study_logs.xp_earned + v_xp;

    -- Update user streak & XP in profiles
    UPDATE public.profiles
    SET 
        xp_points = xp_points + v_xp,
        streak_count = CASE 
            WHEN last_active_date IS NULL OR last_active_date < v_today - 1 THEN 1
            WHEN last_active_date = v_today - 1 THEN streak_count + 1
            ELSE streak_count
        END,
        last_active_date = v_today,
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'word_id', p_word_id,
        'status', v_status,
        'interval_days', v_interval,
        'next_review_at', v_next_review,
        'ease_factor', v_ease,
        'xp_earned', v_xp
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 7. RPC FUNCTION: GET WORDS DUE FOR REVIEW
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_due_words(p_limit INT DEFAULT 20)
RETURNS TABLE (
    word_id INT,
    word TEXT,
    type TEXT,
    cefr TEXT,
    ielts_band TEXT,
    phon_n_am TEXT,
    meaning_vi TEXT,
    definition TEXT,
    example TEXT,
    example_vi TEXT,
    collocations TEXT[],
    synonyms TEXT[],
    antonyms TEXT[],
    word_family JSONB,
    us TEXT,
    topic TEXT,
    subtopic TEXT,
    status TEXT,
    repetitions INT,
    interval_days INT,
    ease_factor NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        w.id AS word_id,
        w.word,
        w.type,
        w.cefr,
        w.ielts_band,
        w.phon_n_am,
        w.meaning_vi,
        w.definition,
        w.example,
        w.example_vi,
        w.collocations,
        w.synonyms,
        w.antonyms,
        w.word_family,
        w.us,
        w.topic,
        w.subtopic,
        uw.status,
        uw.repetitions,
        uw.interval_days,
        uw.ease_factor
    FROM public.user_words uw
    JOIN public.words w ON w.id = uw.word_id
    WHERE uw.user_id = auth.uid()
      AND uw.next_review_at <= NOW()
    ORDER BY uw.next_review_at ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 8. RPC FUNCTION: MARK WORD AS KNOWN / MASTERED
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_word_as_known(p_word_id INT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.user_words (
        user_id, word_id, status, ease_factor, interval_days, repetitions,
        next_review_at, last_reviewed_at, updated_at
    )
    VALUES (
        v_user_id, p_word_id, 'mastered', 2.50, 365, 5,
        NOW() + INTERVAL '365 days', NOW(), NOW()
    )
    ON CONFLICT (user_id, word_id) DO UPDATE SET
        status = 'mastered',
        interval_days = 365,
        repetitions = 5,
        next_review_at = NOW() + INTERVAL '365 days',
        last_reviewed_at = NOW(),
        updated_at = NOW();

    RETURN jsonb_build_object('success', true, 'status', 'mastered', 'word_id', p_word_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 9. RPC FUNCTION: GET TOPIC STATS
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_topic_stats(p_band TEXT DEFAULT 'All')
RETURNS TABLE (
    topic TEXT,
    word_count BIGINT
) AS $$
BEGIN
    IF p_band IS NULL OR p_band = '' OR p_band = 'All' THEN
        RETURN QUERY
        SELECT w.topic, COUNT(*)::BIGINT AS word_count
        FROM public.words w
        GROUP BY w.topic
        ORDER BY w.topic ASC;
    ELSE
        RETURN QUERY
        SELECT w.topic, COUNT(*)::BIGINT AS word_count
        FROM public.words w
        WHERE w.ielts_band = p_band
        GROUP BY w.topic
        ORDER BY w.topic ASC;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 10. RPC FUNCTION: SKIP WORDS BELOW BAND
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.skip_words_below_band(p_current_band TEXT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_skipped INT := 0;
    v_bands TEXT[];
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Determine which lower bands to skip
    IF p_current_band IN ('8.0', '8.5') THEN
        v_bands := ARRAY['1.0 - 2.5', '3.0 - 3.5', '4.0 - 5.0', '5.5 - 6.5', '7.0 - 8.0'];
    ELSIF p_current_band IN ('7.0', '7.5') THEN
        v_bands := ARRAY['1.0 - 2.5', '3.0 - 3.5', '4.0 - 5.0', '5.5 - 6.5'];
    ELSIF p_current_band IN ('6.0', '6.5') THEN
        v_bands := ARRAY['1.0 - 2.5', '3.0 - 3.5', '4.0 - 5.0'];
    ELSIF p_current_band IN ('5.0', '5.5') THEN
        v_bands := ARRAY['1.0 - 2.5', '3.0 - 3.5'];
    ELSIF p_current_band IN ('4.5') THEN
        v_bands := ARRAY['1.0 - 2.5'];
    ELSE
        RETURN jsonb_build_object('success', true, 'skipped_count', 0);
    END IF;

    INSERT INTO public.user_words (
        user_id, word_id, status, ease_factor, interval_days, repetitions,
        next_review_at, last_reviewed_at, updated_at
    )
    SELECT
        v_user_id, w.id, 'mastered', 2.50, 365, 5,
        NOW() + INTERVAL '365 days', NOW(), NOW()
    FROM public.words w
    WHERE w.ielts_band = ANY(v_bands)
    ON CONFLICT (user_id, word_id) DO NOTHING;

    GET DIAGNOSTICS v_skipped = ROW_COUNT;

    RETURN jsonb_build_object('success', true, 'skipped_count', v_skipped);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 11. RPC FUNCTION: GET SMART STUDY SESSION
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_smart_study_session(
    p_user_id UUID,
    p_target_band TEXT DEFAULT '6.5',
    p_limit INT DEFAULT 20,
    p_current_band TEXT DEFAULT '5.5'
)
RETURNS TABLE (
    id INT,
    word TEXT,
    type TEXT,
    cefr TEXT,
    ielts_band TEXT,
    phon_br TEXT,
    phon_n_am TEXT,
    meaning_vi TEXT,
    definition TEXT,
    example TEXT,
    example_vi TEXT,
    collocations TEXT[],
    synonyms TEXT[],
    antonyms TEXT[],
    word_family JSONB,
    uk TEXT,
    us TEXT,
    topic TEXT,
    subtopic TEXT,
    session_type TEXT
) AS $$
DECLARE
    v_actual_user_id UUID;
    v_due_count INT := 0;
BEGIN
    v_actual_user_id := COALESCE(p_user_id, auth.uid());

    -- Part 1: Due SM-2 review words
    IF v_actual_user_id IS NOT NULL THEN
        RETURN QUERY
        SELECT 
            w.id, w.word, w.type, w.cefr, w.ielts_band,
            w.phon_br, w.phon_n_am, w.meaning_vi, w.definition,
            w.example, w.example_vi, w.collocations, w.synonyms, w.antonyms,
            w.word_family, w.uk, w.us, w.topic, w.subtopic,
            'review'::TEXT AS session_type
        FROM public.user_words uw
        JOIN public.words w ON w.id = uw.word_id
        WHERE uw.user_id = v_actual_user_id
          AND uw.status IN ('learning', 'reviewing')
          AND uw.next_review_at <= NOW()
        ORDER BY uw.next_review_at ASC
        LIMIT p_limit;

        GET DIAGNOSTICS v_due_count = ROW_COUNT;
    END IF;

    -- Part 2: If we still need more words to meet p_limit, select adaptive new words
    IF v_due_count < p_limit THEN
        RETURN QUERY
        SELECT 
            w.id, w.word, w.type, w.cefr, w.ielts_band,
            w.phon_br, w.phon_n_am, w.meaning_vi, w.definition,
            w.example, w.example_vi, w.collocations, w.synonyms, w.antonyms,
            w.word_family, w.uk, w.us, w.topic, w.subtopic,
            'new'::TEXT AS session_type
        FROM public.words w
        WHERE (
            v_actual_user_id IS NULL OR 
            NOT EXISTS (
                SELECT 1 FROM public.user_words uw 
                WHERE uw.user_id = v_actual_user_id AND uw.word_id = w.id
            )
        )
        ORDER BY w.id ASC
        LIMIT (p_limit - v_due_count);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
