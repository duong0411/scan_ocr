import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PNG header magic bytes validation', () {
    final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    expect(pngBytes[0], equals(0x89));
    expect(pngBytes[1], equals(0x50));
    expect(pngBytes[2], equals(0x4E));
    expect(pngBytes[3], equals(0x47));
  });
}
