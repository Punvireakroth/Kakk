import 'package:flutter/widgets.dart';

import 'package:chashew/services/database_service.dart';
import 'package:chashew/services/seeding_service.dart';

/// Seeds expense-only transactions across the **same ~3 calendar months**
/// [SpendingSummaryService] uses, so Gemini sees richer Needs/Wants/Goals averages.
///
/// **Simulator / device:** prefer **More → Developer → Seed AI role expense history**
/// (debug builds), since this CLI uses the host DB path only when sqflite matches.
///
/// ```sh
/// dart run tool/seed_ai_role_history.dart
/// dart run tool/seed_ai_role_history.dart --replace
/// ```
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final replace = args.contains('--replace');
  await SeedingService(DatabaseService()).seedAiRoleExpenseHistory(
    replaceExisting: replace,
  );
}
