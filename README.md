# Vocap - IELTS Vocabulary Learning App (Oxford 5000 Edition)

Vocap là ứng dụng học từ vựng IELTS chuyên sâu chuẩn Oxford 5000 (5.943 từ, 19 trường dữ liệu chi tiết, phát âm giọng Mỹ chuẩn US Audio), tích hợp thuật toán lặp lại ngắt quãng SM-2 (Spaced Repetition System), hệ thống bài tập trắc nghiệm 4 chế độ và đồng bộ đám mây Supabase PostgreSQL.

---

## 🌟 Tính Năng Nổi Bật

- **Kho 5.943 Từ Vựng Oxford 5000 Phân Cấp CEFR & IELTS Chuẩn Quốc Tế:**
  - `A1` (1.0 – 2.5): 1.076 từ
  - `A2` (3.0 – 3.5): 990 từ
  - `B1` (4.0 – 5.0): 902 từ
  - `B2` (5.5 – 6.5): 1.571 từ
  - `C1` (7.0 – 8.0): 972 từ
  - `C2` (8.5 – 9.0): 432 từ
- **Thuật Toán SM-2 Spaced Repetition (SRS):**
  - Đánh giá 4 mức độ: *Quên (Again)*, *Khó (Hard)*, *Nhớ (Good)*, *Dễ (Easy)*.
  - Tùy chọn *Đã thuộc (Không học lại nữa)* giúp bỏ qua vĩnh viễn các từ đã quen thuộc.
  - Tự động lên lịch ngày ôn tập tiếp theo vào mục *🔥 Cần ôn tập hôm nay*.
- **Chế Độ Học Kép (Dual View Mode):**
  - **📁 Theo Chủ Đề:** 20 Chủ đề IELTS lớn phân bổ động theo từng Band mục tiêu.
  - **📜 Tất Cả Từ Vựng:** Danh sách A-Z cuộn vô tận (Infinite Scrolling) kèm bộ lọc đa tiêu chí (Từ loại, CEFR, Collocations điểm cao Writing/Speaking).
- **Luyện Tập 4 Chế Độ Quiz:**
  - Nghĩa tiếng Việt ➔ Chọn từ tiếng Anh
  - Từ tiếng Anh ➔ Chọn nghĩa tiếng Việt
  - Nghe audio US ➔ Điền từ vựng
  - Điền từ vào câu ví dụ IELTS
- **Âm Thanh CDN Cloudflare:** 4.957 file âm thanh MP3 US streaming tốc độ cao từ Supabase Storage CDN.
- **Đồng Bộ Đám Mây & Ngoại Tuyến (Offline First):**
  - Supabase Auth tự động kích hoạt tài khoản.
  - Bảo lưu chuỗi Streak, điểm XP và lịch sử học tập ngay cả khi mất mạng.

---

## 🛠️ Công Nghệ Sử Dụng

- **Frontend:** Flutter SDK 3.x (Dart) - Hỗ trợ Web, Android, iOS, Desktop.
- **Backend & Database:** Supabase PostgreSQL (Stored Procedures, RPC, RLS, Triggers).
- **Storage CDN:** Cloudflare-backed Supabase Storage bucket `vocab-audio`.
- **Cơ sở dữ liệu cục bộ:** SharedPreferences & SQLite/file caching.

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Yêu cầu hệ thống:
- Đã cài đặt [Flutter SDK](https://flutter.dev).
- Thiết bị chạy: Trình duyệt web (Chrome/Edge), Thiết bị giả lập Android hoặc điện thoại thật.

### 2. Cài đặt Dependencies:
```bash
cd vocap_app
flutter pub get
```

### 3. Chạy ứng dụng:
- **Chạy trên Web:**
```bash
flutter run -d web-server --web-port 8080
```
Truy cập: `http://localhost:8080`

- **Chạy trên Chrome:**
```bash
flutter run -d chrome
```

- **Build file APK Android:**
```bash
flutter build apk --release
```

---

## 📂 Cấu Trúc Thư Mục

```
vocap/
├── assets/
│   └── data/oxford_5000.json     # Dữ liệu gốc 5.943 từ vựng
├── schema.sql                    # Toàn bộ schema PostgreSQL & RPC functions
├── seed_words.sql                # Dữ liệu nạp hạt giống vào CSDL
├── generate_seed.py              # Script sinh dữ liệu PostgreSQL
└── vocap_app/                    # Mã nguồn ứng dụng Flutter
    ├── lib/
    │   ├── core/                 # Constants, Theme, Color coding
    │   ├── models/               # WordModel, UserWordModel
    │   ├── services/             # Supabase, Audio, Auth, Offline, Progress
    │   ├── widgets/              # AudioPlayButton, IeltsBandBadge,...
    │   └── screens/              # Home, Flashcard, Quiz, TopicExplorer,...
    └── pubspec.yaml
```

---

## 📄 License
Dự án được phát hành dưới giấy phép MIT.
