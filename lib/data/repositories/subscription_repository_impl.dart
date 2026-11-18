import 'package:sqflite/sqflite.dart';

import '../../core/utils/recurring_scan_service.dart';
import '../../core/utils/subscription_cancellation_notice_generator.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/local_database.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  Future<Database> get _db async => await AppDatabase.database;

  @override
  Future<List<SubscriptionEntity>> getSubscriptions() async {
    final db = await _db;
    final maps = await db.query(
      'subscriptions',
      orderBy: 'nextBillingDate ASC',
    );
    return maps.map((m) => SubscriptionModel.fromMap(m)).toList();
  }

  @override
  Future<List<SubscriptionEntity>> scanRecurringCharges({
    List<TransactionEntity>? transactions,
  }) async {
    final db = await _db;
    List<TransactionEntity> txList = transactions ?? [];

    if (txList.isEmpty) {
      final txMaps = await db.query('transactions', orderBy: 'timestamp DESC');
      txList = txMaps.map((m) => TransactionModel.fromMap(m)).toList();
    }

    final currentSubscriptions = await getSubscriptions();
    final discovered = RecurringScanService.scanTransactions(
      txList,
      existingSubscriptions: currentSubscriptions,
    );

    for (final newSub in discovered) {
      final model = SubscriptionModel.fromEntity(newSub);
      await db.insert(
        'subscriptions',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return await getSubscriptions();
  }

  @override
  Future<SubscriptionEntity> freezeSubscription(String id) async {
    final db = await _db;
    await db.update(
      'subscriptions',
      {'status': SubscriptionStatus.frozen.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    final results = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) {
      throw Exception('Subscription with id $id not found');
    }
    return SubscriptionModel.fromMap(results.first);
  }

  @override
  Future<SubscriptionEntity> unfreezeSubscription(String id) async {
    final db = await _db;
    await db.update(
      'subscriptions',
      {'status': SubscriptionStatus.active.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    final results = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) {
      throw Exception('Subscription with id $id not found');
    }
    return SubscriptionModel.fromMap(results.first);
  }

  @override
  Future<SubscriptionEntity> cancelSubscription(
    String id, {
    String? reason,
    String? customNotice,
  }) async {
    final db = await _db;
    final results = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) {
      throw Exception('Subscription with id $id not found');
    }

    final current = SubscriptionModel.fromMap(results.first);
    final notice =
        customNotice ??
        generateCancellationNotice(
          current,
          userName: 'Safeer Hussain',
          userEmail: 'bcsm-s20-033@superior.edu.pk',
          reason: reason,
        );

    await db.update(
      'subscriptions',
      {
        'status': SubscriptionStatus.cancelled.name,
        'cancellationNotice': notice,
        'cancellationReason':
            reason ?? 'Consolidation of operational recurring expenditures',
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final updated = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return SubscriptionModel.fromMap(updated.first);
  }

  @override
  Future<SubscriptionEntity> addSubscription(
    SubscriptionEntity subscription,
  ) async {
    final db = await _db;
    final model = SubscriptionModel.fromEntity(subscription);
    await db.insert(
      'subscriptions',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return subscription;
  }

  @override
  String generateCancellationNotice(
    SubscriptionEntity subscription, {
    required String userName,
    required String userEmail,
    String? reason,
  }) {
    return SubscriptionCancellationNoticeGenerator.generateNotice(
      subscription: subscription,
      userName: userName,
      userEmail: userEmail,
      reason: reason,
    );
  }
}
