import 'dart:io';
import 'package:flutter/material.dart';
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/core/models/allergy_match_result.dart';
import 'package:NutriViet/core/services/allergy_check_service.dart';
import 'package:NutriViet/core/services/gemini_unified_service.dart';
import 'package:NutriViet/core/services/social_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic>? ocrData;

  const ResultScreen({
    super.key,
    required this.imagePath,
    this.ocrData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  bool _isProcessing = true;
  bool _isPosting = false;

  AllergyMatchResult? _allergyResult;
  AllergyMatchResult? _mayContainResult;

  List<String> _ocrIngredients = [];
  Map<String, List<String>> _labelWarnings = {"contains": [], "may_contain": []};

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startUnifiedAnalysis();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _startUnifiedAnalysis() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      List<String> userAllergensRaw = [];
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          if (data['allergies'] != null) {
            userAllergensRaw = List<String>.from(data['allergies']);
          }
        }
      } catch (e) {
        debugPrint("Lỗi lấy Firestore: $e");
        final prefs = await SharedPreferences.getInstance();
        userAllergensRaw = prefs.getStringList('profile_${user.uid}_allergies') ?? [];
      }
      final List<String> refinedAllergies = _refineAllergies(userAllergensRaw);
      debugPrint("Dị ứng User (Refined): $refinedAllergies");

      final scanner = GeminiUnifiedScanner();
      final unifiedResult = await scanner.analyzeImageAndProfile(
        imageFile: File(widget.imagePath),
        userAllergensVi: userAllergensRaw,
      );

      _labelWarnings = unifiedResult.labelWarnings;
      final String rawIngredients = unifiedResult.ingredientsText;
      _ocrIngredients = rawIngredients.isEmpty
          ? <String>[]
          : rawIngredients
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final matchResult = await AllergyCheckService.checkAllergy(
        userAllergens: refinedAllergies,
        scannedIngredients: _ocrIngredients,
      );
      AllergyMatchResult? mayContainChecked;
      final List<String> mayContainList = _labelWarnings['may_contain'] ?? [];

      if (mayContainList.isNotEmpty) {
        mayContainChecked = await AllergyCheckService.checkAllergy(
          userAllergens: refinedAllergies,
          scannedIngredients: mayContainList,
        );
      }

      if (mounted) {
        setState(() {
          _allergyResult = matchResult;
          _mayContainResult = mayContainChecked;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Unified Analysis Failed: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  List<String> _refineAllergies(List<String> rawList) {
    final Map<String, String> keywordMapping = {
      'chicken egg': 'Egg', 'duck egg': 'Egg', 'egg yolk': 'Egg', 'egg white': 'Egg', 'trứng': 'Egg',
      'cow milk': 'Milk', 'goat milk': 'Milk', 'powdered milk': 'Milk', 'sữa': 'Milk', 'dairy': 'Milk',
      'shrimp': 'Shellfish', 'crab': 'Shellfish', 'lobster': 'Shellfish', 'prawn': 'Shellfish',
      'clam': 'Shellfish', 'mussel': 'Shellfish', 'tôm': 'Shellfish', 'cua': 'Shellfish',
      'peanut': 'Peanut', 'lạc': 'Peanut', 'đậu phộng': 'Peanut',
      'almond': 'Tree nut', 'cashew': 'Tree nut', 'walnut': 'Tree nut', 'hạnh nhân': 'Tree nut',
      'flour': 'Wheat', 'gluten': 'Wheat', 'mì': 'Wheat',
      'soy': 'Soybean', 'soya': 'Soybean', 'soybean': 'Soybean',
      'đậu nành': 'Soybean', 'edamame': 'Soybean', 'tofu': 'Soybean', 'lecithin': 'Soybean'
    };

    Set<String> refinedSet = {};
    for (var item in rawList) {
      String lowerItem = item.toLowerCase().trim();
      if (keywordMapping.containsKey(lowerItem)) {
        refinedSet.add(keywordMapping[lowerItem]!);
      } else if (lowerItem.contains('egg')) {
        refinedSet.add('Egg');
      } else if (lowerItem.contains('milk')) {
        refinedSet.add('Milk');
      } else if (lowerItem.contains('nut')) {
        refinedSet.add('Tree nut');
      } else if (lowerItem.contains('soy') || lowerItem.contains('đậu nành')) {
        refinedSet.add('Soybean');
      } else {
        refinedSet.add(item);
      }
    }
    return refinedSet.toList();
  }

  Future<void> _shareToCommunity() async {
    if (_isPosting) return;

    bool isRiskyMain = _allergyResult?.ingredientDetails.any((e) => e.isNotEmpty) ?? false;
    bool isRiskyMayContain = _mayContainResult?.ingredientDetails.any((e) => e.isNotEmpty) ?? false;

    setState(() => _isPosting = true);

    try {
      await SocialService().postToCommunity(
        imageFile: File(widget.imagePath),
        hasAllergyRisk: isRiskyMain || isRiskyMayContain,
        ingredients: _ocrIngredients,
        labelContains: _labelWarnings['contains'] ?? [],
        mayContain: _labelWarnings['may_contain'] ?? [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Posted to Community! 📸"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint("Post failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Post failed: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }
  String _cleanIngredient(String raw) {
    if (raw.isEmpty) return '';
    String cleaned = raw.trim();
    if (cleaned.contains('[')) cleaned = cleaned.split('[').first.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\(Path length:[^)]*\)', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'PATH:\s*None', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\[\]\(\)\->]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  void _openFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(widget.imagePath)),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAllergySummaryCard() {
    final List<String> dangerousIngredients = [];
    if (_allergyResult != null) {
      for (int i = 0; i < _ocrIngredients.length; i++) {
        if (i < _allergyResult!.ingredientDetails.length &&
            _allergyResult!.ingredientDetails[i].isNotEmpty) {
          dangerousIngredients.add(_cleanIngredient(_ocrIngredients[i]));
        }
      }
    }
    final List<String> dangerousMayContain = [];
    final List<String> mayContainList = _labelWarnings['may_contain'] ?? [];
    if (_mayContainResult != null) {
      for (int i = 0; i < mayContainList.length; i++) {
        if (i < _mayContainResult!.ingredientDetails.length &&
            _mayContainResult!.ingredientDetails[i].isNotEmpty) {
          dangerousMayContain.add(_cleanIngredient(mayContainList[i]));
        }
      }
    }

    final bool hasRisk = dangerousIngredients.isNotEmpty || dangerousMayContain.isNotEmpty;
    if (!hasRisk) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success, width: 2.5),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle, size: 48, color: AppColors.success),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Safe", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success)),
                  SizedBox(height: 8),
                  Text("No known allergens detected based on your profile.", style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error, width: 2.5),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Allergy Warning!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        ...dangerousIngredients.map((name) => Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Contains: $name",
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )),
        ...dangerousMayContain.map((name) => Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF57C00),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "May Contain: $name",
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContainsWarning() {
    final List<String> contains = _labelWarnings['contains'] ?? [];
    if (contains.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Text("Label: Contains", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          ...contains.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text("- $item", style: const TextStyle(fontSize: 15)),
          )),
        ],
      ),
    );
  }

  Widget _buildMayContainWarning() {
    final List<String> mayContain = _labelWarnings['may_contain'] ?? [];
    if (mayContain.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.help_outline, color: AppColors.warning, size: 28),
              SizedBox(width: 12),
              Text("Label: May contain", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
            ],
          ),
          const SizedBox(height: 12),
          ...mayContain.asMap().entries.map((entry) {
            int index = entry.key;
            String originalText = entry.value;

            bool isAllergen = false;
            String detailRisk = "";
            String mappedName = "";

            if (_mayContainResult != null && index < _mayContainResult!.ingredientDetails.length) {
              detailRisk = _mayContainResult!.ingredientDetails[index];
              mappedName = _mayContainResult!.mappedScannedAllergiesLabel[index];
              isAllergen = detailRisk.isNotEmpty;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: isAllergen
                        ? const Icon(Icons.warning, color: AppColors.error, size: 18)
                        : const Icon(Icons.circle, size: 8, color: Colors.black54),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: RichText(
                      text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                          children: [
                            TextSpan(
                                text: originalText,
                                style: TextStyle(
                                  fontWeight: isAllergen ? FontWeight.bold : FontWeight.normal,
                                  color: isAllergen ? AppColors.error : Colors.black87,
                                )
                            ),
                            if (isAllergen)
                              TextSpan(
                                  text: "\nRisk: $detailRisk (${mappedName.isNotEmpty ? mappedName : 'Detected'})",
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4
                                  )
                              )
                          ]
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showIngredientDetail(BuildContext context, String originalName, String mappedName, String allergyInfo) {
    final bool isNotFound = mappedName.isEmpty;
    final String displayMapped = isNotFound ? "Not found in Database" : mappedName;
    final bool hasAllergy = allergyInfo.isNotEmpty;
    final String displayAllergy = hasAllergy ? allergyInfo : "None";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Ingredient Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _buildDetailRow("Scanned Name:", originalName),
              const SizedBox(height: 20),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 20),
              _buildDetailRow("Database Name:", displayMapped, valueColor: isNotFound ? Colors.grey : Colors.black87),
              const SizedBox(height: 20),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 20),
              _buildDetailRow("Allergen Risk:", displayAllergy, valueColor: hasAllergy ? AppColors.error : AppColors.success, isBold: true),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = Colors.black87, bool isBold = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 18, color: Colors.black87),
        children: [
          TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: " $value", style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerItem(height: 300, width: double.infinity, borderRadius: 0),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerItem(height: 100, width: double.infinity, borderRadius: 20),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerItem(height: 80, width: double.infinity, borderRadius: 16),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerItem(height: 24, width: 200, borderRadius: 4),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(6, (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildShimmerItem(height: 50, width: double.infinity, borderRadius: 12),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem({required double height, required double width, required double borderRadius}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasRisk = false;
    if (_allergyResult != null && _allergyResult!.ingredientDetails.any((e) => e.isNotEmpty)) hasRisk = true;
    if (_mayContainResult != null && _mayContainResult!.ingredientDetails.any((e) => e.isNotEmpty)) hasRisk = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Results"),
        backgroundColor: hasRisk ? AppColors.error.withAlpha(230) : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      floatingActionButton: _isProcessing
          ? null
          : FloatingActionButton.extended(
        onPressed: _isPosting ? null : _shareToCommunity,
        backgroundColor: AppColors.primary,
        icon: _isPosting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send_rounded, color: Colors.white),
        label: Text(_isPosting ? "Posting..." : "Share to Community", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: _isProcessing
          ? _buildSkeletonLoading()
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            GestureDetector(
              onTap: _openFullScreenImage,
              child: Container(
                height: 300,
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildAllergySummaryCard(),
            _buildContainsWarning(),
            _buildMayContainWarning(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Product Ingredients:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Column(
                    children: _ocrIngredients.asMap().entries.map((entry) {
                      final int i = entry.key;
                      final String originalName = entry.value.trim();

                      final int mappedLength = _allergyResult?.mappedScannedAllergiesLabel.length ?? 0;
                      final int detailsLength = _allergyResult?.ingredientDetails.length ?? 0;

                      final String mappedName = i < mappedLength ? _allergyResult!.mappedScannedAllergiesLabel[i] : "";
                      final String allergyInfo = i < detailsLength ? _allergyResult!.ingredientDetails[i] : "";

                      Color itemColor;
                      IconData itemIcon;

                      if (allergyInfo.isNotEmpty) {
                        itemColor = AppColors.error;
                        itemIcon = Icons.warning_amber_rounded;
                      } else if (mappedName.isEmpty) {
                        itemColor = Colors.grey;
                        itemIcon = Icons.help_outline;
                      } else {
                        itemColor = AppColors.success;
                        itemIcon = Icons.check_circle_outline;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onTap: () => _showIngredientDetail(context, originalName, mappedName, allergyInfo),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: itemColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    originalName,
                                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(itemIcon, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}