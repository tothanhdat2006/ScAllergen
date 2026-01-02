// lib/core/models/allergy_match_result.dart

class AllergyMatchResult {
  final List<String> mappedScannedAllergiesLabel;
  final List<String> mappedUserAllergiesLabel;
  final List<String> ingredientDetails;
  final List<String> displayLabels;

  AllergyMatchResult({
    required this.mappedScannedAllergiesLabel,
    required this.mappedUserAllergiesLabel,
    required this.ingredientDetails,
    required this.displayLabels,
  });

  factory AllergyMatchResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) {
      final list = json[key];
      if (list is List) {
        return list.map((e) => e?.toString() ?? "").toList();
      }
      return [];
    }

    final mappedScanned = parseList('mapped_scanned_allergies_label');
    final mappedUser = parseList('mapped_user_allergies_label');
    final ingredientsAllergies = parseList('ingredients_allergies');
    final List<String> dangers = [];
    for (int i = 0; i < mappedScanned.length; i++) {
      if (i < ingredientsAllergies.length && ingredientsAllergies[i].isNotEmpty) {
        dangers.add(mappedScanned[i].isNotEmpty ? mappedScanned[i] : ingredientsAllergies[i]);
      }
    }

    return AllergyMatchResult(
      mappedScannedAllergiesLabel: mappedScanned,
      mappedUserAllergiesLabel: mappedUser,
      ingredientDetails: ingredientsAllergies,
      displayLabels: dangers,
    );
  }
}