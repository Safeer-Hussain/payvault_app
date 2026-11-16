import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/savings_vault_entity.dart';
import '../../domain/repositories/savings_vault_repository.dart';
import '../datasources/local_database.dart';
import '../models/savings_vault_model.dart';
import '../models/transaction_model.dart';

class SavingsVaultRepositoryImpl implements SavingsVaultRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<SavingsVaultEntity> getSavingsVault() async {
    final db = await AppDatabase.database;
    await AppDatabase.ensureSavingsVaultInitialized(db);

    final maps = await db.query(
      'savings_vaults',
      where: 'id = ?',
      whereArgs: ['sv_spare_change'],
      limit: 1,
    );

    if (maps.isEmpty) {
      throw Exception('Spare change savings vault not found');
    }
    return SavingsVaultModel.fromMap(maps.first);
  }

  @override
  Future<SavingsVaultEntity> updateRoundupSettings({
    required bool isEnabled,
    required int multiplier,
  }) async {
    final db = await AppDatabase.database;
    await AppDatabase.ensureSavingsVaultInitialized(db);

    await db.update(
      'savings_vaults',
      {'isRoundupEnabled': isEnabled ? 1 : 0, 'roundupMultiplier': multiplier},
      where: 'id = ?',
      whereArgs: ['sv_spare_change'],
    );

    return getSavingsVault();
  }

  @override
  Future<void> executeRoundupTransfer({
    required String sourceCurrency,
    required double roundupAmount,
    required String originalTxId,
  }) async {
    if (roundupAmount <= 0) return;

    final db = await AppDatabase.database;
    await AppDatabase.ensureSavingsVaultInitialized(db);

    await db.transaction((txn) async {
      // 1. Check source wallet balance
      final walletMaps = await txn.query(
        'wallets',
        where: 'currency = ?',
        whereArgs: [sourceCurrency],
        limit: 1,
      );
      if (walletMaps.isEmpty) {
        throw Exception('Source wallet $sourceCurrency not found');
      }

      final currentBal = (walletMaps.first['balance'] as num).toDouble();
      if (currentBal < roundupAmount) {
        throw Exception('Insufficient funds in $sourceCurrency for roundup');
      }

      // 2. Deduct roundup from wallet
      await txn.update(
        'wallets',
        {'balance': currentBal - roundupAmount},
        where: 'currency = ?',
        whereArgs: [sourceCurrency],
      );

      // 3. Credit savings vault
      final svMaps = await txn.query(
        'savings_vaults',
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
        limit: 1,
      );
      if (svMaps.isEmpty) {
        throw Exception('Savings vault not found');
      }

      final svModel = SavingsVaultModel.fromMap(svMaps.first);
      final newSvBalance = svModel.balance + roundupAmount;
      final newTotalSaved = svModel.totalSaved + roundupAmount;
      final newRoundupsCount = svModel.totalRoundupsCount + 1;

      await txn.update(
        'savings_vaults',
        {
          'balance': newSvBalance,
          'totalSaved': newTotalSaved,
          'totalRoundupsCount': newRoundupsCount,
          'lastRoundupTimestamp': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
      );

      // 4. Create ledger transaction for the roundup
      final tx = TransactionModel(
        id: 'tx_rnd_${_uuid.v4().substring(0, 8)}',
        title: 'Spare Change Auto-Roundup',
        subtitle:
            'Auto-transferred to High-Yield Savings Vault (${svModel.roundupMultiplier}x multiplier)',
        amount: roundupAmount,
        currency: sourceCurrency,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        category: 'Savings',
        status: 'Completed',
        type: 'debit',
        referenceId: 'RND-${_uuid.v4().substring(0, 8).toUpperCase()}',
      );

      await txn.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> withdrawToWallet({
    required double amount,
    required String targetCurrency,
  }) async {
    if (amount <= 0) {
      throw Exception('Withdrawal amount must be greater than zero');
    }

    final db = await AppDatabase.database;
    await AppDatabase.ensureSavingsVaultInitialized(db);

    await db.transaction((txn) async {
      // 1. Check savings vault balance
      final svMaps = await txn.query(
        'savings_vaults',
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
        limit: 1,
      );
      if (svMaps.isEmpty) {
        throw Exception('Savings vault not found');
      }

      final svModel = SavingsVaultModel.fromMap(svMaps.first);
      if (svModel.balance < amount) {
        throw Exception(
          'Insufficient balance in Savings Vault (Available: \$${svModel.balance.toStringAsFixed(2)})',
        );
      }

      // 2. Deduct from savings vault
      await txn.update(
        'savings_vaults',
        {'balance': svModel.balance - amount},
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
      );

      // 3. Credit target currency wallet
      final walletMaps = await txn.query(
        'wallets',
        where: 'currency = ?',
        whereArgs: [targetCurrency],
        limit: 1,
      );
      if (walletMaps.isEmpty) {
        throw Exception('Target wallet $targetCurrency not found');
      }

      final currentBal = (walletMaps.first['balance'] as num).toDouble();
      await txn.update(
        'wallets',
        {'balance': currentBal + amount},
        where: 'currency = ?',
        whereArgs: [targetCurrency],
      );

      // 4. Create credit transaction record
      final tx = TransactionModel(
        id: 'tx_wth_${_uuid.v4().substring(0, 8)}',
        title: 'Savings Vault Withdrawal',
        subtitle: 'Transferred from Spare Change Vault to $targetCurrency',
        amount: amount,
        currency: targetCurrency,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        category: 'Savings',
        status: 'Completed',
        type: 'credit',
        referenceId: 'WTH-${_uuid.v4().substring(0, 8).toUpperCase()}',
      );

      await txn.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> depositToSavings({
    required double amount,
    required String sourceCurrency,
  }) async {
    if (amount <= 0) {
      throw Exception('Deposit amount must be greater than zero');
    }

    final db = await AppDatabase.database;
    await AppDatabase.ensureSavingsVaultInitialized(db);

    await db.transaction((txn) async {
      // 1. Check wallet balance
      final walletMaps = await txn.query(
        'wallets',
        where: 'currency = ?',
        whereArgs: [sourceCurrency],
        limit: 1,
      );
      if (walletMaps.isEmpty) {
        throw Exception('Source wallet $sourceCurrency not found');
      }

      final currentBal = (walletMaps.first['balance'] as num).toDouble();
      if (currentBal < amount) {
        throw Exception('Insufficient funds in $sourceCurrency wallet');
      }

      // 2. Deduct from wallet
      await txn.update(
        'wallets',
        {'balance': currentBal - amount},
        where: 'currency = ?',
        whereArgs: [sourceCurrency],
      );

      // 3. Credit savings vault
      final svMaps = await txn.query(
        'savings_vaults',
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
        limit: 1,
      );
      final svModel = SavingsVaultModel.fromMap(svMaps.first);

      await txn.update(
        'savings_vaults',
        {
          'balance': svModel.balance + amount,
          'totalSaved': svModel.totalSaved + amount,
          'lastRoundupTimestamp': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
      );

      // 4. Transaction record
      final tx = TransactionModel(
        id: 'tx_dep_${_uuid.v4().substring(0, 8)}',
        title: 'Savings Vault Deposit',
        subtitle: 'Manual transfer from $sourceCurrency to Spare Change Vault',
        amount: amount,
        currency: sourceCurrency,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        category: 'Savings',
        status: 'Completed',
        type: 'debit',
        referenceId: 'DEP-${_uuid.v4().substring(0, 8).toUpperCase()}',
      );

      await txn.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
