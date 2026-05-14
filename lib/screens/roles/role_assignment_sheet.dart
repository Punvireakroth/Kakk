import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ai_role_suggestion.dart';
import '../../services/ai_role_service.dart';
import '../../services/spending_summary_service.dart';
import '../../utils/currency_formatter.dart';
import 'ai_role_suggestion_screen.dart';
import 'role_assignment_screen.dart';

/// Result of the optional role split before saving income; `null` if the sheet was dismissed.
enum RoleAssignmentOutcome { skip, completedSplit }

/// Prompt to split income across Needs / Wants / Goals before the transaction is saved.
class RoleAssignmentSheet extends ConsumerStatefulWidget {
  final double incomeAmount;
  final String currencyCode;
  final String? accountId;
  final int periodStartMs;
  final int periodEndMs;

  const RoleAssignmentSheet({
    super.key,
    required this.incomeAmount,
    required this.currencyCode,
    required this.accountId,
    required this.periodStartMs,
    required this.periodEndMs,
  });

  @override
  ConsumerState<RoleAssignmentSheet> createState() =>
      _RoleAssignmentSheetState();
}

class _RoleAssignmentSheetState extends ConsumerState<RoleAssignmentSheet> {
  bool _fetchingSuggestion = false;

  Future<void> _openAssignment(BuildContext context) async {
    setState(() => _fetchingSuggestion = true);
    AiRoleSuggestion? suggestion;
    try {
      final summary = await SpendingSummaryService.build(
        ref,
        incomeAmount: widget.incomeAmount,
        currencyCode: widget.currencyCode,
      );
      suggestion = await AiRoleService.suggest(summary);
    } catch (_) {
      suggestion = null;
    } finally {
      if (mounted) setState(() => _fetchingSuggestion = false);
    }

    if (!context.mounted) return;

    final s = suggestion;
    // Always show the AI-assistant layout when loading succeeded; `isFallback`
    // only changes footer copy and whether amounts came from Gemini vs 50/30/20.
    final useAiUi = s != null;

    final Widget routeChild = useAiUi
        ? AiRoleSuggestionScreen(
            suggestion: s,
            incomeAmount: widget.incomeAmount,
            currencyCode: widget.currencyCode,
            accountId: widget.accountId,
            periodStartMs: widget.periodStartMs,
            periodEndMs: widget.periodEndMs,
          )
        : RoleAssignmentScreen(
            incomeAmount: widget.incomeAmount,
            currencyCode: widget.currencyCode,
            accountId: widget.accountId,
            periodStartMs: widget.periodStartMs,
            periodEndMs: widget.periodEndMs,
          );

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => routeChild),
    );
    if (!context.mounted) return;
    if (saved == true) {
      Navigator.pop(context, RoleAssignmentOutcome.completedSplit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final formatted = CurrencyFormatter.format(
      widget.incomeAmount,
      currency: widget.currencyCode,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$formatted: split it across Needs, Wants, and Goals?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional. Skip if you prefer.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_fetchingSuggestion) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.roleAssignmentFetchingSuggestions,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _fetchingSuggestion
                ? null
                : () => _openAssignment(context),
            child: const Text('Split it'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _fetchingSuggestion
                ? null
                : () =>
                    Navigator.pop(context, RoleAssignmentOutcome.skip),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
