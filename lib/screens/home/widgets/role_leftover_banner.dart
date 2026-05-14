import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/budget_provider.dart';
import '../../roles/role_rollover_screen.dart';

/// Tap to open [RoleRolloverScreen] when expired role budgets still have cash left.
class RoleLeftoverBanner extends ConsumerWidget {
  const RoleLeftoverBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(expiredRoleRolloverCandidatesProvider);
    if (candidates.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings_outlined,
              color: Colors.teal.shade800,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.roleLeftoverBannerTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.roleLeftoverBannerSubtitle(candidates.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const RoleRolloverScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(l10n.roleLeftoverBannerAction),
          ),
        ],
      ),
    );
  }
}
