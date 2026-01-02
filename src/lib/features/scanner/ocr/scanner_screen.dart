// lib/features/scanner/ocr/scanner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/features/scanner/ocr/result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error picking image"),
              backgroundColor: AppColors.error
          ),
        );
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _imageFile = null;
    });
  }

  void _confirmAndScan() {
    if (_imageFile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imagePath: _imageFile!.path,
          ocrData: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showGradientBackground = _imageFile == null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: showGradientBackground ? Colors.white24 : (isDark ? Colors.black45 : Colors.white54),
              shape: BoxShape.circle
          ),
          child: IconButton(
            icon: Icon(
                Icons.arrow_back,
                color: showGradientBackground ? Colors.white : AppColors.contentColor(context)
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "AI Nutrition Scan",
          style: TextStyle(
              color: showGradientBackground ? Colors.white : AppColors.contentColor(context),
              fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: showGradientBackground
            ? const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4E7CFE), Color(0xFF8E44AD), Color(0xFF00C4B4)],
          ),
        )
            : BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: _imageFile == null ? _buildSelectionView() : _buildPreviewView(context),
        ),
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 80, color: Colors.white),
        ),
        const SizedBox(height: 40),
        const Text(
          "What do you want to scan?",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Take a photo or upload a nutrition facts label for AI analysis.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        const SizedBox(height: 50),
        _buildLargeButton(
          icon: Icons.camera_alt_rounded,
          label: "Take a new photo",
          bgColor: Colors.white,
          textColor: AppColors.primary,
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 16),
        _buildLargeButton(
          icon: Icons.photo_library_rounded,
          label: "Choose from gallery",
          bgColor: Colors.white.withOpacity(0.2),
          textColor: Colors.white,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildLargeButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // View 2: Xem trước ảnh (Đã sửa lỗi Light/Dark mode)
  Widget _buildPreviewView(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Màu nền panel dưới
    final Color panelColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    // Màu chữ chính
    final Color titleColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    // Màu chữ phụ
    final Color subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    blurRadius: 15
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Is the image clear?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                "Ensure the food label is fully inside the frame",
                style: TextStyle(color: subtitleColor),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetScanner,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                          "Retake",
                          style: TextStyle(color: titleColor)
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmAndScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text(
                        "Analyze Now",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}