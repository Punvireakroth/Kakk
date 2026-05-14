import 'package:flutter/foundation.dart';

/// AI-proposed split of income across Needs / Wants / Goals, or a 50/30/20 fallback.
@immutable
class AiRoleSuggestion {
  const AiRoleSuggestion({
    required this.needsAmount,
    required this.wantsAmount,
    required this.goalsAmount,
    required this.needsReason,
    required this.wantsReason,
    required this.goalsReason,
    required this.isFallback,
  });

  final double needsAmount;
  final double wantsAmount;
  final double goalsAmount;
  final String needsReason;
  final String wantsReason;
  final String goalsReason;

  /// True when the API key was missing, history was too thin, the request failed,
  /// or the model returned unusable JSON — amounts use the 50/30/20 rule.
  final bool isFallback;
}
