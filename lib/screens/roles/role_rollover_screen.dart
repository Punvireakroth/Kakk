import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/budget_role_type.dart';
import '../../utils/currency_formatter.dart';

/// Call after [BudgetNotifier.loadBudgets] when [HomeScreen] loads.
Future<void> checkAndPromptRollover(
  BuildContext context,
  WidgetRef ref,
) async {
  final notifier = ref.read(budgetProvider.notifier);
  if (!notifier.checkRolloverNeeded()) return;
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const RoleRolloverScreen(),
    ),
  );
}

class RoleRolloverScreen extends ConsumerStatefulWidget {
  const RoleRolloverScreen({super.key});

  @override
  ConsumerState<RoleRolloverScreen> createState() => _RoleRolloverScreenState();
}

class _RoleRolloverScreenState extends ConsumerState<RoleRolloverScreen> {
  final Map<String, RoleRolloverDestination> _choices = {};

  String _currencyFor(BudgetWithSpent b) {
    final aid = b.budget.accountId;
    if (aid == null) {
      final accounts = ref.read(accountProvider).accounts;
      return accounts.isNotEmpty ? accounts.first.currency : 'USD';
    }
    return ref.read(accountProvider.notifier).getAccountById(aid)?.currency ??
        'USD';
  }

  String _roleLabel(BudgetRoleType role, AppLocalizations l10n) {
    return switch (role) {
      BudgetRoleType.needs => l10n.needs,
      BudgetRoleType.wants => l10n.wants,
      BudgetRoleType.goals => l10n.goals,
      _ => role.displayName,
    };
  }

  RoleRolloverDestination _choiceFor(BudgetWithSpent b) {
    final role = b.budget.roleType!;
    if (role == BudgetRoleType.goals ||
        role == BudgetRoleType.futureMe ||
        role == BudgetRoleType.custom) {
      return RoleRolloverDestination.carryForward;
    }
    return _choices[b.budget.id] ?? RoleRolloverDestination.carryForward;
  }

  void _setChoice(String budgetId, RoleRolloverDestination v) {
    setState(() => _choices[budgetId] = v);
  }

  Future<void> _confirm() async {
    final candidates = ref.read(expiredRoleRolloverCandidatesProvider);
    final l10n = AppLocalizations.of(context)!;
    if (candidates.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final map = <String, RoleRolloverDestination>{};
    for (final b in candidates) {
      map[b.budget.id] = _choiceFor(b);
    }

    final ok =
        await ref.read(budgetProvider.notifier).applyRoleRollovers(map);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.roleRolloverSuccess)),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(budgetProvider).error ?? l10n.retry;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final candidates = ref.watch(expiredRoleRolloverCandidatesProvider);
    final loading = ref.watch(budgetProvider).isLoading;

    if (candidates.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return Scaffold(
        appBar: AppBar(title: Text(l10n.roleRolloverTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roleRolloverTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.roleRolloverSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ...candidates.map((b) {
                  final role = b.budget.roleType!;
                  final currency = _currencyFor(b);
                  final leftover =
                      CurrencyFormatter.format(b.remaining, currency: currency);
                  final canMoveGoals = role == BudgetRoleType.needs ||
                      role == BudgetRoleType.wants;
                  final sel = _choiceFor(b);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(role.icon, color: role.color, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _roleLabel(role, l10n),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.roleRolloverLeftover(leftover),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (canMoveGoals) ...[
                              const SizedBox(height: 12),
                              SegmentedButton<RoleRolloverDestination>(
                                segments: [
                                  ButtonSegment(
                                    value: RoleRolloverDestination.moveToGoals,
                                    label: Text(l10n.moveToGoalsLabel),
                                  ),
                                  ButtonSegment(
                                    value:
                                        RoleRolloverDestination.carryForward,
                                    label: Text(l10n.carryForwardLabel),
                                  ),
                                ],
                                selected: {sel},
                                onSelectionChanged: (s) {
                                  _setChoice(b.budget.id, s.first);
                                },
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.carryForwardOnlyHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: loading ? null : _confirm,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.roleRolloverConfirm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
