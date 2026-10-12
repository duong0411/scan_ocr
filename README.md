# scan_ocr - PaddleOCR NCNN Mobile App

Ứng dụng nhận diện chữ (OCR) trên thiết bị di động **hoàn toàn ngoại tuyến (Offline 100%)**, chạy mô hình **PaddleOCR (DBNet + CRNN)** tối ưu hóa cho di động thông qua **Tencent NCNN C++ Engine** và gọi trực tiếp từ Flutter qua **Dart FFI**.

---

## ⚡ Ưu điểm nổi bật

1. **100% Offline - Không cần API Key**:
   - Hoạt động độc lập trên phần cứng máy (CPU / GPU ARM NEON & Vulkan).
   - Không cần mạng Internet, không cần nhập API key, không lo lộ lọt dữ liệu hình ảnh nhạy cảm.

2. **Kiến trúc Native C++ Siêu nhẹ & Tốc độ cao**:
   - Sử dụng framework suy luận mạng nơ-ron **Tencent NCNN** viết bằng C++.
   - Mô hình PaddleOCR v3/v4 rút gọn:
     - **DBNet Detection**: Phát hiện chính xác vị trí các dòng chữ và bảng biểu.
     - **CRNN Recognition**: Nhận diện ký tự và từ vựng.
     - **CTC Greedy Decoder**: Giải mã chuỗi văn bản tự nhiên.
   - Thời gian nhận diện chỉ từ **50ms - 150ms / ảnh**.

3. **Giao diện tối giản & Tiện ích**:
   - Chụp ảnh trực tiếp từ Camera hoặc tải ảnh từ thư viện thiết bị.
   - Trả về kết quả văn bản ngay lập tức.
   - Thống kê số từ, số ký tự, nút **Sao chép (Copy to Clipboard)** với 1 chạm.

---

## 📁 Cấu trúc Native C++ & Dart FFI

```text
app_ocr/
├── android/app/src/main/cpp/
│   ├── CMakeLists.txt              # Cấu hình biên dịch thư viện động .so
│   ├── ocr_ncnn.h                  # Khai báo C API (ocr_init, ocr_detect_and_recognize)
│   ├── ocr_ncnn.cpp                # Thuật toán suy luận NCNN DBNet + CRNN
│   └── ncnn-android-vulkan/        # Prebuilt SDK NCNN cho Android (ARMv7, ARM64, x86)
├── assets/models/
│   ├── ch_PP-OCRv3_det_infer.*     # Trọng số mô hình phát hiện chữ
│   ├── ch_PP-OCRv3_rec_infer.*     # Trọng số mô hình nhận dạng ký tự
│   └── ppocr_keys_v1.txt           # Từ điển giải mã ký tự
└── lib/
    ├── core/services/
    │   └── paddle_ocr_ffi_service.dart # Dart FFI Bridge kết nối C++ Engine
    ├── screens/
    │   └── ocr_home_screen.dart        # Màn hình chính
    └── main.dart
```

---

## 🚀 Cách chạy ứng dụng

```bash
cd app_ocr
flutter run -d emulator-5554
# hoặc đóng gói APK
flutter build apk --release
```