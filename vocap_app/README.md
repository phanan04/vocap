# Vocap - IELTS Spaced Repetition Vocabulary (Flutter Client)

Vocap là ứng dụng học và ghi nhớ từ vựng tiếng Anh chuyên sâu cho kỳ thi **IELTS**, xây dựng trên nền tảng **Oxford 5000** kết hợp thuật toán lặp lại ngắt quãng **SuperMemo-2 (SM-2)** và máy chủ **Supabase PostgreSQL**.

---

## 🌟 Tính Năng Nổi Bật

1. **Kho từ vựng Oxford 5000 chuẩn IELTS:**
   - Đầy đủ 5.943 từ vựng phân loại theo 20 Chủ đề IELTS và Band điểm từ 4.0 đến 9.0.
   - 19 trường dữ liệu: Phiên âm quốc tế IPA, Định nghĩa Oxford, Nghĩa tiếng Việt, Câu ví dụ song ngữ, Collocations ăn điểm, Synonyms, Antonyms, Word Family.

2. **Hệ thống ôn tập ngắt quãng (SM-2 Spaced Repetition System):**
   - Thuật toán SuperMemo-2 phân bổ lịch ôn tập tự động dựa trên độ nhớ của người dùng:
     - 🔴 **Quên (Again / 1)**: Lặp lại ngay trong phiên học
     - 🟠 **Khó (Hard / 3)**: Khoảng cách ôn tăng nhẹ
     - 🔵 **Nhớ (Good / 4)**: Chu kỳ chuẩn SM-2
     - 🟢 **Dễ (Easy / 5)**: Nhớ sâu, tăng khoảng cách chu kỳ tối đa

3. **Phát âm US Audio từ Cloudflare CDN:**
   - 4.957 file MP3 phát âm chuẩn Mỹ stream trực tiếp từ Supabase Storage CDN, tốc độ phản hồi cực nhanh, không làm nặng dung lượng máy.

4. **4 Chế độ Luyện tập Đa dạng:**
   - 🎴 **Flashcard 3D:** Lật thẻ mượt mà, tra cứu nghĩa, collocations và phát âm.
   - 🎯 **Trắc nghiệm (Quiz):** 4 lựa chọn (Nghĩa ➔ Từ vựng, hoặc Từ vựng ➔ Nghĩa).
   - 🎧 **Luyện nghe (Listening Quiz):** Nghe phát âm chuẩn Mỹ và nhận diện từ.
   - ✏️ **Điền từ vào câu (Fill-in-the-blank):** Luyện ngữ cảnh câu ví dụ IELTS.

---

## 📁 Cấu Trúc Thư Mục (Clean Architecture)

```text
vocap_app/
├── pubspec.yaml                 # Cấu hình dependencies và assets
├── README.md                    # Tài liệu hướng dẫn sử dụng
└── lib/
    ├── main.dart                # Điểm khởi chạy ứng dụng & kết nối Supabase
    ├── core/
    │   ├── constants/
    │   │   └── supabase_constants.dart  # Cấu hình API URL, Anon Key, Audio CDN
    │   └── theme/
    │       └── app_theme.dart           # Giao diện Material 3, Dark theme, IELTS Band colors
    ├── models/
    │   ├── word_model.dart              # Model 19 trường dữ liệu từ vựng
    │   └── user_word_model.dart         # Model tiến độ học SM-2 SRS
    ├── services/
    │   ├── supabase_service.dart        # Tương tác PostgreSQL, RPC hàm SRS
    │   └── audio_service.dart           # Dịch vụ phát âm thanh US Audio từ CDN
    ├── widgets/
    │   ├── audio_play_button.dart       # Nút phát âm thanh tương tác
    │   └── ielts_band_badge.dart        # Huy hiệu hiển thị Band điểm IELTS
    └── screens/
        ├── home_screen.dart             # Màn hình chính Dashboard, mục tiêu ngày, streak
        ├── flashcard_screen.dart        # Màn hình lật thẻ Flashcard & nút đánh giá SM-2
        ├── quiz_screen.dart             # Màn hình bài tập trắc nghiệm 4 chế độ
        ├── topic_explorer_screen.dart   # Màn hình khám phá 20 chủ đề IELTS & tìm kiếm
        └── word_detail_screen.dart      # Màn hình chi tiết toàn diện của 1 từ vựng
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Chạy Ứng Dụng Trên Linux (GNOME)

### 1. Cài đặt Flutter SDK qua dòng lệnh:
Chạy lần lượt các lệnh sau trong Terminal của bạn:

```bash
# 1. Tạo thư mục development và tải Flutter SDK chính thức
mkdir -p ~/development
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# 2. Thêm Flutter vào biến môi trường PATH (cho bash / zsh)
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 3. Kiểm tra môi trường Flutter
flutter doctor
```

### 2. Cài đặt các gói phụ thuộc và chạy ứng dụng:

```bash
# Di chuyển vào thư mục dự án
cd /home/pan/pan/projects/vocap/vocap_app

# Cài đặt thư viện
flutter pub get

# Chạy ứng dụng trên thiết bị (Trình duyệt Web, Thiết bị Android kết nối hoặc Linux Desktop)
flutter run
```
