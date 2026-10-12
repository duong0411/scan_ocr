import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/ocr_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (transparent status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const GeminiOcrApp());
}

class GeminiOcrApp extends StatelessWidget {
  const GeminiOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini OCR App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OcrHomeScreen(),
    );
  }
}
