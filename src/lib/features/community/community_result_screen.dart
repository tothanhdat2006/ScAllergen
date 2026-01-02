import 'package:flutter/material.dart';
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/core/models/allergy_match_result.dart';
import 'package:NutriViet/core/services/allergy_check_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityResultScreen extends StatefulWidget {
  final String imageUrl;
  final List<dynamic> ingredients;
  final List<dynamic>? mayContain;

  const CommunityResultScreen({
    super.key,
    required this.imageUrl,
    required this.ingredients,
    this.mayContain,
  });

  @override
  State<CommunityResultScreen> createState() => _CommunityResultScreenState();
}

class _CommunityResultScreenState extends State<CommunityResultScreen> {
  bool _isProcessing = true;
  AllergyMatchResult? _allergyResult;
  AllergyMatchResult? _mayContainResult;

  @override
  void initState() {
    super.initState();
    _analyzeForCurrentUser();
  }

  Future<void> _analyzeForCurrentUser() async {
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
        debugPrint("❌ Lỗi lấy Firestore: $e");
        final prefs = await SharedPreferences.getInstance();
        userAllergensRaw = prefs.getStringList('profile_${user.uid}_allergies') ?? [];
      }
      final List<String> refinedAllergies = _refineAllergies(userAllergensRaw);
      final List<String> safeIngredients = widget.ingredients.map((e) => e.toString()).toList();
      final List<String> safeMayContain = widget.mayContain?.map((e) => e.toString()).toList() ?? [];
      final matchResult = await AllergyCheckService.checkAllergy(
        userAllergens: refinedAllergies,
        scannedIngredients: safeIngredients,
      );

      AllergyMatchResult? mayContainChecked;
      if (safeMayContain.isNotEmpty) {
        mayContainChecked = await AllergyCheckService.checkAllergy(
          userAllergens: refinedAllergies,
          scannedIngredients: safeMayContain,
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
      debugPrint("❌ Lỗi phân tích Community: $e");
      if (mounted) setState(() => _isProcessing = false);
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
              child: Image.network(
                widget.imageUrl,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.broken_image, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text("Image unavailable", style: TextStyle(color: Colors.white))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRiskyMain = _allergyResult?.ingredientDetails.any((e) => e.isNotEmpty) ?? false;
    bool isRiskyMayContain = _mayContainResult?.ingredientDetails.any((e) => e.isNotEmpty) ?? false;
    bool isTotalRisk = isRiskyMain || isRiskyMayContain;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Check"),
        backgroundColor: isTotalRisk ? AppColors.error : AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
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
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 300,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text("Image load failed", style: TextStyle(color: Colors.grey))
                          ],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
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
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildAllergySummaryCard(),
            _buildMayContainWarning(),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ingredient Analysis:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (widget.ingredients.isEmpty)
                    const Text("No ingredient data available.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),

                  ...widget.ingredients.asMap().entries.map((entry) {
                    return _buildIngredientItem(entry.key, entry.value.toString());
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergySummaryCard() {
    final dangerousIngredients = _allergyResult?.ingredientDetails
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => widget.ingredients[e.key].toString())
        .toSet().toList() ?? [];

    final dangerousMayContain = _mayContainResult?.ingredientDetails
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => widget.mayContain![e.key].toString())
        .toSet().toList() ?? [];

    final bool hasRisk = dangerousIngredients.isNotEmpty || dangerousMayContain.isNotEmpty;

    if (!hasRisk) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success, width: 2)
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle, size: 40, color: AppColors.success),
            SizedBox(width: 16),
            Expanded(child: Text("Safe for YOU!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success))),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error, width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 40, color: AppColors.error),
              SizedBox(width: 16),
              Expanded(child: Text("Warning: Don't Eat!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error))),
            ],
          ),
          const SizedBox(height: 12),
          if (dangerousIngredients.isNotEmpty)
            ...dangerousIngredients.map((e) => Text("• Contains: $e", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          if (dangerousMayContain.isNotEmpty)
            ...dangerousMayContain.map((e) => Text("• May Contain: $e", style: const TextStyle(fontSize: 16, color: Color(0xFFF57C00), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildMayContainWarning() {
    final List<dynamic> mayContain = widget.mayContain ?? [];
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
            String item = entry.value.toString();

            bool isAllergen = false;
            String detailInfo = "";

            if (_mayContainResult != null && index < _mayContainResult!.ingredientDetails.length) {
              detailInfo = _mayContainResult!.ingredientDetails[index];
              isAllergen = detailInfo.isNotEmpty;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (isAllergen)
                    const Icon(Icons.warning, color: AppColors.error, size: 16)
                  else
                    const Icon(Icons.circle, size: 6, color: Colors.black54),

                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                          children: [
                            TextSpan(
                                text: item,
                                style: TextStyle(
                                  fontWeight: isAllergen ? FontWeight.bold : FontWeight.normal,
                                  color: isAllergen ? AppColors.error : Colors.black87,
                                )
                            ),
                            if (isAllergen)
                              TextSpan(
                                  text: " (Risk: $detailInfo)",
                                  style: const TextStyle(color: AppColors.error, fontSize: 13, fontStyle: FontStyle.italic)
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

  Widget _buildIngredientItem(int index, String originalName) {
    final int mappedLength = _allergyResult?.mappedScannedAllergiesLabel.length ?? 0;
    final int detailsLength = _allergyResult?.ingredientDetails.length ?? 0;

    final String mappedName = index < mappedLength ? _allergyResult!.mappedScannedAllergiesLabel[index] : "";
    final String allergyInfo = index < detailsLength ? _allergyResult!.ingredientDetails[index] : "";

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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(color: itemColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(originalName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    if (mappedName.isNotEmpty && mappedName.toLowerCase() != originalName.toLowerCase())
                      Text("($mappedName)", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(itemIcon, color: Colors.white, size: 20),
            ],
          ),
        ),
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
              _buildDetailRow("Original:", originalName),
              const SizedBox(height: 20),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 20),
              _buildDetailRow("Database:", displayMapped, valueColor: isNotFound ? Colors.grey : Colors.black87),
              const SizedBox(height: 20),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 20),
              _buildDetailRow("Risk:", displayAllergy, valueColor: hasAllergy ? AppColors.error : AppColors.success, isBold: true),
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
}