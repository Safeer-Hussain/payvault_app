import '../entities/subscription_entity.dart';
import '../entities/transaction_entity.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionEntity>> getSubscriptions();

  Future<List<SubscriptionEntity>> scanRecurringCharges({
    List<TransactionEntity>? transactions,
  });

  Future<SubscriptionEntity> freezeSubscription(String id);

  Future<SubscriptionEntity> unfreezeSubscription(String id);

  Future<SubscriptionEntity> cancelSubscription(
    String id, {
    String? reason,
    String? customNotice,
  });

  Future<SubscriptionEntity> addSubscription(SubscriptionEntity subscription);

  String generateCancellationNotice(
    SubscriptionEntity subscription, {
    required String userName,
    required String userEmail,
    String? reason,
  });
}
