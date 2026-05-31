import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Journey 1: onboarding then first expense transaction', (
    tester,
  ) async {
    await bootstrapIntegrationTest(firstLaunch: true, showOnboarding: true);
    await pumpKakkApp(tester, showOnboarding: true);

    await skipOnboardingIntro(tester);
    await completeOnboardingSetup(tester);

    expect(find.text('Transactions'), findsOneWidget);

    await openAddTransactionForm(tester);
    await fillAndSaveExpenseTransaction(
      tester,
      title: 'Lunch',
      amount: '25',
    );

    expect(find.text('Lunch'), findsOneWidget);
  });
}
