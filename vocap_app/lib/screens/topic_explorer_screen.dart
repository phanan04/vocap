import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/audio_play_button.dart';
import '../widgets/ielts_band_badge.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'word_detail_screen.dart';

class TopicExplorerScreen extends StatefulWidget {
  const TopicExplorerScreen({super.key});

  @override
  State<TopicExplorerScreen> createState() => _TopicExplorerScreenState();
}

class _TopicExplorerScreenState extends State<TopicExplorerScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _topics = [];
  List<WordModel> _results = [];
  int _totalCount = 0;
  bool _isLoadingTopics = true;
  bool _isLoadingWords = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 50;

  // Filter criteria state
  String _selectedBand = 'All';
  String _selectedCefr = 'All';
  String _selectedPos = 'All'; // Part of speech: noun, verb, adjective, adverb
  String _selectedSort = 'id_asc';
  bool _onlyCollocations = false;
  bool _onlyBookmarked = false;

  final List<String> _bands = [
    'All',
    '1.0 - 2.5',
    '3.0 - 3.5',
    '4.0 - 5.0',
    '5.5 - 6.5',
    '7.0 - 8.0',
    '8.5 - 9.0',
  ];
  final List<String> _cefrs = ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final List<Map<String, String>> _posList = [
    {'value': 'All', 'label': 'Tất cả từ loại'},
    {'value': 'noun', 'label': 'Danh từ (n)'},
    {'value': 'verb', 'label': 'Động từ (v)'},
    {'value': 'adjective', 'label': 'Tính từ (adj)'},
    {'value': 'adverb', 'label': 'Trạng từ (adv)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadTopics(band: 'All');
    _applyFilters();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreWords();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedBand != 'All' ||
      _selectedCefr != 'All' ||
      _selectedPos != 'All' ||
      _onlyCollocations ||
      _onlyBookmarked ||
      _selectedSort != 'id_asc';

  int get _activeFilterCount {
    int count = 0;
    if (_selectedBand != 'All') count++;
    if (_selectedCefr != 'All') count++;
    if (_selectedPos != 'All') count++;
    if (_onlyCollocations) count++;
    if (_onlyBookmarked) count++;
    if (_selectedSort != 'id_asc') count++;
    return count;
  }

  Future<void> _loadTopics({String? band}) async {
    setState(() => _isLoadingTopics = true);
    final targetBand = (band != null && band != 'All') ? band : 'All';
    final topics = await _supabaseService.getTopicsWithCounts(band: targetBand);
    if (mounted) {
      setState(() {
        _topics = topics;
        _isLoadingTopics = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isNotEmpty && _tabController.index != 1) {
      _tabController.animateTo(1);
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoadingWords = true;
      _isLoadingMore = false;
    });

    final res = await _supabaseService.filterWordsWithCount(
      query: _searchController.text.trim(),
      band: _selectedBand,
      cefr: _selectedCefr,
      type: _selectedPos,
      hasCollocations: _onlyCollocations,
      sortBy: _selectedSort,
      limit: _pageSize,
      offset: 0,
    );

    List<WordModel> words = (res['words'] as List<WordModel>?) ?? [];
    int total = (res['total'] as int?) ?? 0;

    if (_onlyBookmarked) {
      final bookmarkedIds = await _supabaseService.offlineService.getLocalBookmarkedIds();
      words = words.where((w) => bookmarkedIds.contains(w.id)).toList();
      total = words.length;
    }

    if (mounted) {
      setState(() {
        _results = words;
        _totalCount = total;
        _isLoadingWords = false;
      });
    }
  }

  Future<void> _loadMoreWords() async {
    if (_isLoadingMore || _isLoadingWords || _results.length >= _totalCount) {
      return;
    }

    setState(() => _isLoadingMore = true);

    final res = await _supabaseService.filterWordsWithCount(
      query: _searchController.text.trim(),
      band: _selectedBand,
      cefr: _selectedCefr,
      type: _selectedPos,
      hasCollocations: _onlyCollocations,
      sortBy: _selectedSort,
      limit: _pageSize,
      offset: _results.length,
    );

    if (mounted) {
      final newWords = (res['words'] as List<WordModel>?) ?? [];
      setState(() {
        _results.addAll(newWords);
        _totalCount = (res['total'] as int?) ?? _totalCount;
        _isLoadingMore = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedBand = 'All';
      _selectedCefr = 'All';
      _selectedPos = 'All';
      _selectedSort = 'id_asc';
      _onlyCollocations = false;
      _onlyBookmarked = false;
      _searchController.clear();
      _results = [];
      _totalCount = 0;
      _isLoadingMore = false;
    });
    _loadTopics(band: 'All');
    _applyFilters();
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune, color: AppTheme.primary, size: 22),
                      SizedBox(width: 8),
                      Text('Bộ Lọc Nâng Cao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedBand = 'All';
                        _selectedCefr = 'All';
                        _selectedPos = 'All';
                        _selectedSort = 'id_asc';
                        _onlyCollocations = false;
                      });
                      setState(() {});
                      _applyFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Đặt lại', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFF334155)),

              // 1. Part of Speech (Từ loại)
              const Text('Từ loại (Part of Speech):', style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _posList.map((pos) {
                  final isSelected = (_selectedPos == pos['value']);
                  return ChoiceChip(
                    label: Text(pos['label']!),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) {
                      setModalState(() => _selectedPos = pos['value']!);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 2. CEFR Level
              const Text('Cấp độ Khung Châu Âu (CEFR):', style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _cefrs.map((c) {
                  final isSelected = (_selectedCefr == c);
                  return ChoiceChip(
                    label: Text(c == 'All' ? 'Tất cả' : c),
                    selected: isSelected,
                    selectedColor: AppTheme.accent,
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) {
                      setModalState(() => _selectedCefr = c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 3. Collocations Only Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Chỉ từ có Collocations điểm cao', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Ưu tiên từ vựng có cụm từ ăn điểm Writing & Speaking', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                value: _onlyCollocations,
                activeThumbColor: AppTheme.primary,
                onChanged: (val) {
                  setModalState(() => _onlyCollocations = val);
                },
              ),
              const SizedBox(height: 8),

              // 4. Bookmarked Only Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Chỉ từ trong Sổ tay yêu thích ⭐', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Xem các từ vựng bạn đã đánh dấu bookmark', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                value: _onlyBookmarked,
                activeThumbColor: Colors.amber,
                onChanged: (val) {
                  setModalState(() => _onlyBookmarked = val);
                },
              ),
              const SizedBox(height: 8),

              // 4. Sort Order
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sắp xếp theo:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedSort,
                    dropdownColor: AppTheme.surfaceDark,
                    items: const [
                      DropdownMenuItem(value: 'id_asc', child: Text('Mặc định (A-Z)')),
                      DropdownMenuItem(value: 'word_desc', child: Text('Ngược lại (Z-A)')),
                      DropdownMenuItem(value: 'cefr_asc', child: Text('Cấp độ (Dễ ➔ Khó)')),
                      DropdownMenuItem(value: 'cefr_desc', child: Text('Cấp độ (Khó ➔ Dễ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _selectedSort = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Apply Button
              ElevatedButton(
                onPressed: () {
                  _tabController.animateTo(1);
                  _applyFilters();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Áp Dụng Bộ Lọc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTopicWords(String topic, {String? band}) async {
    final effectiveBand = (band != null && band != 'All') ? band : null;
    final words = await _supabaseService.getWordsByTopic(
      topic,
      band: effectiveBand,
      limit: 1000,
    );

    if (!mounted) return;

    final sheetTitle = effectiveBand != null
        ? '$topic • Band $effectiveBand'
        : topic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$sheetTitle (${words.length} từ vựng)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FlashcardScreen(words: words, title: sheetTitle),
                              ),
                            );
                          },
                          icon: const Icon(Icons.style, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Học Flashcard', maxLines: 1, softWrap: false),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(
                                  words: words.take(20).toList(),
                                  distractorPool: words,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.quiz, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Luyện Quiz', maxLines: 1, softWrap: false),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: words.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
                itemBuilder: (_, idx) {
                  final w = words[idx];
                  return ListTile(
                    title: Text(w.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${w.type} • ${w.meaningVi}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IeltsBandBadge(band: w.ieltsBand, cefr: w.cefr),
                        const SizedBox(width: 8),
                        AudioPlayButton(usAudioFile: w.us, size: 36),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WordDetailScreen(word: w)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: SizedBox(
          height: 42,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(_topics.isNotEmpty ? 'Chủ Đề (${_topics.length})' : 'Chủ Đề'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.format_list_bulleted_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(_totalCount > 0 ? 'Tất Cả Từ ($_totalCount)' : 'Tất Cả Từ'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear_all, size: 20, color: Colors.redAccent),
              tooltip: 'Xóa bộ lọc',
            ),
        ],
      ),
      body: Column(
        children: [
          // Compact Search & Filter Row (Height: 40px)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tìm từ tiếng Anh hoặc nghĩa tiếng Việt...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surfaceDark,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0
                              ? AppTheme.primary.withOpacity(0.2)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _activeFilterCount > 0
                                ? AppTheme.primary
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.tune,
                            size: 18,
                            color: _activeFilterCount > 0 ? AppTheme.primary : Colors.white,
                          ),
                          tooltip: 'Bộ lọc nâng cao',
                          onPressed: _openFilterBottomSheet,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Mini Band Pills (Height: 30px)
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final band = _bands[idx];
                final isSelected = (_selectedBand == band);
                return InkWell(
                  onTap: () {
                    setState(() => _selectedBand = band);
                    _loadTopics(band: band);
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      band == 'All' ? 'Tất cả' : band,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // TabBarView Content (Swipeable)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopicsGrid(),
                _buildFilteredResultsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredResultsView() {
    if (_isLoadingWords) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('Không tìm thấy từ vựng phù hợp.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Thử thay đổi từ khóa hoặc điều chỉnh lại bộ lọc.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Xóa tất cả bộ lọc'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Action Bar for filtered set
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tìm thấy $_totalCount từ vựng (Đã tải ${_results.length}/$_totalCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlashcardScreen(words: _results, title: 'Kết quả lọc'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.style, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Học thẻ này', maxLines: 1, softWrap: false),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            words: _results.take(20).toList(),
                            distractorPool: _results,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.quiz, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Luyện Quiz', maxLines: 1, softWrap: false),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF334155)),

        // Results List with Infinite Scrolling
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: _results.length + (_isLoadingMore ? 1 : (_results.length < _totalCount ? 1 : 0)),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, idx) {
              if (idx == _results.length) {
                if (_isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: _loadMoreWords,
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: Text('Tải thêm (${_results.length}/$_totalCount)'),
                      ),
                    ),
                  );
                }
              }

              final w = _results[idx];
              return Card(
                child: ListTile(
                  title: Text(w.word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text('${w.type} • ${w.meaningVi}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IeltsBandBadge(band: w.ieltsBand, cefr: w.cefr),
                      const SizedBox(width: 8),
                      AudioPlayButton(usAudioFile: w.us, size: 36),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WordDetailScreen(word: w)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsGrid() {
    if (_isLoadingTopics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'Không có chủ đề nào cho Band $_selectedBand',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _selectedBand = 'All');
                _loadTopics(band: 'All');
                _applyFilters();
              },
              child: const Text('Xem tất cả Band'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
      itemCount: _topics.length,
      itemBuilder: (_, idx) {
        final item = _topics[idx];
        final topicName = item['topic'] as String;
        final count = item['count'] as int;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: InkWell(
            onTap: () => _openTopicWords(topicName, band: _selectedBand),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.school_outlined, color: AppTheme.primary, size: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count từ',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    topicName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
            ),
          ),
        );
      },
    );
  }
}
