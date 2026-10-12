import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/gemini_ocr_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import 'api_key_dialog.dart';

class OcrHomeScreen extends StatefulWidget {
  const OcrHomeScreen({super.key});

  @override
  State<OcrHomeScreen> createState() => _OcrHomeScreenState();
}

class _OcrHomeScreenState extends State<OcrHomeScreen> {
  final ImagePicker _picker = ImagePicker();

  String? _apiKey;
  String _selectedModel = StorageService.defaultModel;

  Uint8List? _selectedImageBytes;
  String? _imageName;
  int? _imageSize;

  bool _isLoading = false;
  String? _ocrResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final key = await StorageService.getApiKey();
    final model = await StorageService.getSelectedModel();
    setState(() {
      _apiKey = key;
      _selectedModel = model;
    });

    // If no key yet, prompt user
    if (key == null || key.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiKeyDialog();
      });
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ApiKeyDialog(
        currentApiKey: _apiKey,
        currentModel: _selectedModel,
        onSaved: (newKey, newModel) {
          setState(() {
            _apiKey = newKey;
            _selectedModel = newModel;
          });
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 92, // Keep good quality for OCR
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

        // Automatically trigger OCR if API key is present
        if (_apiKey != null && _apiKey!.isNotEmpty) {
          _runOcr();
        } else {
          _showApiKeyDialog();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể chọn ảnh: $e';
      });
    }
  }

  Future<void> _runOcr() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chụp hoặc tải ảnh lên trước.')),
      );
      return;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await GeminiOcrService.performOcr(
        imageBytes: _selectedImageBytes!,
        apiKey: _apiKey!,
        model: _selectedModel,
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
    final bool hasKey = _apiKey != null && _apiKey!.isNotEmpty;

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
              child: const Icon(Icons.document_scanner_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Gemini OCR App'),
          ],
        ),
        actions: [
          // API Key status pill
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: Icon(
                hasKey ? Icons.key_rounded : Icons.warning_amber_rounded,
                size: 16,
                color: hasKey ? AppTheme.secondary : AppTheme.warning,
              ),
              label: Text(
                hasKey ? 'Key: Đã lưu' : 'Chưa có Key',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasKey ? AppTheme.secondary : AppTheme.warning,
                ),
              ),
              backgroundColor: hasKey
                  ? AppTheme.secondary.withValues(alpha: 0.12)
                  : AppTheme.warning.withValues(alpha: 0.12),
              side: BorderSide(
                color: hasKey
                    ? AppTheme.secondary.withValues(alpha: 0.4)
                    : AppTheme.warning.withValues(alpha: 0.4),
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: _showApiKeyDialog,
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
              // Banner / Model Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mô hình: $_selectedModel • Nhận diện văn bản, chữ viết tay & bảng',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _showApiKeyDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Đổi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 18),

              // Hero Input Choice Cards
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'Chụp ảnh',
                      subtitle: 'Dùng Camera',
                      color: AppTheme.primary,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.photo_library_rounded,
                      title: 'Tải ảnh lên',
                      subtitle: 'Từ thư viện ảnh',
                      color: AppTheme.secondary,
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms),

              const SizedBox(height: 20),

              // Image Preview Card (if selected)
              if (_selectedImageBytes != null) ...[
                _buildImagePreviewSection(),
                const SizedBox(height: 20),
              ],

              // Loading Indicator
              if (_isLoading) ...[
                _buildLoadingSection(),
                const SizedBox(height: 20),
              ],

              // Error Message Card
              if (_errorMessage != null) ...[
                _buildErrorSection(),
                const SizedBox(height: 20),
              ],

              // OCR Result Section
              if (_ocrResult != null && !_isLoading) ...[
                _buildResultSection(),
                const SizedBox(height: 30),
              ],

              // Empty state guide if nothing selected yet
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
                  onPressed: _isLoading ? null : _runOcr,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Nhận diện lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
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
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gemini AI đang phân tích ảnh...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đang nhận diện ký tự quang học, bố cục bảng và ngôn ngữ...',
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
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Lỗi nhận diện OCR',
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
          Row(
            children: [
              TextButton.icon(
                onPressed: _showApiKeyDialog,
                icon: const Icon(Icons.vpn_key_rounded, size: 16, color: AppTheme.primaryLight),
                label: const Text('Kiểm tra API Key', style: TextStyle(color: AppTheme.primaryLight)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _runOcr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Thử lại'),
              ),
            ],
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
                    'Kết quả OCR',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Trích xuất văn bản thành công',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              // Quick Copy Button
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
          // Stats row
          Row(
            children: [
              _buildStatChip(Icons.short_text_rounded, '$wordCount từ'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.format_size_rounded, '$charCount ký tự'),
            ],
          ),
          const SizedBox(height: 16),
          // Recognized text container
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
      child: Column(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.warning, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Hướng dẫn sử dụng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Nhấn nút [Chụp ảnh] hoặc [Tải ảnh lên] để chọn ảnh tài liệu, hóa đơn, biển báo hoặc chữ viết tay.\n2. Cài đặt Gemini API Key của bạn (chỉ cần nhập 1 lần).\n3. Ứng dụng sẽ tự động phân tích và trích xuất nội dung văn bản cho bạn.',
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

