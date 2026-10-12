import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// Native C structs
final class OcrBoxResultNative extends Struct {
  @Int32()
  external int x1;
  @Int32()
  external int y1;
  @Int32()
  external int x2;
  @Int32()
  external int y2;
  @Int32()
  external int x3;
  @Int32()
  external int y3;
  @Int32()
  external int x4;
  @Int32()
  external int y4;

  @Array(512)
  external Array<Uint8> text;

  @Float()
  external double score;
}

final class OcrFullResultNative extends Struct {
  @Int32()
  external int count;

  external Pointer<OcrBoxResultNative> boxes;
}

typedef OcrInitC = Int32 Function(
  Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32
);
typedef OcrInitDart = int Function(
  Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int
);

typedef OcrInferC = Pointer<OcrFullResultNative> Function(
  Pointer<Uint8>, Int32, Int32, Int32
);
typedef OcrInferDart = Pointer<OcrFullResultNative> Function(
  Pointer<Uint8>, int, int, int
);

typedef OcrFreeC = Void Function(Pointer<OcrFullResultNative>);
typedef OcrFreeDart = void Function(Pointer<OcrFullResultNative>);

class PaddleOcrFfiService {
  static DynamicLibrary? _lib;
  static OcrInitDart? _ocrInit;
  static OcrInferDart? _ocrInfer;
  static OcrFreeDart? _ocrFree;
  static bool _isInitialized = false;

  static bool get isAvailable => _isInitialized;

  /// Khởi tạo Native Library và nạp Model NCNN
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open("libpaddle_ocr_ncnn.so");
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open("paddle_ocr_ncnn.dll");
      } else {
        _lib = DynamicLibrary.process();
      }

      _ocrInit = _lib!.lookupFunction<OcrInitC, OcrInitDart>('ocr_init');
      _ocrInfer = _lib!.lookupFunction<OcrInferC, OcrInferDart>('ocr_detect_and_recognize');
      _ocrFree = _lib!.lookupFunction<OcrFreeC, OcrFreeDart>('ocr_free_result');

      // Chuẩn bị file model từ Assets sang Bộ nhớ máy
      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/ocr_models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final detParam = await _copyAssetToFile('assets/models/ch_PP-OCRv3_det_infer.param', '${modelsDir.path}/det.param') ??
          await _copyAssetToFile('assets/models/ch_PP-OCRv4_det_infer.param', '${modelsDir.path}/det.param');
      final detBin = await _copyAssetToFile('assets/models/ch_PP-OCRv3_det_infer.bin', '${modelsDir.path}/det.bin') ??
          await _copyAssetToFile('assets/models/ch_PP-OCRv4_det_infer.bin', '${modelsDir.path}/det.bin');
      final recParam = await _copyAssetToFile('assets/models/ch_PP-OCRv3_rec_infer.param', '${modelsDir.path}/rec.param') ??
          await _copyAssetToFile('assets/models/ch_PP-OCRv4_rec_infer.param', '${modelsDir.path}/rec.param');
      final recBin = await _copyAssetToFile('assets/models/ch_PP-OCRv3_rec_infer.bin', '${modelsDir.path}/rec.bin') ??
          await _copyAssetToFile('assets/models/ch_PP-OCRv4_rec_infer.bin', '${modelsDir.path}/rec.bin');
      final keysPath = await _copyAssetToFile('assets/models/ppocr_keys_v1.txt', '${modelsDir.path}/keys.txt');

      if (detParam != null && detBin != null && recParam != null && recBin != null && keysPath != null) {
        final pDetParam = detParam.toNativeUtf8();
        final pDetBin = detBin.toNativeUtf8();
        final pRecParam = recParam.toNativeUtf8();
        final pRecBin = recBin.toNativeUtf8();
        final pKeys = keysPath.toNativeUtf8();

        final res = _ocrInit!(pDetParam, pDetBin, pRecParam, pRecBin, pKeys, 4);

        malloc.free(pDetParam);
        malloc.free(pDetBin);
        malloc.free(pRecParam);
        malloc.free(pRecBin);
        malloc.free(pKeys);

        _isInitialized = (res == 0);
      } else {
        // Native stub mode
        _isInitialized = true;
      }

      return _isInitialized;
    } catch (e) {
      // Library not compiled or device does not support native yet
      _isInitialized = false;
      return false;
    }
  }

  static Future<String?> _copyAssetToFile(String assetPath, String targetPath) async {
    try {
      final file = File(targetPath);
      if (await file.exists() && await file.length() > 0) {
        return targetPath;
      }
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      return targetPath;
    } catch (_) {
      return null;
    }
  }

  /// Gọi infer nhận diện qua C++ FFI
  static Future<String> inferOcr({
    required Uint8List imageBytes,
    int width = 960,
    int height = 540,
  }) async {
    if (!_isInitialized || _ocrInfer == null || _ocrFree == null) {
      throw Exception('PaddleOCR NCNN Native Engine chưa được tải hoặc thiết bị chưa hỗ trợ native.');
    }

    final ptr = malloc.allocate<Uint8>(imageBytes.length);
    final nativeList = ptr.asTypedList(imageBytes.length);
    nativeList.setAll(0, imageBytes);

    try {
      final resPtr = _ocrInfer!(ptr, width, height, 4);
      if (resPtr == nullptr) {
        return 'Không nhận diện được nội dung từ PaddleOCR NCNN.';
      }

      final count = resPtr.ref.count;
      final buffer = StringBuffer();

      for (int i = 0; i < count; i++) {
        final box = resPtr.ref.boxes[i];
        final charCodes = <int>[];
        for (int j = 0; j < 512; j++) {
          final code = box.text[j];
          if (code == 0) break;
          charCodes.add(code);
        }
        final textLine = String.fromCharCodes(charCodes).trim();
        if (textLine.isNotEmpty) {
          buffer.writeln(textLine);
        }
      }

      _ocrFree!(resPtr);
      final result = buffer.toString().trim();
      return result.isEmpty ? 'Không tìm thấy ký tự văn bản.' : result;
    } finally {
      malloc.free(ptr);
    }
  }
}
