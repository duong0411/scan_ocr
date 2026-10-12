# scan_ocr - Gemini OCR App

Ứng dụng Flutter OCR đa nền tảng (Android, Web, Windows) tích hợp **Google Gemini Multimodal API**, cho phép người dùng tự nhập API Key cá nhân để trích xuất văn bản từ hình ảnh chụp hoặc ảnh tải lên.

---

## 🌟 Tính năng nổi bật

1. **Nhập Gemini API Key cá nhân**:
   - Người dùng tự nhập API Key lấy từ [Google AI Studio](https://aistudio.google.com/app/apikey).
   - Tự động lưu trữ an toàn trong thiết bị (`SharedPreferences`), không cần nhập lại nhiều lần.
   - Hỗ trợ đổi hoặc xóa API Key bất cứ lúc nào.
   - Tùy chọn mô hình: `gemini-1.5-flash` (mặc định - tốc độ siêu nhanh & tối ưu OCR), `gemini-2.0-flash`, `gemini-1.5-pro`.

2. **Đầu vào linh hoạt**:
   - **Chụp ảnh trực tiếp từ Camera**: Tiện lợi khi quét tài liệu, hóa đơn, bài thi, sách vở.
   - **Tải ảnh từ thư viện thiết bị**: Hỗ trợ định dạng PNG, JPG, JPEG, WEBP.
   - Xem trước (preview) hình ảnh, thông tin dung lượng và định dạng.

3. **Xử lý OCR thông minh bằng Multimodal AI**:
   - Nhận diện văn bản in, chữ viết tay, công thức và bảng biểu.
   - Tự động giữ nguyên cấu trúc định dạng xuống dòng và ngữ pháp tiếng Việt có dấu.
   - Hiệu ứng quét / loading sinh động trong khi chờ AI phản hồi.

4. **Tiện ích kết quả**:
   - Hiển thị thống kê số từ (word count) và số ký tự (character count).
   - Nút **Sao chép (Copy to Clipboard)** nhanh chóng chỉ với 1 chạm.
   - Hỗ trợ chọn và bôi đen từng đoạn văn bản cụ thể (`SelectableText`).

---

## 🚀 Hướng dẫn khởi chạy ứng dụng

### 1. Chạy trên trình duyệt Web (Chrome / Edge):
```bash
cd app_ocr
flutter run -d chrome
```

### 2. Chạy trên Android Emulator hoặc thiết bị thật:
```bash
cd app_ocr
flutter run -d emulator-5554
# hoặc
flutter run -d android
```

### 3. Chạy trên Windows Desktop:
```bash
cd app_ocr
flutter run -d windows
```

Hoặc bạn có thể click đúp chuột vào file script `run_web.bat` hoặc `run_android.bat` nằm ngay trong thư mục `app_ocr`.

---

## 🔑 Hướng dẫn lấy Gemini API Key miễn phí

1. Truy cập vào [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Đăng nhập bằng tài khoản Google.
3. Chọn **Create API key** và sao chép mã khoá (bắt đầu bằng `AIzaSy...`).
4. Mở ứng dụng, dán mã khoá vào mục **Cài đặt Gemini API Key** và nhấn **Lưu Key**.
