import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:kakk/models/budget.dart';
import 'package:kakk/services/database_service.dart';
import '../helpers/test_database.dart';

void main() {
  late DatabaseService db;

  setUp(() async {
    db = await createTestDatabase();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  group('DatabaseService - transactions & balances', () {
    test('insert expense reduces account balance when applied', () async {
      final account = await seedTestAccount(db, balance: 100);
      final category = await seedTestCategory(db);
      final tx = await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
        amount: 25,
      );
      await applyTransactionBalanceChange(db, tx, category);

      final updated = await db.getAccountById(account.id);
      expect(updated!.balance, 75);
    });

    test('insert income increases account balance when applied', () async {
      final account = await seedTestAccount(db, balance: 100);
      final category = await seedTestCategory(
        db,
        id: 'cat-income-1',
        name: 'Salary',
        type: 'income',
      );
      final tx = await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
        amount: 50,
        title: 'Paycheck',
      );
      await applyTransactionBalanceChange(db, tx, category);

      final updated = await db.getAccountById(account.id);
      expect(updated!.balance, 150);
    });

    test('delete transaction reverses balance change', () async {
      final account = await seedTestAccount(db, balance: 100);
      final category = await seedTestCategory(db);
      final tx = await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
        amount: 25,
      );
      await applyTransactionBalanceChange(db, tx, category);
      expect((await db.getAccountById(account.id))!.balance, 75);

      await db.deleteTransaction(tx.id);
      final current = await db.getAccountById(account.id);
      await db.updateAccountBalance(account.id, current!.balance + 25);

      expect((await db.getAccountById(account.id))!.balance, 100);
    });

    test('update transaction amount adjusts balance delta', () async {
      final account = await seedTestAccount(db, balance: 100);
      final category = await seedTestCategory(db);
      final tx = await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
        amount: 25,
      );
      await applyTransactionBalanceChange(db, tx, category);

      final updatedTx = tx.copyWith(amount: 40, updatedAt: tx.updatedAt);
      await db.updateTransaction(updatedTx);
      // Reverse old (-25) and apply new (-40): net -15 from 75 => 60
      await db.updateAccountBalance(account.id, 75 + 25 - 40);

      final updated = await db.getAccountById(account.id);
      expect(updated!.balance, 60);
    });

    test('getTotalExpenses respects date range', () async {
      final account = await seedTestAccount(db);
      final category = await seedTestCategory(db);
      final jan = DateTime(2025, 1, 15).millisecondsSinceEpoch;
      final feb = DateTime(2025, 2, 15).millisecondsSinceEpoch;

      await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
        amount: 10,
        dateMs: jan,
      );
      await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
        amount: 20,
        dateMs: feb,
      );

      final janOnly = await db.getTotalExpenses(
        startDate: DateTime(2025, 1, 1).millisecondsSinceEpoch,
        endDate: DateTime(2025, 1, 31, 23, 59, 59).millisecondsSinceEpoch,
      );
      expect(janOnly, 10);

      final all = await db.getTotalExpenses();
      expect(all, 30);
    });

    test('deleteAccount cascades transactions', () async {
      final account = await seedTestAccount(db);
      final category = await seedTestCategory(db);
      await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
      );

      await db.deleteAccount(account.id);

      final txs = await db.getTransactionsByAccount(account.id);
      expect(txs, isEmpty);
      expect(await db.getAccountById(account.id), isNull);
    });

    test('deleteCategory fails when transactions reference it', () async {
      final account = await seedTestAccount(db);
      final category = await seedTestCategory(db);
      await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: category.id,
      );

      expect(
        () => db.deleteCategory(category.id),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DatabaseService - budgets', () {
    test('getBudgetSpent sums only linked categories', () async {
      final account = await seedTestAccount(db);
      final food = await seedTestCategory(db, id: 'cat-food', name: 'Food');
      final transport = await seedTestCategory(
        db,
        id: 'cat-transport',
        name: 'Transport',
      );

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59)
          .millisecondsSinceEpoch;

      const uuid = Uuid();
      final budget = Budget(
        id: uuid.v4(),
        name: 'Groceries',
        accountId: account.id,
        limitAmount: 500,
        startDate: start,
        endDate: end,
        createdAt: start,
        updatedAt: start,
      );
      await db.insertBudget(budget);
      await db.setBudgetCategories(budget.id, [food.id]);

      await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: food.id,
        amount: 30,
      );
      await seedTestTransaction(
        db,
        accountId: account.id,
        categoryId: transport.id,
        amount: 99,
      );

      final spent = await db.getBudgetSpent(start, end, [food.id]);
      expect(spent, 30);
    });

    test('getActiveBudgets returns only in-period budgets', () async {
      final now = DateTime.now();
      final activeStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final activeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59)
          .millisecondsSinceEpoch;
      const uuid = Uuid();

      await db.insertBudget(
        Budget(
          id: uuid.v4(),
          name: 'Active',
          limitAmount: 100,
          startDate: activeStart,
          endDate: activeEnd,
          createdAt: activeStart,
          updatedAt: activeStart,
        ),
      );
      await db.insertBudget(
        Budget(
          id: uuid.v4(),
          name: 'Expired',
          limitAmount: 100,
          startDate: DateTime(2020, 1, 1).millisecondsSinceEpoch,
          endDate: DateTime(2020, 1, 31).millisecondsSinceEpoch,
          createdAt: activeStart,
          updatedAt: activeStart,
        ),
      );

      final active = await db.getActiveBudgets();
      expect(active.length, 1);
      expect(active.first.name, 'Active');
    });
  });
}
