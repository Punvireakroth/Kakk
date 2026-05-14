import 'package:flutter/foundation.dart';

import 'ai_role_suggestion.dart';

/// One persisted AI role split snapshot (see `ai_role_suggestions` table).
@immutable
class AiRoleSuggestionRecord {
  const AiRoleSuggestionRecord({
    required this.id,
    required this.incomeAmount,
    required this.currencyCode,
    required this.periodStartMs,
    required this.periodEndMs,
    required this.accountId,
    required this.createdAtMs,
    required this.suggestion,
  });

  final String id;
  final double incomeAmount;
  final String currencyCode;
  final int periodStartMs;
  final int periodEndMs;
  final String? accountId;
  final int createdAtMs;
  final AiRoleSuggestion suggestion;

  factory AiRoleSuggestionRecord.fromMap(Map<String, Object?> map) {
    return AiRoleSuggestionRecord(
      id: map['id']! as String,
      incomeAmount: (map['income_amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String? ?? 'USD',
      periodStartMs: map['period_start_ms']! as int,
      periodEndMs: map['period_end_ms']! as int,
      accountId: map['account_id'] as String?,
      createdAtMs: map['created_at']! as int,
      suggestion: AiRoleSuggestion(
        needsAmount: (map['needs_amount'] as num).toDouble(),
        wantsAmount: (map['wants_amount'] as num).toDouble(),
        goalsAmount: (map['goals_amount'] as num).toDouble(),
        needsReason: map['needs_reason']! as String,
        wantsReason: map['wants_reason']! as String,
        goalsReason: map['goals_reason']! as String,
        isFallback: ((map['is_fallback'] as int?) ?? 0) == 1,
      ),
    );
  }
}
