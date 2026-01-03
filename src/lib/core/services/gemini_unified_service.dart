// lib/core/services/gemini_unified_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiUnifiedScanner {
  static const String _modelId = 'gemini-2.5-flash';
  static const String _apiKey = String.fromEnvironment('API_KEY', defaultValue: 'YOUR_API_KEY_HERE');

  late final GenerativeModel _model;

  GeminiUnifiedScanner() {
    if (_apiKey.isEmpty || _apiKey.contains('YOUR_API_KEY_HERE')) {
      throw StateError(
          'Gemini API_KEY is not configured. Set it via --dart-define or environment variable.');
    }
    _model = GenerativeModel(
      model: _modelId,
      apiKey: _apiKey,
    );
  }

  Future<UnifiedScanResult> analyzeImageAndProfile({
    required File imageFile,
    List<String>? userAllergensVi,
  }) async {
    final Uint8List bytes = await imageFile.readAsBytes();

    final String prompt = """
You are an expert food safety assistant, OCR specialist, and translator. 
Perform these 3 tasks simultaneously based on the provided food label image and user data.

--- TASK 1: INGREDIENTS LIST ---
1. Find the ingredients list (English or Vietnamese).
2. Extract it. If in Vietnamese, translate to standard English.
3. Remove parens with ONLY numbers/codes e.g. (322), (E123). Keep parens with text e.g. (soy).
4. Do not include nutrition info.
5. Remove qualitative numbers such as 15%, 15g...

--- TASK 2: LABEL WARNINGS ---
1. Find allergen declarations like "Contains", "May contain", "Produced in factory...", "Chứa", "Có thể chứa".
2. Extract the allergens listed.
3. Translate to English if in Vietnamese.

--- OUTPUT FORMAT ---
Return ONLY valid JSON with this exact structure (no markdown, no explanations):
{
  "ingredients_text": "Water\\nSugar\\nMilk powder...",
  "label_warnings": {
    "contains": ["milk", "soy"],
    "may_contain": ["peanuts"]
  },
  "user_allergens_en": ["milk", "egg", "shrimp"]
}
""";

    final List<Content> contents = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', bytes),
      ])
    ];

    try {
      final response = await _model.generateContent(contents);

      if (response.text == null || response.text!.trim().isEmpty) {
        throw Exception('Gemini returned empty response');
      }

      String raw = response.text!.trim();
      if (raw.startsWith('```')) {
        raw = raw.replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '').trim();
      }

      final Map<String, dynamic> jsonResult = jsonDecode(raw);

      return UnifiedScanResult.fromJson(jsonResult);

    } catch (e) {
      debugPrint("Gemini Unified Scan Error: $e");
      return UnifiedScanResult(
        ingredientsText: "",
        labelWarnings: {"contains": [], "may_contain": []},
        userAllergensEn: [],
      );
    }
  }
}

class UnifiedScanResult {
  final String ingredientsText;
  final Map<String, List<String>> labelWarnings;
  final List<String> userAllergensEn;

  UnifiedScanResult({
    required this.ingredientsText,
    required this.labelWarnings,
    required this.userAllergensEn,
  });

  factory UnifiedScanResult.fromJson(Map<String, dynamic> json) {
    String ing = json['ingredients_text']?.toString() ?? '';

    Map<String, dynamic> warningsRaw = json['label_warnings'] is Map
        ? json['label_warnings']
        : {};

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return UnifiedScanResult(
      ingredientsText: ing,
      labelWarnings: {
        "contains": parseList(warningsRaw['contains']),
        "may_contain": parseList(warningsRaw['may_contain']),
      },
      userAllergensEn: parseList(json['user_allergens_en']),
    );
  }
}