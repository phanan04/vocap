import 'word_model.dart';

/// Tracks a user's SuperMemo-2 SRS progress for a specific word
class UserWordModel {
  final String id;
  final String userId;
  final int wordId;
  final String status; // 'learning', 'reviewing', 'mastered'
  final double easeFactor; // SM-2 EF, default 2.5
  final int intervalDays; // Interval in days
  final int repetitions; // Successful repetitions in a row
  final DateTime nextReview;
  final DateTime? lastReviewed;
  final WordModel? word;

  UserWordModel({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.status,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReview,
    this.lastReviewed,
    this.word,
  });

  bool get isDue => DateTime.now().isAfter(nextReview);

  factory UserWordModel.fromJson(Map<String, dynamic> json) {
    return UserWordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      wordId: json['word_id'] as int,
      status: json['status'] as String? ?? 'learning',
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['interval_days'] as int? ?? 1,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReview: DateTime.parse(json['next_review'] as String),
      lastReviewed: json['last_reviewed'] != null
          ? DateTime.parse(json['last_reviewed'] as String)
          : null,
      word: json['words'] != null
          ? WordModel.fromJson(json['words'] as Map<String, dynamic>)
          : null,
    );
  }
}
