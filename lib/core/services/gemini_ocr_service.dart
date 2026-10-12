import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiOcrService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Performs OCR on image bytes using Google Gemini API
  static Future<String> performOcr({
    required Uint8List imageBytes,
    required String apiKey,
    String model = 'gemini-1.5-flash',
    String? mimeType,
  }) async {
    final cleanApiKey = apiKey.trim();
    if (cleanApiKey.isEmpty) {
      throw Exception('Vui lòng cung cấp Gemini API Key.');
    }

    final detectedMime = mimeType ?? _detectMimeType(imageBytes);
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$cleanApiKey');

    final prompt = '''
Bạn là chuyên gia OCR (Optical Character Recognition) hàng đầu.
Nhiệm vụ của bạn:
1. Nhận diện và trích xuất TOÀN BỘ văn bản, chữ viết tay, bảng số liệu, ký hiệu có trong hình ảnh này.
2. Giữ nguyên định dạng gốc: thứ tự đọc tự nhiên từ trên xuống dưới, cách xuống dòng, tiêu đề, danh sách, và bảng biểu (dùng bảng Markdown nếu phù hợp).
3. Nếu có ngôn ngữ Tiếng Việt, hãy giữ đúng dấu thanh và ngữ pháp.
4. Chỉ trả về trực tiếp nội dung văn bản đã trích xuất, KHÔNG thêm câu chào, KHÔNG bình luận thêm lời mở đầu hay kết thúc.
''';

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text": prompt.trim(),
            },
            {
              "inline_data": {
                "mime_type": detectedMime,
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "maxOutputTokens": 8192,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode != 200) {
        final errorMsg = decoded['error']?['message'] ?? 'Lỗi không xác định (${response.statusCode})';
        if (response.statusCode == 400 && errorMsg.toString().contains('API key not valid')) {
          throw Exception('API Key không hợp lệ. Vui lòng kiểm tra lại key của bạn.');
        } else if (response.statusCode == 429) {
          throw Exception('Đã vượt quá giới hạn lượt gọi API (Quota Exceeded). Vui lòng đợi ít phút hoặc dùng key khác.');
        } else {
          throw Exception('Lỗi từ Gemini API: $errorMsg');
        }
      }

      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final blockReason = decoded['promptFeedback']?['blockReason'];
        if (blockReason != null) {
          throw Exception('Yêu cầu bị từ chối do chính sách an toàn: $blockReason');
        }
        throw Exception('Không nhận diện được nội dung hoặc hình ảnh không có văn bản.');
      }

      final content = candidates[0]['content'];
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Không tìm thấy nội dung văn bản trong phản hồi.');
      }

      final extractedText = parts.map((p) => p['text']?.toString() ?? '').join('\n').trim();

      if (extractedText.isEmpty) {
        return 'Không tìm thấy văn bản nào trong hình ảnh này.';
      }

      return extractedText;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }

  /// Simple MIME detection from magic bytes
  static String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 4) {
      // PNG
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'image/jpeg';
      }
      // WEBP
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'image/webp';
      }
      // GIF
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
    }
    return 'image/jpeg';
  }
}
