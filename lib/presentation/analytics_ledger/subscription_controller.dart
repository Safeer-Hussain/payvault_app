import 'package:get/get.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionController extends GetxController {
  final SubscriptionRepository _subscriptionRepository;

  SubscriptionController(this._subscriptionRepository);

  final RxList<SubscriptionEntity> subscriptions = <SubscriptionEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxString selectedFilter = 'All'.obs;

  final List<String> filterOptions = ['All', 'Active', 'Frozen', 'Cancelled'];

  @override
  void onInit() {
    super.onInit();
    loadSubscriptions();
  }

  List<SubscriptionEntity> get filteredSubscriptions {
    switch (selectedFilter.value) {
      case 'Active':
        return subscriptions.where((s) => s.isActive).toList();
      case 'Frozen':
        return subscriptions.where((s) => s.isFrozen).toList();
      case 'Cancelled':
        return subscriptions.where((s) => s.isCancelled).toList();
      default:
        return subscriptions.toList();
    }
  }

  double get totalMonthlySpend {
    return subscriptions
        .where((s) => s.isActive)
        .fold(0.0, (acc, item) => acc + item.monthlyNormalizedAmount);
  }

  double get annualizedRunRate => totalMonthlySpend * 12.0;

  int get activeCount => subscriptions.where((s) => s.isActive).length;
  int get frozenCount => subscriptions.where((s) => s.isFrozen).length;
  int get cancelledCount => subscriptions.where((s) => s.isCancelled).length;

  Future<void> loadSubscriptions() async {
    isLoading.value = true;
    try {
      final list = await _subscriptionRepository.getSubscriptions();
      subscriptions.assignAll(list);
    } catch (e) {
      AppFeedback.showError(
        message: 'Failed to load recurring subscriptions: $e',
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> scanRecurringCharges() async {
    isScanning.value = true;
    try {
      final updated = await _subscriptionRepository.scanRecurringCharges();
      final newCount = updated.length - subscriptions.length;
      subscriptions.assignAll(updated);
      if (newCount > 0) {
        AppFeedback.showSuccess(
          title: 'Subscription Scan Complete',
          message: 'Discovered $newCount new recurring merchant subscriptions.',
        );
      } else {
        AppFeedback.showInfo(
          title: 'Subscription Scan Complete',
          message: 'All recurring merchant charges are currently synchronized.',
        );
      }
    } catch (e) {
      AppFeedback.showError(message: 'Error during recurring scan: $e');
    } finally {
      isScanning.value = false;
      update();
    }
  }

  Future<void> toggleFreeze(SubscriptionEntity sub) async {
    try {
      final SubscriptionEntity updated;
      if (sub.isFrozen) {
        updated = await _subscriptionRepository.unfreezeSubscription(sub.id);
        AppFeedback.showSuccess(
          title: 'Subscription Resumed',
          message: '${sub.merchantName} recurring billing mandate reactivated.',
        );
      } else {
        updated = await _subscriptionRepository.freezeSubscription(sub.id);
        AppFeedback.showWarning(
          title: 'Subscription Frozen',
          message:
              'Temporary hold placed on ${sub.merchantName}. Future debits blocked.',
        );
      }
      final idx = subscriptions.indexWhere((s) => s.id == sub.id);
      if (idx != -1) {
        subscriptions[idx] = updated;
      }
      update();
    } catch (e) {
      AppFeedback.showError(
        message: 'Failed to update subscription status: $e',
      );
    }
  }

  Future<void> cancelSubscriptionWithBot(
    SubscriptionEntity sub, {
    String? reason,
  }) async {
    try {
      final updated = await _subscriptionRepository.cancelSubscription(
        sub.id,
        reason: reason,
      );
      final idx = subscriptions.indexWhere((s) => s.id == sub.id);
      if (idx != -1) {
        subscriptions[idx] = updated;
      }
      AppFeedback.showSuccess(
        title: 'Subscription Cancelled',
        message:
            'Formal cancellation notice dispatched to ${sub.merchantName}. Card token frozen.',
      );
      update();
    } catch (e) {
      AppFeedback.showError(message: 'Failed to cancel subscription: $e');
    }
  }

  String previewNotice(SubscriptionEntity sub, {String? reason}) {
    return _subscriptionRepository.generateCancellationNotice(
      sub,
      userName: 'Safeer Hussain',
      userEmail: 'bcsm-s20-033@superior.edu.pk',
      reason: reason,
    );
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
}
