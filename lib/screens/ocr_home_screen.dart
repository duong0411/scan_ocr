import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/paddle_ocr_ffi_service.dart';
import '../core/theme/app_theme.dart';

class OcrHomeScreen extends StatefulWidget {
  const OcrHomeScreen({super.key});

  @override
  State<OcrHomeScreen> createState() => _OcrHomeScreenState();
}

class _OcrHomeScreenState extends State<OcrHomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _imageName;
  int? _imageSize;

  bool _isEngineReady = false;
  bool _isLoading = false;
  String? _ocrResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initNcnnEngine();
  }

  Future<void> _initNcnnEngine() async {
    try {
      final ready = await PaddleOcrFfiService.initialize();
      if (mounted) {
        setState(() {
          _isEngineReady = ready;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEngineReady = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _imageName = file.name;
          _imageSize = bytes.length;
          _ocrResult = null;
          _errorMessage = null;
        });

        // Trigger OCR offline automatically
        _runPaddleOcr();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể chọn ảnh: $e';
      });
    }
  }

  Future<void> _runPaddleOcr() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chụp hoặc tải ảnh lên trước.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PaddleOcrFfiService.inferOcr(
        imageBytes: _selectedImageBytes!,
      );

      setState(() {
        _ocrResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_ocrResult != null && _ocrResult!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _ocrResult!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text('Đã sao chép văn bản vào bộ nhớ tạm!'),
            ],
          ),
          backgroundColor: AppTheme.bgCardLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearAll() {
    setState(() {
      _selectedImageBytes = null;
      _imageName = null;
      _imageSize = null;
      _ocrResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('PaddleOCR NCNN Mobile'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Chip(
              avatar: Icon(
                _isEngineReady ? Icons.offline_bolt_rounded : Icons.sync_rounded,
                size: 15,
                color: _isEngineReady ? AppTheme.secondary : AppTheme.warning,
              ),
              label: Text(
                _isEngineReady ? 'Offline 100%' : 'Đang nạp Model',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isEngineReady ? AppTheme.secondary : AppTheme.warning,
                ),
              ),
              backgroundColor: _isEngineReady
                  ? AppTheme.secondary.withValues(alpha: 0.12)
                  : AppTheme.warning.withValues(alpha: 0.12),
              side: BorderSide(
                color: _isEngineReady
                    ? AppTheme.secondary.withValues(alpha: 0.4)
                    : AppTheme.warning.withValues(alpha: 0.4),
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Info: 100% On-Device
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondary.withValues(alpha: 0.12),
                      AppTheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.memory_rounded, color: AppTheme.secondary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PaddleOCR DBNet + CRNN trên Tencent NCNN Engine\nChạy trực tiếp trên phần cứng máy • Không cần mạng hay API Key',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 18),

              // Action Cards (Chụp ảnh & Tải ảnh)
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'Chụp ảnh',
                      subtitle: 'Quét văn bản',
                      color: AppTheme.primary,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.photo_library_rounded,
                      title: 'Tải ảnh lên',
                      subtitle: 'Từ thư viện máy',
                      color: AppTheme.secondary,
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms),

              const SizedBox(height: 20),

              // Image Preview Section
              if (_selectedImageBytes != null) ...[
                _buildImagePreviewSection(),
                const SizedBox(height: 20),
              ],

              // Loading Indicator
              if (_isLoading) ...[
                _buildLoadingSection(),
                const SizedBox(height: 20),
              ],

              // Error Section
              if (_errorMessage != null) ...[
                _buildErrorSection(),
                const SizedBox(height: 20),
              ],

              // OCR Result Section
              if (_ocrResult != null && !_isLoading) ...[
                _buildResultSection(),
                const SizedBox(height: 30),
              ],

              // Empty state guide
              if (_selectedImageBytes == null && !_isLoading)
                _buildEmptyStateGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3460), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_rounded, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Hình ảnh đã chọn',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_imageName != null)
                Flexible(
                  child: Text(
                    _imageName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                ),
              const SizedBox(width: 8),
              if (_imageSize != null)
                Text(
                  '${(_imageSize! / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.danger),
                tooltip: 'Xóa ảnh',
                onPressed: _clearAll,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              width: double.infinity,
              color: Colors.black26,
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Đổi ảnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: Color(0xFF2A3460)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runPaddleOcr,
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text('Nhận diện lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3), width: 1),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'PaddleOCR NCNN đang nhận diện...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Xử lý trực tiếp trên thiết bị (DBNet Detection + CRNN Recognition)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    ).animate().shimmer(duration: 1500.ms);
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 22),
              SizedBox(width: 8),
              Text(
                'Thông báo Engine',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _runPaddleOcr,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    final wordCount = _ocrResult!.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final charCount = _ocrResult!.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kết quả OCR (NCNN Offline)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Nhận dạng thành công không cần mạng',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(Icons.short_text_rounded, '$wordCount từ'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.format_size_rounded, '$charCount ký tự'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.flash_on_rounded, 'NCNN C++ Engine'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3460), width: 1),
            ),
            child: SelectableText(
              _ocrResult!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3460), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateGuide() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF202646), width: 1),
      ),
      child: const Column(
        children: [
          Icon(Icons.bolt_rounded, color: AppTheme.secondary, size: 36),
          SizedBox(height: 12),
          Text(
            'PaddleOCR Offline Engine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '1. Nhấn nút [Chụp ảnh] hoặc [Tải ảnh lên] từ máy.\n2. Ứng dụng tự động kích hoạt C++ FFI Engine nhận diện văn bản hoàn toàn ngoại tuyến.\n3. Kết quả OCR được trả về ngay lập tức trên máy của bạn.',
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}
