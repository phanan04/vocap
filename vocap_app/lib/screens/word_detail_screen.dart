import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../core/theme/app_theme.dart';
import '../widgets/audio_play_button.dart';
import '../widgets/ielts_band_badge.dart';
import '../services/supabase_service.dart';

class WordDetailScreen extends StatelessWidget {
  final WordModel word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(word.word),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IeltsBandBadge(band: word.ieltsBand, cefr: word.cefr),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headword Hero Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.word,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                word.type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (word.phonNAm != null) ...[
                                const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                                Text(
                                  word.phonNAm!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF38BDF8),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    AudioPlayButton(usAudioFile: word.us, size: 52),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Mark as Known Button
            OutlinedButton.icon(
              onPressed: () async {
                await SupabaseService().markWordAsKnown(word.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Đã đánh dấu "${word.word}" là đã thuộc. Từ sẽ không xuất hiện trong bài ôn tập.'),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.greenAccent),
              label: const Text(
                'Đã thuộc từ này (Không học lại nữa)',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: const BorderSide(color: Colors.greenAccent, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Vietnamese Meaning
            _buildSection(
              title: 'Nghĩa tiếng Việt',
              child: Text(
                word.meaningVi,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF34D399),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Oxford Definition
            _buildSection(
              title: 'Định nghĩa chuẩn Oxford',
              child: Text(
                word.definition,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ),
            const SizedBox(height: 16),

            // Examples
            _buildSection(
              title: 'Ví dụ ngữ cảnh IELTS',
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(left: BorderSide(color: AppTheme.primary, width: 3.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.example,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.exampleVi,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Collocations
            if (word.collocations.isNotEmpty) ...[
              _buildSection(
                title: 'Collocations điểm cao (Cụm từ hay)',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: word.collocations.map((col) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: Text(col, style: const TextStyle(fontSize: 13, color: Colors.white)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Synonyms & Antonyms
            if (word.synonyms.isNotEmpty || word.antonyms.isNotEmpty) ...[
              _buildSection(
                title: 'Từ đồng nghĩa & Trái nghĩa',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (word.synonyms.isNotEmpty) ...[
                      const Text('Đồng nghĩa:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: word.synonyms.map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD))),
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                        )).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (word.antonyms.isNotEmpty) ...[
                      const Text('Trái nghĩa:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: word.antonyms.map((a) => Chip(
                          label: Text(a, style: const TextStyle(fontSize: 12, color: Color(0xFFFCA5A5))),
                          backgroundColor: const Color(0xFF7F1D1D).withOpacity(0.3),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Topic info
            _buildSection(
              title: 'Chủ đề IELTS',
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text('${word.topic} • ${word.subtopic}', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
