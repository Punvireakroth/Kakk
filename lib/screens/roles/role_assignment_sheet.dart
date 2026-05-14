import 'package:flutter/material.dart';

import '../../utils/currency_formatter.dart';
import 'role_assignment_screen.dart';

/// Result of the optional role split before saving income; `null` if the sheet was dismissed.
enum RoleAssignmentOutcome { skip, completedSplit }

/// Prompt to split income across Needs / Wants / Goals before the transaction is saved.
class RoleAssignmentSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = CurrencyFormatter.format(
      incomeAmount,
      currency: currencyCode,
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
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => RoleAssignmentScreen(
                    incomeAmount: incomeAmount,
                    currencyCode: currencyCode,
                    accountId: accountId,
                    periodStartMs: periodStartMs,
                    periodEndMs: periodEndMs,
                  ),
                ),
              );
              if (!context.mounted) return;
              if (saved == true) {
                Navigator.pop(context, RoleAssignmentOutcome.completedSplit);
              }
            },
            child: const Text('Split it'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                Navigator.pop(context, RoleAssignmentOutcome.skip),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
