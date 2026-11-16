import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/local_database.dart';
import '../models/contact_model.dart';
import '../models/transaction_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ContactEntity>> getContacts() async {
    final db = await AppDatabase.database;
    final maps = await db.query('contacts', orderBy: 'lastTransferDate DESC');
    return maps.map((m) => ContactModel.fromMap(m)).toList();
  }

  @override
  Future<ContactEntity> addContact({
    required String name,
    required String handle,
    required String iban,
  }) async {
    final db = await AppDatabase.database;
    final contact = ContactModel(
      id: 'cont_${_uuid.v4().substring(0, 8)}',
      name: name,
      handle: handle.startsWith('@') ? handle : '@$handle',
      avatarUrl: 'assets/images/avatar_user.png',
      iban: iban.toUpperCase(),
      lastTransferDate: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return contact;
  }

  @override
  Future<TransactionEntity> executeP2PTransfer({
    required String recipientName,
    required String recipientHandle,
    required String currency,
    required double amount,
    required String memo,
    required String biometricAuthToken,
  }) async {
    final db = await AppDatabase.database;
    await AppDatabase.ensureSavingsVaultInitialized(db);
    late TransactionModel txModel;

    await db.transaction((txn) async {
      final walletMaps = await txn.query(
        'wallets',
        where: 'currency = ?',
        whereArgs: [currency],
        limit: 1,
      );
      if (walletMaps.isEmpty) {
        throw Exception('Vault wallet $currency not found');
      }
      final currentBal = (walletMaps.first['balance'] as num).toDouble();

      // Check auto-roundup
      double roundupAmount = 0.0;
      final svMaps = await txn.query(
        'savings_vaults',
        where: 'id = ?',
        whereArgs: ['sv_spare_change'],
        limit: 1,
      );
      if (svMaps.isNotEmpty) {
        final sv = svMaps.first;
        final isRoundupEnabled = (sv['isRoundupEnabled'] as int) == 1;
        final multiplier = (sv['roundupMultiplier'] as int?) ?? 1;
        if (isRoundupEnabled) {
          final ceil = amount.ceilToDouble();
          final diff = ceil > amount ? (ceil - amount) : 0.0;
          if (diff > 0.0) {
            final raw = diff * multiplier;
            roundupAmount = double.parse(raw.toStringAsFixed(2));
          }
        }
      }

      final totalDeduction = amount + roundupAmount;
      if (currentBal < totalDeduction) {
        throw Exception('Insufficient funds in $currency vault');
      }

      // Deduct total balance (amount + roundup)
      await txn.update(
        'wallets',
        {'balance': currentBal - totalDeduction},
        where: 'currency = ?',
        whereArgs: [currency],
      );

      // Create primary transaction
      txModel = TransactionModel(
        id: 'tx_${_uuid.v4().substring(0, 8)}',
        title: 'Transfer to $recipientName',
        subtitle: memo.isNotEmpty ? memo : 'P2P Transfer to $recipientHandle',
        amount: amount,
        currency: currency,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        category: 'Shopping',
        status: 'Completed',
        type: 'debit',
        referenceId: 'P2P-${_uuid.v4().substring(0, 8).toUpperCase()}',
      );
      await txn.insert(
        'transactions',
        txModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If spare change rounded up, credit savings vault & record ledger transaction
      if (roundupAmount > 0.0 && svMaps.isNotEmpty) {
        final sv = svMaps.first;
        final svBal = (sv['balance'] as num).toDouble();
        final svSaved = (sv['totalSaved'] as num).toDouble();
        final svCount = sv['totalRoundupsCount'] as int;

        await txn.update(
          'savings_vaults',
          {
            'balance': svBal + roundupAmount,
            'totalSaved': svSaved + roundupAmount,
            'totalRoundupsCount': svCount + 1,
            'lastRoundupTimestamp': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: ['sv_spare_change'],
        );

        final roundupTx = TransactionModel(
          id: 'tx_rnd_${_uuid.v4().substring(0, 8)}',
          title: 'Spare Change Auto-Roundup',
          subtitle: 'Auto-saved to High-Yield Savings Vault',
          amount: roundupAmount,
          currency: currency,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          category: 'Savings',
          status: 'Completed',
          type: 'debit',
          referenceId: 'RND-${_uuid.v4().substring(0, 8).toUpperCase()}',
        );
        await txn.insert(
          'transactions',
          roundupTx.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Update contact if exists
      await txn.update(
        'contacts',
        {'lastTransferDate': DateTime.now().millisecondsSinceEpoch},
        where: 'handle = ?',
        whereArgs: [recipientHandle],
      );
    });

    return txModel;
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? category,
    String? searchQuery,
  }) async {
    final db = await AppDatabase.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause = 'category = ?';
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryCondition =
          '(title LIKE ? OR subtitle LIKE ? OR referenceId LIKE ?)';
      final queryParam = '%${searchQuery.trim()}%';
      if (whereClause != null) {
        whereClause = '$whereClause AND $queryCondition';
      } else {
        whereClause = queryCondition;
      }
      whereArgs.addAll([queryParam, queryParam, queryParam]);
    }

    final maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }
}
