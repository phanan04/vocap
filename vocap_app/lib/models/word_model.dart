import '../core/constants/supabase_constants.dart';

/// Represents a single Oxford 5000 vocabulary record with full IELTS metadata
class WordModel {
  final int id;
  final String word;
  final String type;
  final String cefr;
  final String ieltsBand;
  final String? phonBr;
  final String? phonNAm;
  final String meaningVi;
  final String definition;
  final String example;
  final String exampleVi;
  final List<String> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final Map<String, dynamic> wordFamily;
  final String? uk;
  final String? us;
  final String topic;
  final String subtopic;
  final String? sessionType; // 'review' (Due SM-2) or 'new' (Adaptive New Word)

  WordModel({
    required this.id,
    required this.word,
    required this.type,
    required this.cefr,
    required this.ieltsBand,
    this.phonBr,
    this.phonNAm,
    required this.meaningVi,
    required this.definition,
    required this.example,
    required this.exampleVi,
    required this.collocations,
    required this.synonyms,
    required this.antonyms,
    required this.wordFamily,
    this.uk,
    this.us,
    required this.topic,
    required this.subtopic,
    this.sessionType,
  });

  /// Audio URL streamed from Supabase CDN
  String get audioUrl => SupabaseConstants.getAudioUrl(us);
  String get ukAudioUrl => SupabaseConstants.getAudioUrl(uk);

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as int,
      word: json['word'] as String? ?? '',
      type: json['type'] as String? ?? '',
      cefr: (json['cefr'] as String? ?? 'b1').toUpperCase(),
      ieltsBand: json['ielts_band'] as String? ?? '5.5 - 6.0',
      phonBr: json['phon_br'] as String?,
      phonNAm: json['phon_n_am'] as String?,
      meaningVi: json['meaning_vi'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      example: json['example'] as String? ?? '',
      exampleVi: json['example_vi'] as String? ?? '',
      collocations: (json['collocations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      synonyms: (json['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      antonyms: (json['antonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      wordFamily: json['word_family'] is Map
          ? Map<String, dynamic>.from(json['word_family'] as Map)
          : {},
      uk: json['uk'] as String?,
      us: json['us'] as String?,
      topic: json['topic'] as String? ?? 'General Vocabulary',
      subtopic: json['subtopic'] as String? ?? 'General',
      sessionType: json['session_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'type': type,
      'cefr': cefr,
      'ielts_band': ieltsBand,
      'phon_br': phonBr,
      'phon_n_am': phonNAm,
      'meaning_vi': meaningVi,
      'definition': definition,
      'example': example,
      'example_vi': exampleVi,
      'collocations': collocations,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'word_family': wordFamily,
      'uk': uk,
      'us': us,
      'topic': topic,
      'subtopic': subtopic,
    };
  }
}
