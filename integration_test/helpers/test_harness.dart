import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kakk/main.dart';
import 'package:kakk/models/account.dart';
import 'package:kakk/services/database_service.dart';
import 'package:kakk/services/seeding_service.dart';

/// Boots sqflite FFI, in-memory DB, and SharedPreferences for integration tests.
Future<void> bootstrapIntegrationTest({
  bool showOnboarding = false,
  bool firstLaunch = false,
  String? userName,
}) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await DatabaseService.resetForTesting();
  final db = DatabaseService();
  await db.openInMemoryForTesting();

  SharedPreferences.setMockInitialValues({
    'first_launch': firstLaunch,
    'show_onboarding': showOnboarding,
    if (userName != null) 'user_display_name': userName,
    if (!firstLaunch) 'default_currency': 'USD',
  });

  if (firstLaunch) {
    await SeedingService(db).seedDefaultData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    await prefs.setBool('show_onboarding', true);
  } else {
    final categories = await db.getCategories();
    if (categories.isEmpty) {
      await SeedingService(db).seedDefaultData();
    }
  }
}

Future<void> pumpKakkApp(
  WidgetTester tester, {
  required bool showOnboarding,
}) async {
  await tester.pumpWidget(
    ProviderScope(child: CashChewApp(showOnboarding: showOnboarding)),
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> skipOnboardingIntro(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text("Let's Get Started"));
  await tester.pumpAndSettle();
}

Future<void> completeOnboardingSetup(
  WidgetTester tester, {
  String userName = 'Alex',
  String accountName = 'My Wallet',
}) async {
  await tester.enterText(find.byType(TextField).first, userName);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, accountName);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.tap(find.text('Start Using CashChew'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> goToTransactionsTab(WidgetTester tester) async {
  await tester.tap(find.text('Transactions'));
  await tester.pumpAndSettle();
}

Future<void> goToBudgetsTab(WidgetTester tester) async {
  await tester.tap(find.text('Budgets'));
  await tester.pumpAndSettle();
}

Future<void> openAddBudgetForm(WidgetTester tester) async {
  await goToBudgetsTab(tester);

  if (find.text('New Budget').evaluate().isEmpty) {
    if (find.byKey(const Key('fab_add_budget')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('fab_add_budget')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  if (find.text('New Budget').evaluate().isEmpty) {
    final emptyCta = find.text('Create Budget');
    if (emptyCta.evaluate().isNotEmpty) {
      await tester.tap(emptyCta.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  expect(find.text('New Budget'), findsOneWidget);
}

Future<void> openAddTransactionForm(WidgetTester tester) async {
  await goToTransactionsTab(tester);

  if (find.byKey(const Key('transaction_category_picker')).evaluate().isEmpty) {
    await tester.tap(find.byKey(const Key('fab_add_transaction')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  if (find.byKey(const Key('transaction_category_picker')).evaluate().isEmpty) {
    final emptyListCta = find.widgetWithText(FilledButton, 'Add Transaction');
    if (emptyListCta.evaluate().isNotEmpty) {
      await tester.tap(emptyListCta);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  expect(find.byKey(const Key('transaction_category_picker')), findsOneWidget);
}

Future<void> fillAndSaveExpenseTransaction(
  WidgetTester tester, {
  required String title,
  required String amount,
  String categoryName = 'Food & Dining',
}) async {
  await tester.tap(find.byKey(const Key('transaction_category_picker')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(categoryName).last);
  await tester.pumpAndSettle();

  await tester.tap(find.textContaining('\$').first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, amount);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Title',
    ),
    title,
  );
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.widgetWithText(ElevatedButton, 'Add Transaction'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Add Transaction'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> seedOnboardedAccount() async {
  final db = DatabaseService();
  final now = DateTime.now().millisecondsSinceEpoch;
  await db.insertAccount(
    Account(
      id: 'e2e-account',
      name: 'E2E Cash',
      balance: 500,
      currency: 'USD',
      createdAt: now,
      updatedAt: now,
    ),
  );
}
