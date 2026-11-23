import 'package:shared_preferences/shared_preferences.dart';

class PlacementQuestion {
  final int id;
  final String word;
  final String type;
  final String phonetic;
  final String prompt;
  final String level;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const PlacementQuestion({
    required this.id,
    required this.word,
    required this.type,
    required this.phonetic,
    required this.prompt,
    required this.level,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class PlacementResult {
  final int score;
  final int totalQuestions;
  final String band;
  final String cefr;
  final String title;
  final String description;
  final String recommendation;
  final List<String> skippedLevels;

  const PlacementResult({
    required this.score,
    required this.totalQuestions,
    required this.band,
    required this.cefr,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.skippedLevels,
  });
}

class PlacementTestService {
  static const String _keyCompleted = 'has_completed_placement_test';
  static const String _keyAssessedBand = 'placement_assessed_band';
  static const String _keyScore = 'placement_test_score';

  static const List<PlacementQuestion> questions = [
    // --- LEVEL 1: A2 / Band 4.0 - 4.5 (3 questions) ---
    PlacementQuestion(
      id: 1,
      word: 'ability',
      type: 'noun',
      phonetic: '/əˈbɪləti/',
      prompt: 'Regular speaking practice will greatly improve your _____ to express ideas naturally.',
      level: 'A2 (Band 4.0 - 4.5)',
      options: ['khả năng, năng lực', 'sự nghi ngờ', 'thái độ', 'thói quen'],
      correctIndex: 0,
      explanation: '"ability" có nghĩa là khả năng hoặc năng lực làm một việc gì đó.',
    ),
    PlacementQuestion(
      id: 2,
      word: 'convenient',
      type: 'adjective',
      phonetic: '/kənˈviːniənt/',
      prompt: 'Public transport is very _____ because you do not have to worry about finding parking spaces.',
      level: 'A2 (Band 4.0 - 4.5)',
      options: ['nguy hiểm', 'tiện lợi, thuận tiện', 'tốn kém', 'khó khăn'],
      correctIndex: 1,
      explanation: '"convenient" có nghĩa là thuận tiện, tiện lợi cho sinh hoạt.',
    ),
    PlacementQuestion(
      id: 3,
      word: 'environment',
      type: 'noun',
      phonetic: '/ɪnˈvaɪrənmənt/',
      prompt: 'Plastic waste in oceans causes severe long-term harm to the marine _____.',
      level: 'A2 (Band 4.0 - 4.5)',
      options: ['môi trường', 'dân số', 'lịch sử', 'kinh tế'],
      correctIndex: 0,
      explanation: '"environment" là môi trường sống hoặc môi trường tự nhiên.',
    ),

    // --- LEVEL 2: B1 / Band 5.0 - 5.5 (4 questions) ---
    PlacementQuestion(
      id: 4,
      word: 'contribute',
      type: 'verb',
      phonetic: '/kənˈtrɪbjuːt/',
      prompt: 'Sedentary lifestyles and poor diets can _____ to chronic health complications.',
      level: 'B1 (Band 5.0 - 5.5)',
      options: ['từ chối hoàn toàn', 'phục hồi nhanh', 'đóng góp, góp phần gây ra', 'ngăn chặn'],
      correctIndex: 2,
      explanation: '"contribute to" có nghĩa là đóng góp vào hoặc là nguyên nhân dẫn đến điều gì.',
    ),
    PlacementQuestion(
      id: 5,
      word: 'persuade',
      type: 'verb',
      phonetic: '/pəˈsweɪd/',
      prompt: 'The manager gave a compelling presentation to _____ the investors to fund the project.',
      level: 'B1 (Band 5.0 - 5.5)',
      options: ['ép buộc', 'thuyết phục', 'lừa dối', 'trì hoãn'],
      correctIndex: 1,
      explanation: '"persuade" có nghĩa là thuyết phục ai đó tin hoặc làm theo một việc.',
    ),
    PlacementQuestion(
      id: 6,
      word: 'essential',
      type: 'adjective',
      phonetic: '/ɪˈsenʃl/',
      prompt: 'Critical thinking is an _____ skill for students entering university education.',
      level: 'B1 (Band 5.0 - 5.5)',
      options: ['xa xỉ, không bắt buộc', 'tạm thời', 'thiết yếu, cốt lõi', 'nhân tạo'],
      correctIndex: 2,
      explanation: '"essential" mang nghĩa thiết yếu, vô cùng quan trọng và không thể thiếu.',
    ),
    PlacementQuestion(
      id: 7,
      word: 'reliable',
      type: 'adjective',
      phonetic: '/rɪˈlaɪəbl/',
      prompt: 'The scientific journal is a _____ source of academic research and verified data.',
      level: 'B1 (Band 5.0 - 5.5)',
      options: ['đáng tin cậy', 'lỗi thời', 'mơ hồ', 'bất thường'],
      correctIndex: 0,
      explanation: '"reliable" chỉ người hoặc nguồn tin đáng tin cậy, chắc chắn.',
    ),

    // --- LEVEL 3: B2 / Band 6.0 - 6.5 (4 questions) ---
    PlacementQuestion(
      id: 8,
      word: 'abandon',
      type: 'verb',
      phonetic: '/əˈbændən/',
      prompt: 'Due to extreme weather and rising risks, the research team had to _____ their Arctic expedition.',
      level: 'B2 (Band 6.0 - 6.5)',
      options: ['tiếp tục', 'mở rộng', 'từ bỏ, hủy bỏ', 'ca ngợi'],
      correctIndex: 2,
      explanation: '"abandon" có nghĩa là từ bỏ, bỏ dở giữa chừng một kế hoạch hoặc đồ vật.',
    ),
    PlacementQuestion(
      id: 9,
      word: 'compensate',
      type: 'verb',
      phonetic: '/ˈkɒmpenseɪt/',
      prompt: 'Airlines are legally required to _____ passengers when flights are cancelled without prior notice.',
      level: 'B2 (Band 6.0 - 6.5)',
      options: ['phạt tiền', 'bồi thường, bù đắp', 'chỉ trích', 'từ chối phục vụ'],
      correctIndex: 1,
      explanation: '"compensate" có nghĩa là đền bù hoặc bồi thường thiệt hại cho ai đó.',
    ),
    PlacementQuestion(
      id: 10,
      word: 'deteriorate',
      type: 'verb',
      phonetic: '/dɪˈtɪəriəreɪt/',
      prompt: 'Air quality in the metropolitan area will _____ if industrial emissions remain unregulated.',
      level: 'B2 (Band 6.0 - 6.5)',
      options: ['suy giảm, xấu đi', 'cải thiện đáng kể', 'ổn định dần', 'biến mất'],
      correctIndex: 0,
      explanation: '"deteriorate" có nghĩa là trở nên tệ hơn hoặc suy giảm chất lượng/tình trạng.',
    ),
    PlacementQuestion(
      id: 11,
      word: 'sustainable',
      type: 'adjective',
      phonetic: '/səˈsteɪnəbl/',
      prompt: 'Solar and wind energy are recognized as _____ alternatives to finite fossil fuels.',
      level: 'B2 (Band 6.0 - 6.5)',
      options: ['ngắn hạn', 'bền vững, thân thiện sinh thái', 'lãng phí', 'độc hại'],
      correctIndex: 1,
      explanation: '"sustainable" có nghĩa là bền vững, có thể duy trì lâu dài mà không tổn hại môi trường.',
    ),

    // --- LEVEL 4: C1 / Band 7.0 - 8.0+ (4 questions) ---
    PlacementQuestion(
      id: 12,
      word: 'abolish',
      type: 'verb',
      phonetic: '/əˈbɒlɪʃ/',
      prompt: 'Civil rights advocates campaigned for decades to _____ archaic and discriminatory laws.',
      level: 'C1 (Band 7.0 - 8.0+)',
      options: ['bãi bỏ, thủ tiêu', 'ban hành mới', 'củng cố uy tín', 'hoãn tạm thời'],
      correctIndex: 0,
      explanation: '"abolish" là huỷ bỏ, bãi bỏ chính thức một bộ luật hoặc tập tục lâu đời.',
    ),
    PlacementQuestion(
      id: 13,
      word: 'exacerbate',
      type: 'verb',
      phonetic: '/ɪɡˈzæsəbeɪt/',
      prompt: 'The ongoing trade dispute will only _____ economic instability across developing nations.',
      level: 'C1 (Band 7.0 - 8.0+)',
      options: ['làm giảm áp lực', 'làm trầm trọng thêm', 'giải quyết triệt để', 'nghiên cứu'],
      correctIndex: 1,
      explanation: '"exacerbate" là từ vựng C1 diễn tả việc làm cho vấn đề hoặc bệnh tình tồi tệ, trầm trọng hơn.',
    ),
    PlacementQuestion(
      id: 14,
      word: 'ubiquitous',
      type: 'adjective',
      phonetic: '/juːˈbɪkwɪtəs/',
      prompt: 'Smartphones and digital displays have become _____ in modern urban environments.',
      level: 'C1 (Band 7.0 - 8.0+)',
      options: ['hiếm hoi', 'lỗi thời', 'phổ biến ở khắp mọi nơi', 'xa hoa'],
      correctIndex: 2,
      explanation: '"ubiquitous" nghĩa là có mặt hoặc phổ biến ở khắp mọi nơi (omnipresent).',
    ),
    PlacementQuestion(
      id: 15,
      word: 'scrutinize',
      type: 'verb',
      phonetic: '/ˈskruːtənaɪz/',
      prompt: 'Auditors were hired to _____ every financial transaction to ensure regulatory compliance.',
      level: 'C1 (Band 7.0 - 8.0+)',
      options: ['sao chép nhanh', 'bỏ qua lỗi', 'xem xét kỹ lưỡng', 'phê duyệt sơ sài'],
      correctIndex: 2,
      explanation: '"scrutinize" có nghĩa là soi xét, kiểm tra hoặc nghiên cứu một cách cực kỳ cẩn thận, chi tiết.',
    ),
  ];

  /// Evaluate Placement Test Results
  static PlacementResult evaluateScore(int correctCount) {
    if (correctCount >= 13) {
      return const PlacementResult(
        score: 13,
        totalQuestions: 15,
        band: '7.5',
        cefr: 'C1',
        title: 'Trình độ Nâng cao (Band 7.5+ / C1)',
        description: 'Vốn từ vựng học thuật của bạn rất xuất sắc, nắm vững các từ chuyên sâu và cấu trúc trừu tượng.',
        recommendation: 'Hệ thống sẽ bỏ qua toàn bộ từ cơ bản & trung cấp (A1, A2, B1, B2) và chỉ cấp các từ vựng Band 7.0 – 8.5+ để tối ưu điểm số IELTS.',
        skippedLevels: ['A1', 'A2', 'B1', 'B2'],
      );
    } else if (correctCount >= 9) {
      return const PlacementResult(
        score: 9,
        totalQuestions: 15,
        band: '6.5',
        cefr: 'B2',
        title: 'Trình độ Khá (Band 6.0 - 6.5 / B2)',
        description: 'Bạn đã có nền tảng từ vựng phổ thông rất tốt, đã sẵn sàng chinh phục các chủ đề học thuật chuyên sâu.',
        recommendation: 'Hệ thống sẽ bỏ qua ~3.000 từ vựng cơ sở (A1, A2, B1) và tập trung luyện các từ vựng IELTS Band 6.0 – 7.5+.',
        skippedLevels: ['A1', 'A2', 'B1'],
      );
    } else if (correctCount >= 5) {
      return const PlacementResult(
        score: 5,
        totalQuestions: 15,
        band: '5.5',
        cefr: 'B1',
        title: 'Trình độ Tiền trung cấp (Band 5.0 - 5.5 / B1)',
        description: 'Bạn nắm tốt từ vựng giao tiếp hàng ngày, cần mở rộng vốn từ sang các chủ đề xã hội và học thuật.',
        recommendation: 'Hệ thống sẽ bỏ qua các từ A1-A2 quá đơn giản và cấp lộ trình từ vựng Band 5.5 – 6.5.',
        skippedLevels: ['A1', 'A2'],
      );
    } else {
      return const PlacementResult(
        score: 3,
        totalQuestions: 15,
        band: '4.5',
        cefr: 'A2',
        title: 'Trình độ Cơ bản (Band 4.0 - 4.5 / A2)',
        description: 'Bạn đang ở giai đoạn xây dựng nền móng từ vựng ban đầu.',
        recommendation: 'Hệ thống sẽ lọc bỏ từ A1 và hỗ trợ bạn xây chắc vốn từ vựng nền tảng Band 4.5 – 5.5.',
        skippedLevels: ['A1'],
      );
    }
  }

  /// Save placement results locally
  Future<void> saveResult({required String band, required int score}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompleted, true);
    await prefs.setString(_keyAssessedBand, band);
    await prefs.setInt(_keyScore, score);
  }

  /// Check if placement test is completed
  Future<bool> hasCompletedTest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCompleted) ?? false;
  }

  /// Get saved assessed band
  Future<String?> getAssessedBand() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAssessedBand);
  }
}
