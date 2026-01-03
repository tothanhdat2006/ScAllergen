import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:NutriViet/core/models/allergy_match_result.dart';

class AllergyCheckService {
  static const String _baseUrl = 'https://XXX.ngrok-free.app';
  
  static String get baseUrl => _baseUrl;

  static Future<AllergyMatchResult> checkAllergy({
    required List<String> userAllergens,
    required List<String> scannedIngredients,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_allergens': userAllergens,
          'scanned_ingredients': scannedIngredients,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AllergyMatchResult.fromJson(data);
      } else {
        return _fallbackMatch(userAllergens, scannedIngredients);
      }
    } catch (e) {
      return _fallbackMatch(userAllergens, scannedIngredients);
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return "${s[0].toUpperCase()}${s.substring(1)}";
  }

  static AllergyMatchResult _fallbackMatch(
      List<String> userAllergens,
      List<String> scannedIngredients,
      ) {
    const Map<String, List<String>> knownAllergensMap = {
      'Milk': ['cheese', 'cream', 'yogurt', 'milk', 'whey', 'lactose', 'casein', 'butter'],
      'Egg': ['egg', 'mayonnaise', 'albumin', 'ovalbumin'],
      'Peanut': ['peanut', 'nut', 'arachis'],
      'Soy': ['soy', 'soya', 'lecithin', 'tofu', 'bean'],
      'Wheat': ['wheat', 'gluten', 'flour', 'bread', 'barley', 'rye', 'malt'],
      'Fish': ['fish', 'tuna', 'salmon', 'cod', 'anchovy'],
      'Shellfish': ['shrimp', 'crab', 'lobster', 'prawn', 'clam', 'mussel'],
      'Tree nut': ['almond', 'cashew', 'walnut', 'pecan', 'pistachio'],
    };

    const List<String> commonSafeIngredients = [
      'water', 'sugar', 'salt', 'oil', 'fat', 'starch', 'corn', 'rice',
      'flour', 'yeast', 'baking powder', 'cocoa', 'chocolate',
      'humectant', 'shortening', 'emulsifier', 'stabilizer', 'preservative',
      'acidity regulator', 'flavor', 'color', 'raising agent',
      'calcium', 'carbonate', 'vitamin', 'mineral', 'syrup', 'dextrose',
      'vegetable', 'palm', 'sunflower', 'canola',
      'premix', 'taurine', 'caffeine', 'inositol', 'carbonated water'
    ];

    final List<String> mappedScanned = [];
    final List<String> mappedUser = [];
    final List<String> details = [];
    final List<String> display = [];

    for (String rawIng in scannedIngredients) {
      String cleanIngLower = rawIng.toLowerCase();
      String foundAllergenCategory = '';
      String foundSafeName = '';

      for (var entry in knownAllergensMap.entries) {

        bool isUserAllergicToThisGroup = userAllergens.any(
                (u) => u.toLowerCase() == entry.key.toLowerCase()
                || entry.value.contains(u.toLowerCase())
        );

        if (isUserAllergicToThisGroup) {
          if (entry.value.any((k) => cleanIngLower.contains(k))) {
            foundAllergenCategory = entry.key;
            break;
          }
        }
      }

      if (foundAllergenCategory.isNotEmpty) {
        mappedScanned.add(foundAllergenCategory);
        mappedUser.add(foundAllergenCategory);
        details.add(foundAllergenCategory);
        display.add(foundAllergenCategory);
      } else {
        for (String safeItem in commonSafeIngredients) {
          if (cleanIngLower.contains(safeItem)) {
            foundSafeName = safeItem;
            break;
          }
        }

        if (foundSafeName.isNotEmpty) {
          mappedScanned.add(_capitalize(foundSafeName));
          mappedUser.add("");
          details.add("");
        } else {
          mappedScanned.add("");
          mappedUser.add("");
          details.add("");
        }
      }
    }

    return AllergyMatchResult(
      mappedScannedAllergiesLabel: mappedScanned,
      mappedUserAllergiesLabel: mappedUser,
      ingredientDetails: details,
      displayLabels: display,
    );
  }
}