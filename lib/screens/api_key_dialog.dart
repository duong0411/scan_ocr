import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';

class ApiKeyDialog extends StatefulWidget {
  final String? currentApiKey;
  final String currentModel;
  final Function(String key, String model) onSaved;

  const ApiKeyDialog({
    super.key,
    required this.currentApiKey,
    required this.currentModel,
    required this.onSaved,
  });

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late TextEditingController _controller;
  late String _selectedModel;
  bool _obscureText = true;
  String? _errorMessage;

  final List<Map<String, String>> _availableModels = [
    {
      'id': 'gemini-1.5-flash',
      'name': 'Gemini 1.5 Flash (Nhanh & Tối ưu OCR)',
    },
    {
      'id': 'gemini-2.0-flash',
      'name': 'Gemini 2.0 Flash (Thế hệ mới nhất)',
    },
    {
      'id': 'gemini-1.5-pro',
      'name': 'Gemini 1.5 Pro (Độ chính xác cao)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentApiKey ?? '');
    _selectedModel = widget.currentModel;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập API Key';
      });
      return;
    }

    await StorageService.saveApiKey(key);
    await StorageService.saveSelectedModel(_selectedModel);
    widget.onSaved(key, _selectedModel);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình Gemini API Key thành công!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleClear() async {
    await StorageService.clearApiKey();
    widget.onSaved('', _selectedModel);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa API Key.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cài đặt Gemini API Key',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Nhập key từ Google AI Studio',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // API Key TextField
              const Text(
                'Gemini API Key',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                obscureText: _obscureText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste_rounded, size: 20),
                        tooltip: 'Dán từ clipboard',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            setState(() {
                              _controller.text = data!.text!.trim();
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 16),

              // Model Selection
              const Text(
                'Mô hình xử lý (Model)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A3460), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    dropdownColor: AppTheme.bgCardLight,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
                    items: _availableModels.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['id'],
                        child: Text(m['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedModel = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hint note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn có thể lấy Gemini API Key miễn phí tại: https://aistudio.google.com/app/apikey. Key được lưu trên thiết bị của bạn.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  if (widget.currentApiKey != null && widget.currentApiKey!.isNotEmpty)
                    TextButton.icon(
                      onPressed: _handleClear,
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                      label: const Text('Xóa key', style: TextStyle(color: AppTheme.danger)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Lưu Key'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
