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
    // --- TIER 1: Band 4.0 - 5.0 (Questions 1 - 4) ---
    PlacementQuestion(
      id: 1,
      word: 'significant',
      type: 'adjective',
      phonetic: '/sɪɡˈnɪfɪkənt/',
      prompt: 'There was a _____ difference between the test scores of students who practiced daily and those who did not.',
      level: 'Band 4.5 - 5.0 (Cơ bản)',
      options: ['đáng kể, có ý nghĩa lớn', 'tạm thời, ngắn hạn', 'nguy hiểm, rủi ro', 'bất công, thiên vị'],
      correctIndex: 0,
      explanation: '"significant" là tính từ học thuật phổ biến trong IELTS chỉ sự khác biệt hoặc thay đổi "đáng kể, quan trọng".',
    ),
    PlacementQuestion(
      id: 2,
      word: 'maintain',
      type: 'verb',
      phonetic: '/meɪnˈteɪn/',
      prompt: 'It is essential to _____ a consistent revision schedule to ensure vocabulary is retained in long-term memory.',
      level: 'Band 4.5 - 5.0 (Cơ bản)',
      options: ['phá vỡ, hủy bỏ', 'duy trì, giữ vững', 'từ chối hoàn toàn', 'làm suy giảm'],
      correctIndex: 1,
      explanation: '"maintain" có nghĩa là duy trì, giữ cho một thói quen hoặc trạng thái không bị gián đoạn.',
    ),
    PlacementQuestion(
      id: 3,
      word: 'acquire',
      type: 'verb',
      phonetic: '/əˈkwaɪə(r)/',
      prompt: 'Children can naturally _____ language skills when they are surrounded by immersive native environments.',
      level: 'Band 4.5 - 5.0 (Cơ bản)',
      options: ['tiếp thu, đạt được', 'từ chối, cự tuyệt', 'đánh mất', 'nghi ngờ'],
      correctIndex: 0,
      explanation: '"acquire" là từ học thuật thay thế cho "get/learn", mang nghĩa tiếp thu tri thức hoặc đạt được kỹ năng.',
    ),
    PlacementQuestion(
      id: 4,
      word: 'impact',
      type: 'noun',
      phonetic: '/ˈɪmpækt/',
      prompt: 'Widespread smartphone usage has had a profound _____ on the sleep quality and attention span of youths.',
      level: 'Band 4.5 - 5.0 (Cơ bản)',
      options: ['tác động, ảnh hưởng sâu sắc', 'nguồn gốc ban đầu', 'sự trì hoãn', 'khoảng cách địa lý'],
      correctIndex: 0,
      explanation: '"profound impact on" là cụm collocation kinh điển trong IELTS Writing Task 2 chỉ tác động sâu sắc.',
    ),

    // --- TIER 2: Band 5.5 - 6.0 (Questions 5 - 9) ---
    PlacementQuestion(
      id: 5,
      word: 'contribute to',
      type: 'phrasal verb',
      phonetic: '/kənˈtrɪbjuːt tuː/',
      prompt: 'Excessive consumption of fast food and processed sugar will inevitably _____ obesity and cardiovascular diseases.',
      level: 'Band 5.5 - 6.0 (Trung cấp)',
      options: ['ngăn chặn triệt để', 'góp phần gây ra, dẫn đến', 'chữa lành hoàn toàn', 'loại bỏ nguy cơ'],
      correctIndex: 1,
      explanation: '"contribute to" thường dùng trong IELTS để giải thích mối quan hệ nguyên nhân - kết quả (cause and effect).',
    ),
    PlacementQuestion(
      id: 6,
      word: 'evaluate',
      type: 'verb',
      phonetic: '/ɪˈvæljueɪt/',
      prompt: 'Independent experts were invited to _____ the economic viability and environmental safety of the proposed dam.',
      level: 'Band 5.5 - 6.0 (Trung cấp)',
      options: ['sao chép số liệu', 'bác bỏ không căn cứ', 'đánh giá, thẩm định', 'kéo dài thời hạn'],
      correctIndex: 2,
      explanation: '"evaluate" là đánh giá kỹ lưỡng giá trị, tầm quan trọng hoặc mức độ khả thi của một dự án.',
    ),
    PlacementQuestion(
      id: 7,
      word: 'adequate',
      type: 'adjective',
      phonetic: '/ˈædɪkwət/',
      prompt: 'Without _____ funding and clinical staff, public hospitals struggle to manage patient overload during flu season.',
      level: 'Band 5.5 - 6.0 (Trung cấp)',
      options: ['đầy đủ, đáp ứng đủ nhu cầu', 'đắt đỏ, xa hoa', 'lỗi thời, cổ lỗ', 'nhân tạo'],
      correctIndex: 0,
      explanation: '"adequate" mang nghĩa đầy đủ về số lượng hoặc chất lượng cho một mục đích cụ thể (đối nghĩa với inadequate).',
    ),
    PlacementQuestion(
      id: 8,
      word: 'consequence',
      type: 'noun',
      phonetic: '/ˈkɒnsɪkwəns/',
      prompt: 'Severe flash floods in the lowlands were a direct _____ of reckless deforestation upstream.',
      level: 'Band 5.5 - 6.0 (Trung cấp)',
      options: ['lợi ích kinh tế', 'hệ quả, hậu quả tất yếu', 'động lực phát triển', 'dự báo trước'],
      correctIndex: 1,
      explanation: '"consequence" là hậu quả hoặc kết quả phát sinh từ một hành động trước đó.',
    ),
    PlacementQuestion(
      id: 9,
      word: 'adversely',
      type: 'adverb',
      phonetic: '/ˈædvɜːsli/',
      prompt: 'Prolonged exposure to microplastics can _____ affect human endocrine and metabolic systems.',
      level: 'Band 5.5 - 6.0 (Trung cấp)',
      options: ['thuận lợi, tích cực', 'bất lợi, gây hại', 'ngẫu nhiên, tình cờ', 'nhẹ nhàng, không đáng kể'],
      correctIndex: 1,
      explanation: '"adversely affect" là cụm học thuật Band cao diễn tả tác động tiêu cực, gây hại cho sức khỏe hoặc hệ thống.',
    ),

    // --- TIER 3: Band 6.5 (Questions 10 - 14) ---
    PlacementQuestion(
      id: 10,
      word: 'compensate for',
      type: 'phrasal verb',
      phonetic: '/ˈkɒmpenseɪt fɔː(r)/',
      prompt: 'Higher salaries alone cannot permanently _____ an unhealthy workplace culture and chronic burnout.',
      level: 'Band 6.5 (Khá)',
      options: ['bồi thường, bù đắp cho', 'chỉ trích gay gắt', 'phạt tiền', 'chối bỏ trách nhiệm'],
      correctIndex: 0,
      explanation: '"compensate for" là bù đắp hoặc đền bù lại cho một thiếu sót hoặc tổn thất.',
    ),
    PlacementQuestion(
      id: 11,
      word: 'deteriorate',
      type: 'verb',
      phonetic: '/dɪˈtɪəriəreɪt/',
      prompt: 'Unless maintenance funds are allocated immediately, heritage bridges will _____ to the point of collapse.',
      level: 'Band 6.5 (Khá)',
      options: ['suy thoái, xuống cấp nghiêm trọng', 'phát triển mạnh mẽ', 'phục hồi nguyên trạng', 'đổi mới toàn diện'],
      correctIndex: 0,
      explanation: '"deteriorate" miêu tả tình trạng vật chất, sức khỏe hoặc quan hệ ngày càng xấu đi, suy thoái theo thời gian.',
    ),
    PlacementQuestion(
      id: 12,
      word: 'sustainable',
      type: 'adjective',
      phonetic: '/səˈsteɪnəbl/',
      prompt: 'Urban planners advocate for _____ transit systems to curb emissions without exhausting municipal budgets.',
      level: 'Band 6.5 (Khá)',
      options: ['ngắn hạn, tạm bợ', 'bền vững, duy trì lâu dài', 'lãng phí ngân sách', 'độc hại cho môi trường'],
      correctIndex: 1,
      explanation: '"sustainable" là từ khóa trọng điểm của các bài đọc IELTS Environment & Economy, chỉ sự bền vững dài hạn.',
    ),
    PlacementQuestion(
      id: 13,
      word: 'prevalent',
      type: 'adjective',
      phonetic: '/ˈprevələnt/',
      prompt: 'Sedentary leisure habits have become far more _____ among urban youths than engaging in outdoors sports.',
      level: 'Band 6.5 (Khá)',
      options: ['khan hiếm, hiếm hoi', 'thịnh hành, phổ biến rộng rãi', 'bất hợp pháp', 'tốn kém chi phí'],
      correctIndex: 1,
      explanation: '"prevalent" nghĩa là phổ biến, lan rộng tại một thời điểm hoặc khu vực cụ thể (synonym của widespread).',
    ),
    PlacementQuestion(
      id: 14,
      word: 'drawback',
      type: 'noun',
      phonetic: '/ˈdrɔːbæk/',
      prompt: 'A significant _____ of full-time remote working is the gradual erosion of spontaneous team collaboration.',
      level: 'Band 6.5 (Khá)',
      options: ['lợi thế nổi bật', 'nhược điểm, điều bất lợi', 'mục tiêu chiến lược', 'yêu cầu pháp lý'],
      correctIndex: 1,
      explanation: '"drawback" là từ học thuật diễn tả nhược điểm hoặc mặt hạn chế trong các bài luận Advantage/Disadvantage.',
    ),

    // --- TIER 4: Band 7.0 - 7.5 (Questions 15 - 18) ---
    PlacementQuestion(
      id: 15,
      word: 'exacerbate',
      type: 'verb',
      phonetic: '/ɪɡˈzæsəbeɪt/',
      prompt: 'Drastic reductions in green belts and tree canopies will only _____ the urban heat island effect during summer.',
      level: 'Band 7.0 - 7.5 (Giỏi)',
      options: ['làm trầm trọng, tồi tệ thêm', 'giải quyết triệt để', 'xoa dịu tình hình', 'đo lường định lượng'],
      correctIndex: 0,
      explanation: '"exacerbate" là từ vựng C1 diễn tả hành động làm cho một vấn đề, căn bệnh hoặc tình huống vốn đã xấu càng tệ hơn.',
    ),
    PlacementQuestion(
      id: 16,
      word: 'mitigate',
      type: 'verb',
      phonetic: '/ˈmɪtɪɡeɪt/',
      prompt: 'Coastal mangrove restoration projects have proven remarkably effective to _____ the impact of tidal surges.',
      level: 'Band 7.0 - 7.5 (Giỏi)',
      options: ['làm tăng áp lực', 'làm dịu bớt, giảm nhẹ tác hại', 'kích động dư luận', 'trì hoãn thi hành'],
      correctIndex: 1,
      explanation: '"mitigate" là giảm nhẹ mức độ nghiêm trọng hoặc tác hại của một thảm họa/rủi ro (key C1 vocabulary).',
    ),
    PlacementQuestion(
      id: 17,
      word: 'disparity',
      type: 'noun',
      phonetic: '/dɪˈspærəti/',
      prompt: 'The latest sociological survey revealed a widening income and digital _____ between urban centers and rural hamlets.',
      level: 'Band 7.0 - 7.5 (Giỏi)',
      options: ['sự tương đồng tuyệt đối', 'sự chênh lệch, bất bình đẳng sâu sắc', 'sự hợp tác chặt chẽ', 'sự hòa hoãn chính trị'],
      correctIndex: 1,
      explanation: '"disparity" chỉ sự khác biệt hoặc bất bình đẳng lớn, không công bằng (thường dùng trong bối cảnh xã hội, thu nhập).',
    ),
    PlacementQuestion(
      id: 18,
      word: 'scrutinize',
      type: 'verb',
      phonetic: '/ˈskruːtənaɪz/',
      prompt: 'Regulatory committees must meticulously _____ clinical trials to ensure consumer safety before licensing vaccines.',
      level: 'Band 7.0 - 7.5 (Giỏi)',
      options: ['soi xét, kiểm tra kỹ lưỡng từng chi tiết', 'thông qua vội vàng', 'lờ đi các sai phạm', 'sao chép công thức'],
      correctIndex: 0,
      explanation: '"scrutinize" có nghĩa là kiểm tra, thẩm tra một cách cực kỳ cẩn trọng và có tính phản biện sâu sắc.',
    ),

    // --- TIER 5: Band 8.0+ (Questions 19 - 20) ---
    PlacementQuestion(
      id: 19,
      word: 'substantiate',
      type: 'verb',
      phonetic: '/səbˈstænʃieɪt/',
      prompt: 'The researchers were unable to _____ their controversial hypothesis with statistically reproducible laboratory data.',
      level: 'Band 8.0+ (Xuất sắc)',
      options: ['bác bỏ hoàn toàn', 'chứng minh, cung cấp chứng cứ xác thực', 'nghi ngờ tính trung thực', 'trì hoãn phán quyết'],
      correctIndex: 1,
      explanation: '"substantiate" là từ học thuật cấp C2, nghĩa là cung cấp bằng chứng xác thực để chứng minh tính đúng đắn của một lập luận.',
    ),
    PlacementQuestion(
      id: 20,
      word: 'ubiquitous',
      type: 'adjective',
      phonetic: '/juːˈbɪkwɪtəs/',
      prompt: 'Sensors and tracking algorithms have become so _____ that modern citizens can scarcely evade automated surveillance.',
      level: 'Band 8.0+ (Xuất sắc)',
      options: ['hiếm hoi, dị biệt', 'có mặt khắp nơi, phổ biến toàn diện', 'lỗi thời, không còn tác dụng', 'dễ phát hiện bằng mắt thường'],
      correctIndex: 1,
      explanation: '"ubiquitous" là từ vựng C2 đỉnh cao diễn tả sự hiện diện ở khắp mọi nơi cùng lúc (omnipresent).',
    ),
  ];

  /// Rigorous, Realistic IELTS Vocabulary Band Evaluation
  static PlacementResult evaluateScore(int correctCount) {
    if (correctCount >= 19) {
      // 19 - 20 correct (95% - 100%)
      return PlacementResult(
        score: correctCount,
        totalQuestions: 20,
        band: '7.5',
        cefr: 'C1',
        title: 'Trình độ Xuất sắc (Band 7.5 - 8.0+ / C1)',
        description: 'Bạn nắm vững toàn diện từ vựng học thuật cao cấp và các collocations phức tạp của đề thi IELTS.',
        recommendation: 'Hệ thống sẽ lọc bỏ toàn bộ từ vựng cơ bản và trung cấp (A1 - B2), chỉ cấp các từ học thuật C1 - C2 để chạm mốc điểm tối đa.',
        skippedLevels: ['A1', 'A2', 'B1', 'B2'],
      );
    } else if (correctCount >= 15) {
      // 15 - 18 correct (75% - 90%)
      return PlacementResult(
        score: correctCount,
        totalQuestions: 20,
        band: '7.0',
        cefr: 'C1',
        title: 'Trình độ Khá giỏi (Band 7.0 / C1)',
        description: 'Vốn từ vựng học thuật của bạn rất tốt, nắm vững hầu hết các cụm từ ngữ cảnh và cấu trúc phức tạp.',
        recommendation: 'Hệ thống sẽ bỏ qua các từ cơ bản (A1, A2, B1) và tập trung luyện các từ vựng học thuật chuyên sâu Band 7.0 - 7.5+.',
        skippedLevels: ['A1', 'A2', 'B1'],
      );
    } else if (correctCount >= 10) {
      // 10 - 14 correct (50% - 70%) -> Trình độ phổ biến nhất của người ôn IELTS
      return PlacementResult(
        score: correctCount,
        totalQuestions: 20,
        band: '6.0',
        cefr: 'B2',
        title: 'Trình độ Trung cấp (Band 6.0 - 6.5 / B2)',
        description: 'Bạn đã có nền tảng từ vựng phổ thông vững chắc và nắm được các từ vựng học thuật cơ bản.',
        recommendation: 'Hệ thống sẽ bỏ qua ~3.000 từ cơ bản (A1, A2, B1) và tập trung xây chắc các từ vựng B2/C1 để nâng Band lên 7.0+.',
        skippedLevels: ['A1', 'A2', 'B1'],
      );
    } else if (correctCount >= 6) {
      // 6 - 9 correct (30% - 45%)
      return PlacementResult(
        score: correctCount,
        totalQuestions: 20,
        band: '5.5',
        cefr: 'B1',
        title: 'Trình độ Tiền trung cấp (Band 5.0 - 5.5 / B1)',
        description: 'Bạn giao tiếp tốt với các từ vựng thông dụng, nhưng còn thiếu vốn từ học thuật cho Reading & Writing.',
        recommendation: 'Hệ thống sẽ lọc bỏ từ vựng quá đơn giản (A1, A2) và xây dựng lộ trình học từ vựng nền tảng Band 5.5 - 6.5.',
        skippedLevels: ['A1', 'A2'],
      );
    } else {
      // 0 - 5 correct (< 30%)
      return PlacementResult(
        score: correctCount,
        totalQuestions: 20,
        band: '4.5',
        cefr: 'A2',
        title: 'Trình độ Cơ bản (Band 4.0 - 4.5 / A2)',
        description: 'Bạn đang ở giai đoạn khởi đầu xây dựng vốn từ vựng nền móng.',
        recommendation: 'Hệ thống sẽ đồng hành từ những bước cơ bản nhất để bạn nắm chắc 1.500 từ vựng cốt lõi đầu tiên.',
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
