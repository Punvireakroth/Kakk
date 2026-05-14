import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_role_suggestion.dart';
import '../models/spending_summary.dart';
import '../utils/budget_rule_categories.dart';

/// Stores the Gemini API key in secure storage when the OS allows it.
///
/// If Keychain / Keystore write fails (simulators, tight policies, etc.), the
/// same key is stored via [SharedPreferences] so the feature keeps working.
/// Prefer secure storage when available.
class AiRoleGeminiKeyStorage {
  AiRoleGeminiKeyStorage._();

  /// Uses plugin defaults (`KeychainAccessibility.unlocked` on Apple platforms).
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static const String storageKey = 'chashew_gemini_api_key';

  /// Weak fallback when [_secure] throws on read/write.
  static const String _prefsFallbackKey = 'chashew_gemini_api_key_prefs_fallback';

  static Future<String?> readApiKey() async {
    try {
      final v = await _secure.read(key: storageKey);
      final t = v?.trim();
      if (t != null && t.isNotEmpty) return t;
    } catch (e, st) {
      debugPrint('AiRoleGeminiKeyStorage secure read: $e\n$st');
    }
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getString(_prefsFallbackKey)?.trim();
    return (f != null && f.isNotEmpty) ? f : null;
  }

  static Future<void> writeApiKey(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      try {
        await _secure.delete(key: storageKey);
      } catch (e, st) {
        debugPrint('AiRoleGeminiKeyStorage secure delete: $e\n$st');
      }
      await prefs.remove(_prefsFallbackKey);
      return;
    }

    try {
      await _secure.write(key: storageKey, value: trimmed);
      await prefs.remove(_prefsFallbackKey);
    } catch (e, st) {
      debugPrint(
        'AiRoleGeminiKeyStorage secure write failed; using prefs fallback: $e\n$st',
      );
      await prefs.setString(_prefsFallbackKey, trimmed);
    }
  }

  static Future<bool> hasApiKey() async {
    final v = await readApiKey();
    return v != null && v.trim().isNotEmpty;
  }
}

/// Calls Gemini with [SpendingSummary.structuredPrompt] and parses role suggestions.
class AiRoleService {
  AiRoleService._();

  static const _geminiModel = 'gemini-2.0-flash';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

  static const Duration _timeout = Duration(seconds: 35);

  static const String _fallbackNeedsReason =
      'Using the default 50% share for essential spending.';
  static const String _fallbackWantsReason =
      'Using the default 30% share for flexible spending.';
  static const String _fallbackGoalsReason =
      'Using the default 20% share for savings and goals.';

  /// Returns an AI suggestion or a silent 50/30/20 fallback per product rules.
  static Future<AiRoleSuggestion> suggest(SpendingSummary summary) async {
    final income = summary.incomeAmount;
    if (income <= 0) {
      return _fallbackZeroIncome();
    }

    final apiKey = await AiRoleGeminiKeyStorage.readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return _fallback503020(income);
    }

    try {
      final rawJson = await _callGemini(apiKey.trim(), summary);
      final parsed = _parseSuggestion(rawJson, income);
      if (parsed != null) return parsed;
    } catch (_) {
      /* silent fallback */
    }

    return _fallback503020(income);
  }

  static AiRoleSuggestion _fallbackZeroIncome() {
    return const AiRoleSuggestion(
      needsAmount: 0,
      wantsAmount: 0,
      goalsAmount: 0,
      needsReason: _fallbackNeedsReason,
      wantsReason: _fallbackWantsReason,
      goalsReason: _fallbackGoalsReason,
      isFallback: true,
    );
  }

  static AiRoleSuggestion _fallback503020(double income) {
    final needs =
        (income * BudgetRulePercentages.needs * 100).roundToDouble() / 100;
    final wants =
        (income * BudgetRulePercentages.wants * 100).roundToDouble() / 100;
    final goals = income - needs - wants;

    return AiRoleSuggestion(
      needsAmount: needs,
      wantsAmount: wants,
      goalsAmount: goals,
      needsReason: _fallbackNeedsReason,
      wantsReason: _fallbackWantsReason,
      goalsReason: _fallbackGoalsReason,
      isFallback: true,
    );
  }

  static Future<String> _callGemini(String apiKey, SpendingSummary summary) async {
    final uri = Uri.parse('$_endpoint?key=${Uri.encodeQueryComponent(apiKey)}');

    final userPrompt = '''
${summary.structuredPrompt}

Respond with JSON only (no markdown), exactly in this shape:
{"needs":{"amount":<number>,"reason":"<one short sentence>"},"wants":{"amount":<number>,"reason":"<one short sentence>"},"goals":{"amount":<number>,"reason":"<one short sentence>"}}

The three amounts must be non-negative and sum to exactly ${summary.incomeAmount} (match to two decimal places).
'''.trim();

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.35,
      },
    });

    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini HTTP ${response.statusCode}');
    }

    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractCandidateText(outer);
    if (text == null || text.isEmpty) {
      throw Exception('Empty Gemini body');
    }
    return _stripMarkdownFence(text);
  }

  static String? _extractCandidateText(Map<String, dynamic> outer) {
    final candidates = outer['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map<String, dynamic>) return null;
    final content = first['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;
    final part0 = parts.first;
    if (part0 is! Map<String, dynamic>) return null;
    final text = part0['text'];
    return text is String ? text : null;
  }

  static String _stripMarkdownFence(String text) {
    final trimmed = text.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)```$', multiLine: true);
    final m = fence.firstMatch(trimmed);
    if (m != null) return m.group(1)!.trim();
    return trimmed;
  }

  static AiRoleSuggestion? _parseSuggestion(String rawJson, double income) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) return null;

    double? needAmt = _readAmount(decoded['needs']);
    double? wantAmt = _readAmount(decoded['wants']);
    double? goalAmt = _readAmount(decoded['goals']);

    if (needAmt == null || wantAmt == null || goalAmt == null) return null;
    if (needAmt < 0 || wantAmt < 0 || goalAmt < 0) return null;

    var needs = needAmt;
    var wants = wantAmt;
    var goals = goalAmt;
    var total = needs + wants + goals;

    if (total <= 0) return null;

    if ((total - income).abs() > 0.02) {
      final scale = income / total;
      needs = needs * scale;
      wants = wants * scale;
      goals = goals * scale;
    }

    needs = (needs * 100).roundToDouble() / 100;
    wants = (wants * 100).roundToDouble() / 100;
    goals = income - needs - wants;

    if (goals < 0) return null;

    final nReason = _readReason(decoded['needs']);
    final wReason = _readReason(decoded['wants']);
    final gReason = _readReason(decoded['goals']);

    return AiRoleSuggestion(
      needsAmount: needs,
      wantsAmount: wants,
      goalsAmount: goals,
      needsReason: nReason,
      wantsReason: wReason,
      goalsReason: gReason,
      isFallback: false,
    );
  }

  static double? _readAmount(dynamic bucket) {
    if (bucket is! Map<String, dynamic>) return null;
    final a = bucket['amount'];
    if (a is num) return a.toDouble();
    return null;
  }

  static String _readReason(dynamic bucket) {
    if (bucket is Map<String, dynamic>) {
      final r = bucket['reason'];
      if (r is String && r.trim().isNotEmpty) return r.trim();
    }
    return 'Suggested based on your summarized spending pattern.';
  }
}
