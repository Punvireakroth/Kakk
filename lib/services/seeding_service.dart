import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart' as app_models;
import '../utils/budget_role_type.dart';
import '../utils/budget_rule_categories.dart';

/// Service to seed default data into the database
class SeedingService {
  final DatabaseService _db;
  final Uuid _uuid = const Uuid();

  /// Tag stored in [Transaction.notes] so demo rows can be removed safely.
  static const String demoTransactionMarker = '[[cashchew-demo-seed]]';

  /// Tag stored in [Transaction.notes] so AI-history demo rows can be removed safely.
  static const String aiRoleHistorySeedMarker = '[[cashchew-ai-role-history-seed]]';

  /// Budget ids for [seedDemoFinancialData] start with this prefix (names stay realistic).
  static const String seedBudgetIdPrefix = 'ccseed_b_';

  /// Budget ids for [seedExpiredRoleBudgetsForRolloverDemo] (cleanup via [removeRoleRolloverDemoSeed]).
  static const String seedRoleRolloverBudgetIdPrefix = 'ccseed_rollover_rb_';

  /// Transaction marker for rollover demo rows (removed with demo budgets cleanup).
  static const String rolloverDemoTransactionMarker = '[[cashchew-rollover-demo]]';

  /// Legacy seeded budgets used this name prefix; still removed when replacing seed.
  static const String legacyDemoBudgetNamePrefix = '[Demo] ';

  SeedingService(this._db);

  /// Seed all default data
  Future<void> seedDefaultData() async {
    try {
      print('Starting to seed default data...');
      await _seedCategories();
      print('Default data seeded successfully!');
    } catch (e) {
      print('Error seeding default data: $e');
      rethrow;
    }
  }

  /// Default categories for first launch and for filling gaps on older DBs.
  List<Category> _defaultCategoriesTemplate(int createdAtMs) {
    return [
      Category(
        id: _uuid.v4(),
        name: 'Food & Dining',
        iconName: 'restaurant',
        color: Colors.orange.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Transportation',
        iconName: 'directions_car',
        color: Colors.blue.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Shopping',
        iconName: 'shopping_bag',
        color: Colors.purple.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Entertainment',
        iconName: 'movie',
        color: Colors.pink.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Bills & Utilities',
        iconName: 'receipt_long',
        color: Colors.red.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Healthcare',
        iconName: 'medical_services',
        color: Colors.teal.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Education',
        iconName: 'school',
        color: Colors.indigo.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Travel',
        iconName: 'flight',
        color: Colors.cyan.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Housing',
        iconName: 'home',
        color: Colors.brown.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Personal Care',
        iconName: 'spa',
        color: Colors.pinkAccent.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Fitness & Sports',
        iconName: 'fitness_center',
        color: Colors.deepOrange.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Other Expenses',
        iconName: 'more_horiz',
        color: Colors.grey.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Savings Transfer',
        iconName: 'savings',
        color: Colors.green.shade700.value,
        type: 'expense',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Salary',
        iconName: 'work',
        color: Colors.green.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Business',
        iconName: 'business_center',
        color: Colors.lightGreen.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Investments',
        iconName: 'trending_up',
        color: Colors.teal.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Freelance',
        iconName: 'laptop_mac',
        color: Colors.blue.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Gifts',
        iconName: 'card_giftcard',
        color: Colors.pink.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Rental Income',
        iconName: 'apartment',
        color: Colors.amber.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Refunds',
        iconName: 'money_off',
        color: Colors.lightBlue.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Other Income',
        iconName: 'more_horiz',
        color: Colors.grey.value,
        type: 'income',
        createdAt: createdAtMs,
      ),
    ];
  }

  /// Seed default expense and income categories. Inserts the full template when
  /// the table is empty; otherwise inserts any **missing** defaults by name
  /// (e.g. after app updates that add new canonical categories).
  Future<void> _seedCategories() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final template = _defaultCategoriesTemplate(now);
    final existingCategories = await _db.getCategories();

    if (existingCategories.isEmpty) {
      for (final category in template) {
        await _db.insertCategory(category);
      }
      print(
        '${template.where((c) => c.isExpense).length} expense categories seeded',
      );
      print(
        '${template.where((c) => c.isIncome).length} income categories seeded',
      );
      print('Total ${template.length} categories created');
      return;
    }

    var added = 0;
    for (final category in template) {
      if (!await _db.categoryExistsByName(category.name)) {
        await _db.insertCategory(category);
        added++;
      }
    }
    if (added > 0) {
      print('Added $added missing default categories (legacy DB merge)');
    } else {
      print('Categories already exist, skipping seeding');
    }
  }

  /// Whether sample seed budgets or legacy `[Demo]` seed budgets exist.
  Future<bool> hasDemoFinancialSeed() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM budgets WHERE id LIKE ? OR name LIKE ?',
      ['$seedBudgetIdPrefix%', '$legacyDemoBudgetNamePrefix%'],
    );
    final n = rows.first['c'];
    return (n is int && n > 0) || (n is num && n > 0);
  }

  /// Removes seed transactions (notes marker) and seed budgets (id or legacy name).
  Future<void> removeDemoFinancialSeed() async {
    final db = await _db.database;
    await db.delete(
      'transactions',
      where: 'notes LIKE ?',
      whereArgs: ['%$demoTransactionMarker%'],
    );
    await db.delete(
      'budgets',
      where: 'id LIKE ? OR name LIKE ?',
      whereArgs: ['$seedBudgetIdPrefix%', '$legacyDemoBudgetNamePrefix%'],
    );
    print('Demo financial seed removed');
  }

  Future<bool> hasRoleRolloverDemoSeed() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM budgets WHERE id LIKE ?',
      ['$seedRoleRolloverBudgetIdPrefix%'],
    );
    final n = rows.first['c'];
    return (n is int && n > 0) || (n is num && n > 0);
  }

  /// Deletes rollover demo budgets and their marker transactions.
  Future<void> removeRoleRolloverDemoSeed() async {
    final db = await _db.database;
    await db.delete(
      'transactions',
      where: 'notes LIKE ?',
      whereArgs: ['%$rolloverDemoTransactionMarker%'],
    );
    await db.delete(
      'budgets',
      where: 'id LIKE ?',
      whereArgs: ['$seedRoleRolloverBudgetIdPrefix%'],
    );
    print('Rollover demo seed removed');
  }

  /// Inserts **expired** Needs/Wants/Goals role budgets for the **previous calendar month**
  /// with partial spending so each has **remaining > 0** → home shows rollover flow.
  ///
  /// Safe to run beside other data; ids use [seedRoleRolloverBudgetIdPrefix].
  Future<void> seedExpiredRoleBudgetsForRolloverDemo({
    bool replaceExisting = false,
  }) async {
    await seedDefaultData();

    if (replaceExisting) {
      await removeRoleRolloverDemoSeed();
    } else if (await hasRoleRolloverDemoSeed()) {
      throw StateError(
        'Rollover demo budgets already exist. Call with replaceExisting: true to refresh.',
      );
    }

    final categories = await _db.getCategories();
    final byName = {for (final c in categories) c.name: c.id};
    const required = [
      'Salary',
      'Food & Dining',
      'Shopping',
      'Savings Transfer',
    ];
    for (final name in required) {
      if (!byName.containsKey(name)) {
        throw StateError('Missing category "$name". Run default seed first.');
      }
    }

    final expenseCategories = await _db.getCategories(type: 'expense');
    final categorized =
        BudgetRuleCategorizer.categorizeExpenses(expenseCategories);
    final needsIds =
        categorized[BudgetRuleType.needs]!.map((c) => c.id).toList();
    final wantsIds =
        categorized[BudgetRuleType.wants]!.map((c) => c.id).toList();
    final savingsIds =
        categorized[BudgetRuleType.savings]!.map((c) => c.id).toList();
    if (needsIds.isEmpty || wantsIds.isEmpty || savingsIds.isEmpty) {
      throw StateError(
        'Needs/Wants/Savings category buckets empty — check expense categories.',
      );
    }

    final clock = DateTime.now();
    final nowMs = clock.millisecondsSinceEpoch;
    var accounts = await _db.getAccounts();
    late final String accountId;
    if (accounts.isEmpty) {
      accountId = _uuid.v4();
      await _db.insertAccount(
        Account(
          id: accountId,
          name: 'Primary checking',
          balance: 0,
          currency: 'USD',
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );
    } else {
      accountId = accounts.first.id;
    }

    final prevMonthStart = DateTime(clock.year, clock.month - 1, 1);
    final prevMonthEnd =
        DateTime(clock.year, clock.month, 0, 23, 59, 59, 999);
    final startMs = prevMonthStart.millisecondsSinceEpoch;
    final endMs = prevMonthEnd.millisecondsSinceEpoch;
    final periodLabel = DateFormat('MMM yyyy').format(prevMonthStart);

    Future<void> addRoleBudget({
      required BudgetRoleType role,
      required double limitAmount,
      required List<String> categoryIds,
    }) async {
      final id = '$seedRoleRolloverBudgetIdPrefix${role.storageValue}';
      final budget = Budget(
        id: id,
        name: '${role.displayName} · $periodLabel · rollover demo',
        accountId: null,
        limitAmount: limitAmount,
        startDate: startMs,
        endDate: endMs,
        roleType: role,
        createdAt: nowMs,
        updatedAt: nowMs,
      );
      await _db.insertBudget(budget);
      await _db.setBudgetCategories(budget.id, categoryIds);
    }

    const needsLimit = 2000.0;
    const wantsLimit = 900.0;
    const goalsLimit = 400.0;

    await addRoleBudget(
      role: BudgetRoleType.needs,
      limitAmount: needsLimit,
      categoryIds: needsIds,
    );
    await addRoleBudget(
      role: BudgetRoleType.wants,
      limitAmount: wantsLimit,
      categoryIds: wantsIds,
    );
    await addRoleBudget(
      role: BudgetRoleType.goals,
      limitAmount: goalsLimit,
      categoryIds: savingsIds,
    );

    Future<void> demoTx(
      String title,
      String categoryName,
      double amount,
      DateTime when,
    ) async {
      await _db.insertTransaction(
        app_models.Transaction(
          id: _uuid.v4(),
          accountId: accountId,
          categoryId: byName[categoryName]!,
          amount: amount,
          title: title,
          notes: rolloverDemoTransactionMarker,
          date: when.millisecondsSinceEpoch,
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );
    }

    await demoTx(
      '[Demo] Paycheck',
      'Salary',
      6000,
      DateTime(prevMonthStart.year, prevMonthStart.month, 5),
    );
    await demoTx(
      '[Demo] Groceries',
      'Food & Dining',
      350,
      DateTime(prevMonthStart.year, prevMonthStart.month, 8),
    );
    await demoTx(
      '[Demo] Online order',
      'Shopping',
      120,
      DateTime(prevMonthStart.year, prevMonthStart.month, 14),
    );
    await demoTx(
      '[Demo] Savings jar',
      'Savings Transfer',
      60,
      DateTime(prevMonthStart.year, prevMonthStart.month, 20),
    );

    await _recalculateAccountBalance(accountId);
    print(
      'Rollover demo: expired role trio $periodLabel (needs/wants/goals leftover)',
    );
  }

  /// Seeds realistic accounts, budgets, and transactions:
  /// - **50/30/20** style buckets (needs / wants / savings) for April (closed) and May (active).
  /// - **Spend ≤80% of net** envelope (non–savings spending vs 80% of monthly net).
  /// - **Past period**: February wants bucket over limit; mixed history Feb–May 2026.
  ///
  /// Uses [demoTransactionMarker] on transactions and [seedBudgetIdPrefix] on budget ids for cleanup.
  /// Ensures categories exist via [seedDefaultData] first.
  ///
  /// [replaceExisting]: if true, deletes prior demo seed rows before inserting.
  Future<void> seedDemoFinancialData({bool replaceExisting = false}) async {
    await seedDefaultData();

    if (replaceExisting) {
      await removeDemoFinancialSeed();
    } else if (await hasDemoFinancialSeed()) {
      throw StateError(
        'Demo financial data already exists. Call with replaceExisting: true to refresh.',
      );
    }

    final categories = await _db.getCategories();
    final byName = {for (final c in categories) c.name: c.id};
    const required = [
      'Salary',
      'Housing',
      'Bills & Utilities',
      'Transportation',
      'Healthcare',
      'Food & Dining',
      'Shopping',
      'Entertainment',
      'Travel',
      'Personal Care',
      'Fitness & Sports',
      'Savings Transfer',
    ];
    for (final name in required) {
      if (!byName.containsKey(name)) {
        throw StateError('Missing category "$name". Reset categories or reinstall seed.');
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    var accounts = await _db.getAccounts();
    late final String accountId;
    if (accounts.isEmpty) {
      accountId = _uuid.v4();
      await _db.insertAccount(
        Account(
          id: accountId,
          name: 'Primary checking',
          balance: 0,
          currency: 'USD',
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      accountId = accounts.first.id;
    }

    final c = byName;

    // ---- Budgets (periods use 2026 calendar; aligns with “today” in dev) ----
    Future<void> addBudget(
      Budget budget,
      List<String> categoryIds,
    ) async {
      await _db.insertBudget(budget);
      await _db.setBudgetCategories(budget.id, categoryIds);
    }

    // February: small “wants only” cap — heavily exceeded (past / over)
    final febStart = DateTime(2026, 2, 1).millisecondsSinceEpoch;
    final febEnd = DateTime(2026, 2, 28, 23, 59, 59, 999).millisecondsSinceEpoch;
    const febWantsId = '${seedBudgetIdPrefix}feb_discretionary';
    await addBudget(
      Budget(
        id: febWantsId,
        name: 'Discretionary · February',
        accountId: null,
        limitAmount: 1000,
        startDate: febStart,
        endDate: febEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Shopping']!,
        c['Entertainment']!,
        c['Travel']!,
        c['Personal Care']!,
        c['Fitness & Sports']!,
      ],
    );

    // April: full 50/30/20 + 80% spend cap (all closed)
    final aprStart = DateTime(2026, 4, 1).millisecondsSinceEpoch;
    final aprEnd = DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch;

    const aprNeedsId = '${seedBudgetIdPrefix}apr_essentials';
    const aprWantsId = '${seedBudgetIdPrefix}apr_lifestyle';
    const aprSaveId = '${seedBudgetIdPrefix}apr_savings';
    const apr80Id = '${seedBudgetIdPrefix}apr_spend_cap';

    const netMonthly = 5000.0;
    final cap80 = (netMonthly * 0.8).roundToDouble();

    await addBudget(
      Budget(
        id: aprNeedsId,
        name: 'Household & essentials · April',
        accountId: null,
        limitAmount: netMonthly * 0.5,
        startDate: aprStart,
        endDate: aprEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Housing']!,
        c['Bills & Utilities']!,
        c['Transportation']!,
        c['Healthcare']!,
        c['Food & Dining']!,
      ],
    );
    await addBudget(
      Budget(
        id: aprWantsId,
        name: 'Lifestyle & fun · April',
        accountId: null,
        limitAmount: netMonthly * 0.3,
        startDate: aprStart,
        endDate: aprEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Shopping']!,
        c['Entertainment']!,
        c['Travel']!,
        c['Personal Care']!,
        c['Fitness & Sports']!,
      ],
    );
    await addBudget(
      Budget(
        id: aprSaveId,
        name: 'Savings transfers · April',
        accountId: null,
        limitAmount: netMonthly * 0.2,
        startDate: aprStart,
        endDate: aprEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [c['Savings Transfer']!],
    );
    await addBudget(
      Budget(
        id: apr80Id,
        name: 'Variable spending cap · April',
        accountId: null,
        limitAmount: cap80,
        startDate: aprStart,
        endDate: aprEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Housing']!,
        c['Bills & Utilities']!,
        c['Transportation']!,
        c['Healthcare']!,
        c['Food & Dining']!,
        c['Shopping']!,
        c['Entertainment']!,
        c['Travel']!,
        c['Personal Care']!,
        c['Fitness & Sports']!,
      ],
    );

    // May: same structure, active month (partial spend through early May)
    final mayStart = DateTime(2026, 5, 1).millisecondsSinceEpoch;
    final mayEnd = DateTime(2026, 5, 31, 23, 59, 59, 999).millisecondsSinceEpoch;

    await addBudget(
      Budget(
        id: '${seedBudgetIdPrefix}may_essentials',
        name: 'Household & essentials · May',
        accountId: null,
        limitAmount: netMonthly * 0.5,
        startDate: mayStart,
        endDate: mayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Housing']!,
        c['Bills & Utilities']!,
        c['Transportation']!,
        c['Healthcare']!,
        c['Food & Dining']!,
      ],
    );
    await addBudget(
      Budget(
        id: '${seedBudgetIdPrefix}may_lifestyle',
        name: 'Lifestyle & fun · May',
        accountId: null,
        limitAmount: netMonthly * 0.3,
        startDate: mayStart,
        endDate: mayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Shopping']!,
        c['Entertainment']!,
        c['Travel']!,
        c['Personal Care']!,
        c['Fitness & Sports']!,
      ],
    );
    await addBudget(
      Budget(
        id: '${seedBudgetIdPrefix}may_savings',
        name: 'Savings transfers · May',
        accountId: null,
        limitAmount: netMonthly * 0.2,
        startDate: mayStart,
        endDate: mayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [c['Savings Transfer']!],
    );
    await addBudget(
      Budget(
        id: '${seedBudgetIdPrefix}may_spend_cap',
        name: 'Variable spending cap · May',
        accountId: null,
        limitAmount: cap80,
        startDate: mayStart,
        endDate: mayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      [
        c['Housing']!,
        c['Bills & Utilities']!,
        c['Transportation']!,
        c['Healthcare']!,
        c['Food & Dining']!,
        c['Shopping']!,
        c['Entertainment']!,
        c['Travel']!,
        c['Personal Care']!,
        c['Fitness & Sports']!,
      ],
    );

    Future<void> tx(
      String title,
      String categoryName,
      double amount,
      DateTime when,
    ) async {
      await _db.insertTransaction(
        app_models.Transaction(
          id: _uuid.v4(),
          accountId: accountId,
          categoryId: c[categoryName]!,
          amount: amount,
          title: title,
          notes: demoTransactionMarker,
          date: when.millisecondsSinceEpoch,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // ---- February: salary + needs + wants over Feb cap ----
    await tx('Paycheck — ACME Corp', 'Salary', 5000, DateTime(2026, 2, 1, 9));
    await tx('Apartment rent', 'Housing', 1200, DateTime(2026, 2, 1));
    await tx('Electric & water', 'Bills & Utilities', 220, DateTime(2026, 2, 3));
    await tx('Whole Foods', 'Food & Dining', 180, DateTime(2026, 2, 5));
    await tx('Metro monthly pass', 'Transportation', 120, DateTime(2026, 2, 6));
    await tx('CVS Pharmacy', 'Healthcare', 45, DateTime(2026, 2, 8));
    await tx('Winter clearance sale', 'Shopping', 420, DateTime(2026, 2, 10));
    await tx('Concert tickets', 'Entertainment', 280, DateTime(2026, 2, 14));
    await tx('Weekend getaway', 'Travel', 260, DateTime(2026, 2, 18));
    await tx('Spa day', 'Personal Care', 190, DateTime(2026, 2, 20));
    await tx('Gym annual renewal', 'Fitness & Sports', 220, DateTime(2026, 2, 22));
    await tx('High-yield savings', 'Savings Transfer', 200, DateTime(2026, 2, 25));

    // ---- March: steady month ----
    await tx('Paycheck — ACME Corp', 'Salary', 5000, DateTime(2026, 3, 1, 9));
    await tx('Apartment rent', 'Housing', 1200, DateTime(2026, 3, 1));
    await tx('Electric & water', 'Bills & Utilities', 210, DateTime(2026, 3, 2));
    await tx('Trader Joe’s', 'Food & Dining', 320, DateTime(2026, 3, 4));
    await tx('Shell Gas', 'Transportation', 160, DateTime(2026, 3, 6));
    await tx('Doctor co-pay', 'Healthcare', 60, DateTime(2026, 3, 9));
    await tx('Amazon', 'Shopping', 140, DateTime(2026, 3, 11));
    await tx('Netflix & Spotify', 'Entertainment', 45, DateTime(2026, 3, 12));
    await tx('Amtrak', 'Travel', 110, DateTime(2026, 3, 15));
    await tx('Haircut', 'Personal Care', 55, DateTime(2026, 3, 17));
    await tx('Yoga studio', 'Fitness & Sports', 35, DateTime(2026, 3, 19));
    await tx('Brokerage deposit', 'Savings Transfer', 600, DateTime(2026, 3, 28));

    // ---- April: needs 2480 + wants 1520 = 4000 (exactly 80% of 5000 net); wants slightly over 30% bucket ----
    await tx('Paycheck — ACME Corp', 'Salary', 5000, DateTime(2026, 4, 1, 9));
    await tx('Apartment rent', 'Housing', 1250, DateTime(2026, 4, 1));
    await tx('Utilities bundle', 'Bills & Utilities', 520, DateTime(2026, 4, 2));
    await tx('Groceries', 'Food & Dining', 340, DateTime(2026, 4, 4));
    await tx('Commuter rail', 'Transportation', 280, DateTime(2026, 4, 5));
    await tx('Annual physical', 'Healthcare', 90, DateTime(2026, 4, 7));
    await tx('Nordstrom', 'Shopping', 400, DateTime(2026, 4, 9));
    await tx('Best Buy', 'Shopping', 280, DateTime(2026, 4, 10));
    await tx('Theater tickets', 'Entertainment', 260, DateTime(2026, 4, 12));
    await tx('Dinner with friends', 'Entertainment', 180, DateTime(2026, 4, 13));
    await tx('Long weekend flight', 'Travel', 130, DateTime(2026, 4, 16));
    await tx('Sephora', 'Personal Care', 190, DateTime(2026, 4, 18));
    await tx('Running shoes', 'Fitness & Sports', 80, DateTime(2026, 4, 20));
    await tx('IRA contribution', 'Savings Transfer', 850, DateTime(2026, 4, 22));

    // ---- May: partial month (e.g. first week) ----
    await tx('Paycheck — ACME Corp', 'Salary', 5000, DateTime(2026, 5, 1, 9));
    await tx('Apartment rent', 'Housing', 1200, DateTime(2026, 5, 1));
    await tx('Savings auto-transfer', 'Savings Transfer', 250, DateTime(2026, 5, 1));
    await tx('Electric & water', 'Bills & Utilities', 180, DateTime(2026, 5, 2));
    await tx('Safeway', 'Food & Dining', 85, DateTime(2026, 5, 2));
    await tx('Chevron', 'Transportation', 45, DateTime(2026, 5, 3));
    await tx('Starbucks & snacks', 'Shopping', 95, DateTime(2026, 5, 3));
    await tx('Cinema', 'Entertainment', 35, DateTime(2026, 5, 4));

    await _recalculateAccountBalance(accountId);
    print('Demo financial seed complete (account $accountId)');
  }

  Future<bool> hasAiRoleExpenseHistorySeed() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM transactions WHERE notes LIKE ?',
      ['%$aiRoleHistorySeedMarker%'],
    );
    final n = rows.first['c'];
    return (n is int && n > 0) || (n is num && n > 0);
  }

  /// Deletes transactions tagged with [aiRoleHistorySeedMarker] and recomputes balances.
  Future<void> removeAiRoleExpenseHistorySeed() async {
    final db = await _db.database;
    await db.delete(
      'transactions',
      where: 'notes LIKE ?',
      whereArgs: ['%$aiRoleHistorySeedMarker%'],
    );
    for (final a in await _db.getAccounts()) {
      await _recalculateAccountBalance(a.id);
    }
    print('AI role expense history seed removed');
  }

  /// Expense-only history across the **last three calendar months** (same window as
  /// [SpendingSummaryService.build]), relative to [clock] or `DateTime.now()`.
  ///
  /// Uses default category → Needs/Wants/Goals mapping so Gemini sees realistic
  /// rolling averages. Does **not** create budgets or income rows.
  ///
  /// Cleanup: [removeAiRoleExpenseHistorySeed].
  Future<void> seedAiRoleExpenseHistory({
    bool replaceExisting = false,
    DateTime? clock,
  }) async {
    await seedDefaultData();

    if (replaceExisting) {
      await removeAiRoleExpenseHistorySeed();
    } else if (await hasAiRoleExpenseHistorySeed()) {
      throw StateError(
        'AI role expense history seed already exists. '
        'Call with replaceExisting: true to refresh.',
      );
    }

    final now = clock ?? DateTime.now();
    final categories = await _db.getCategories();
    final byName = {for (final c in categories) c.name: c.id};
    const requiredExpense = [
      'Housing',
      'Bills & Utilities',
      'Food & Dining',
      'Transportation',
      'Healthcare',
      'Shopping',
      'Entertainment',
      'Travel',
      'Personal Care',
      'Fitness & Sports',
      'Savings Transfer',
    ];
    for (final name in requiredExpense) {
      if (!byName.containsKey(name)) {
        throw StateError(
          'Missing category "$name". Run default seed first.',
        );
      }
    }

    var accounts = await _db.getAccounts();
    final tsNow = DateTime.now().millisecondsSinceEpoch;
    late final String accountId;
    if (accounts.isEmpty) {
      accountId = _uuid.v4();
      await _db.insertAccount(
        Account(
          id: accountId,
          name: 'Cash',
          balance: 0,
          currency: 'USD',
          createdAt: tsNow,
          updatedAt: tsNow,
        ),
      );
    } else {
      accountId = accounts.first.id;
    }

    final periodStart = DateTime(now.year, now.month - 2, 1);
    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    );

    Future<void> expense(
      String title,
      String categoryName,
      double amount,
      DateTime when,
    ) async {
      if (when.isBefore(periodStart)) return;
      if (when.isAfter(windowEnd)) return;
      await _db.insertTransaction(
        app_models.Transaction(
          id: _uuid.v4(),
          accountId: accountId,
          categoryId: byName[categoryName]!,
          amount: amount,
          title: title,
          notes: aiRoleHistorySeedMarker,
          date: when.millisecondsSinceEpoch,
          createdAt: tsNow,
          updatedAt: tsNow,
        ),
      );
    }

    for (var mi = 0; mi < 3; mi++) {
      final monthBase =
          DateTime(periodStart.year, periodStart.month + mi, 1);
      if (monthBase.year > now.year ||
          (monthBase.year == now.year && monthBase.month > now.month)) {
        break;
      }

      final lastDom = (monthBase.year == now.year && monthBase.month == now.month)
          ? now.day
          : DateTime(monthBase.year, monthBase.month + 1, 0).day;

      Future<void> ex(int dom, String cat, double amt, String title) async {
        final d = math.min(math.max(dom, 1), lastDom);
        await expense(title, cat, amt, DateTime(monthBase.year, monthBase.month, d));
      }

      final bump = mi * 18.0;

      await ex(2, 'Housing', 1215 + bump, 'Rent / mortgage');
      await ex(4, 'Bills & Utilities', 215 + mi * 8.0, 'Utilities bundle');
      await ex(6, 'Food & Dining', 88 + mi * 5.0, 'Groceries');
      await ex(8, 'Transportation', 62 + mi * 6.0, 'Transit pass top-up');
      await ex(10, 'Healthcare', 42 + mi * 11.0, 'Pharmacy');
      await ex(11, 'Food & Dining', 112 + mi * 4.0, 'Weekend groceries');
      await ex(13, 'Shopping', 96 + mi * 17.0, 'General merchandise');
      await ex(15, 'Entertainment', 38 + mi * 12.0, 'Streaming & outings');
      await ex(
        17,
        'Travel',
        mi.isEven ? 140 + mi * 25.0 : 85 + mi * 10.0,
        mi.isEven ? 'Regional trip' : 'Local getaway',
      );
      await ex(19, 'Personal Care', 52 + mi * 9.0, 'Personal care');
      await ex(21, 'Fitness & Sports', 68 + mi * 7.0, 'Gym & sports');
      await ex(23, 'Savings Transfer', 420 + mi * 35.0, 'Scheduled savings');
      await ex(24, 'Bills & Utilities', 36 + mi * 3.0, 'Mobile phone');
      await ex(26, 'Food & Dining', 74 + mi * 6.0, 'Dining out');
      await ex(27, 'Shopping', 58 + mi * 5.0, 'Online order');
      await ex(28, 'Entertainment', 24 + mi * 4.0, 'Movies');
      await ex(
        lastDom >= 29 ? 29 : lastDom,
        'Transportation',
        48 + mi * 5.0,
        'Fuel',
      );
    }

    await _recalculateAccountBalance(accountId);
    print(
      'AI role expense history seeded (${DateFormat.yMMMd().format(periodStart)} '
      '– ${DateFormat.yMMMd().format(windowEnd)}, account $accountId)',
    );
  }

  Future<void> _recalculateAccountBalance(String accountId) async {
    final txs = await _db.getTransactionsByAccount(accountId);
    final categories = await _db.getCategories();
    final typeById = {for (final x in categories) x.id: x.type};
    var balance = 0.0;
    for (final t in txs) {
      final typ = typeById[t.categoryId];
      if (typ == 'income') {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    await _db.updateAccountBalance(accountId, balance);
  }
}
