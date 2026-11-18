import '../../domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.merchantName,
    required super.category,
    required super.amount,
    required super.currency,
    required super.billingCycle,
    required super.status,
    required super.paymentMethod,
    required super.nextBillingDate,
    required super.detectedFrequencyDays,
    required super.vendorEmail,
    required super.accountReference,
    super.cancellationNotice,
    super.cancellationReason,
  });

  factory SubscriptionModel.fromEntity(SubscriptionEntity entity) {
    return SubscriptionModel(
      id: entity.id,
      merchantName: entity.merchantName,
      category: entity.category,
      amount: entity.amount,
      currency: entity.currency,
      billingCycle: entity.billingCycle,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      nextBillingDate: entity.nextBillingDate,
      detectedFrequencyDays: entity.detectedFrequencyDays,
      vendorEmail: entity.vendorEmail,
      accountReference: entity.accountReference,
      cancellationNotice: entity.cancellationNotice,
      cancellationReason: entity.cancellationReason,
    );
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String,
      merchantName: map['merchantName'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == (map['billingCycle'] as String),
        orElse: () => BillingCycle.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => SubscriptionStatus.active,
      ),
      paymentMethod: map['paymentMethod'] as String,
      nextBillingDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextBillingDate'] as int,
      ),
      detectedFrequencyDays: map['detectedFrequencyDays'] as int,
      vendorEmail: map['vendorEmail'] as String,
      accountReference: map['accountReference'] as String,
      cancellationNotice: map['cancellationNotice'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantName': merchantName,
      'category': category,
      'amount': amount,
      'currency': currency,
      'billingCycle': billingCycle.name,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'nextBillingDate': nextBillingDate.millisecondsSinceEpoch,
      'detectedFrequencyDays': detectedFrequencyDays,
      'vendorEmail': vendorEmail,
      'accountReference': accountReference,
      'cancellationNotice': cancellationNotice,
      'cancellationReason': cancellationReason,
    };
  }
}
