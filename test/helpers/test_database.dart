import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:uuid/uuid.dart';

import 'package:kakk/models/account.dart';
import 'package:kakk/models/category.dart';
import 'package:kakk/models/transaction.dart' as app_models;
import 'package:kakk/services/database_service.dart';
import 'package:kakk/services/seeding_service.dart';

/// Initializes sqflite FFI and opens a fresh in-memory [DatabaseService].
Future<DatabaseService> createTestDatabase({bool seedCategories = true}) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await DatabaseService.resetForTesting();
  final db = DatabaseService();
  await db.openInMemoryForTesting();

  if (seedCategories) {
    await SeedingService(db).seedDefaultData();
  }

  return db;
}

Future<Account> seedTestAccount(
  DatabaseService db, {
  String id = 'acct-1',
  String name = 'Test Cash',
  double balance = 100,
  String currency = 'USD',
}) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final account = Account(
    id: id,
    name: name,
    balance: balance,
    currency: currency,
    createdAt: now,
    updatedAt: now,
  );
  await db.insertAccount(account);
  return account;
}

Future<Category> seedTestCategory(
  DatabaseService db, {
  String id = 'cat-expense-1',
  String name = 'Test Food',
  String type = 'expense',
}) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final category = Category(
    id: id,
    name: name,
    iconName: 'restaurant',
    color: 0xFFFF9800,
    type: type,
    createdAt: now,
  );
  await db.insertCategory(category);
  return category;
}

Future<app_models.Transaction> seedTestTransaction(
  DatabaseService db, {
  required String accountId,
  required String categoryId,
  String? id,
  double amount = 25,
  String title = 'Test expense',
  int? dateMs,
}) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final tx = app_models.Transaction(
    id: id ?? const Uuid().v4(),
    accountId: accountId,
    categoryId: categoryId,
    amount: amount,
    title: title,
    date: dateMs ?? now,
    createdAt: now,
    updatedAt: now,
  );
  await db.insertTransaction(tx);
  return tx;
}

/// Mirrors [TransactionNotifier.addTransaction] balance logic for DB-level tests.
Future<void> applyTransactionBalanceChange(
  DatabaseService db,
  app_models.Transaction transaction,
  Category category,
) async {
  final account = await db.getAccountById(transaction.accountId);
  if (account == null) {
    throw StateError('Account not found');
  }
  final delta = category.isIncome ? transaction.amount : -transaction.amount;
  await db.updateAccountBalance(account.id, account.balance + delta);
}
