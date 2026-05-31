import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Journey 2: create budget and record linked expense', (
    tester,
  ) async {
    await bootstrapIntegrationTest(firstLaunch: true, showOnboarding: true);
    await pumpKakkApp(tester, showOnboarding: true);
    await skipOnboardingIntro(tester);
    await completeOnboardingSetup(
      tester,
      userName: 'Tester',
      accountName: 'E2E Cash',
    );

    await openAddTransactionForm(tester);
    await fillAndSaveExpenseTransaction(
      tester,
      title: 'Groceries run',
      amount: '40',
    );

    await openAddBudgetForm(tester);

    await tester.enterText(
      find.byKey(const Key('budget_name_field')),
      'E2E Groceries',
    );
    await tester.enterText(find.byKey(const Key('budget_limit_field')), '200');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food & Dining').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('budget_submit_button')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('budget_submit_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('New Budget'), findsNothing);
    expect(find.text('E2E Groceries'), findsOneWidget);
    expect(find.textContaining('20%'), findsWidgets);
  });
}
