enum SubscriptionStatus { active, frozen, cancelled }

enum BillingCycle { monthly, quarterly, annual }

class SubscriptionEntity {
  final String id;
  final String merchantName;
  final String category;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final SubscriptionStatus status;
  final String paymentMethod;
  final DateTime nextBillingDate;
  final int detectedFrequencyDays;
  final String vendorEmail;
  final String accountReference;
  final String? cancellationNotice;
  final String? cancellationReason;

  const SubscriptionEntity({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.status,
    required this.paymentMethod,
    required this.nextBillingDate,
    required this.detectedFrequencyDays,
    required this.vendorEmail,
    required this.accountReference,
    this.cancellationNotice,
    this.cancellationReason,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isFrozen => status == SubscriptionStatus.frozen;
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  double get monthlyNormalizedAmount {
    switch (billingCycle) {
      case BillingCycle.monthly:
        return amount;
      case BillingCycle.quarterly:
        return amount / 3.0;
      case BillingCycle.annual:
        return amount / 12.0;
    }
  }

  SubscriptionEntity copyWith({
    String? id,
    String? merchantName,
    String? category,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    SubscriptionStatus? status,
    String? paymentMethod,
    DateTime? nextBillingDate,
    int? detectedFrequencyDays,
    String? vendorEmail,
    String? accountReference,
    String? cancellationNotice,
    String? cancellationReason,
  }) {
    return SubscriptionEntity(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      detectedFrequencyDays:
          detectedFrequencyDays ?? this.detectedFrequencyDays,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      accountReference: accountReference ?? this.accountReference,
      cancellationNotice: cancellationNotice ?? this.cancellationNotice,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
