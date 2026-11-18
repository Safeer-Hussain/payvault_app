import 'package:flutter_test/flutter_test.dart';
import 'package:pay_vault/core/utils/recurring_scan_service.dart';
import 'package:pay_vault/core/utils/subscription_cancellation_notice_generator.dart';
import 'package:pay_vault/domain/entities/subscription_entity.dart';
import 'package:pay_vault/domain/entities/transaction_entity.dart';
import 'package:pay_vault/presentation/analytics_ledger/subscription_controller.dart';

import '../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecurringScanService Tests', () {
    test('Detects known recurring merchants from debit transactions', () {
      final now = DateTime.now();
      final transactions = [
        TransactionEntity(
          id: 'tx_aws',
          title: 'Amazon Web Services',
          subtitle: 'Cloud Compute',
          amount: 428.50,
          currency: 'USD',
          timestamp: now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
          category: 'Tech/Cloud',
          status: 'Completed',
          type: 'debit',
          referenceId: 'REF-AWS-9021',
        ),
        TransactionEntity(
          id: 'tx_credit',
          title: 'Salary Deposit',
          subtitle: 'Monthly Wire',
          amount: 8000.00,
          currency: 'USD',
          timestamp: now
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          category: 'Salary',
          status: 'Completed',
          type: 'credit',
          referenceId: 'REF-SAL-1029',
        ),
      ];

      final discovered = RecurringScanService.scanTransactions(transactions);

      expect(discovered.length, 1);
      final awsSub = discovered.first;
      expect(awsSub.merchantName, 'Amazon Web Services');
      expect(awsSub.amount, 428.50);
      expect(awsSub.currency, 'USD');
      expect(awsSub.category, 'Cloud Infrastructure');
      expect(awsSub.billingCycle, BillingCycle.monthly);
      expect(awsSub.status, SubscriptionStatus.active);
      expect(awsSub.vendorEmail, 'billing@aws.amazon.com');
      expect(awsSub.accountReference, 'PV-AWS-AWS-9021');
    });

    test('Statistically detects recurring interval for repeated debits', () {
      final now = DateTime.now();
      final transactions = [
        TransactionEntity(
          id: 'tx_sub_recent',
          title: 'Figma Enterprise Workspace',
          subtitle: 'Design Platform',
          amount: 75.00,
          currency: 'USD',
          timestamp: now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
          category: 'Software',
          status: 'Completed',
          type: 'debit',
          referenceId: 'REF-FIG-02',
        ),
        TransactionEntity(
          id: 'tx_sub_prior',
          title: 'Figma Enterprise Workspace',
          subtitle: 'Design Platform',
          amount: 75.00,
          currency: 'USD',
          timestamp: now
              .subtract(const Duration(days: 32))
              .millisecondsSinceEpoch,
          category: 'Software',
          status: 'Completed',
          type: 'debit',
          referenceId: 'REF-FIG-01',
        ),
      ];

      final discovered = RecurringScanService.scanTransactions(transactions);

      expect(discovered.length, 1);
      final figma = discovered.first;
      expect(figma.merchantName, 'Figma Enterprise Workspace');
      expect(figma.amount, 75.00);
      expect(figma.detectedFrequencyDays, 30);
      expect(figma.billingCycle, BillingCycle.monthly);
    });

    test('Does not duplicate already existing subscriptions', () {
      final now = DateTime.now();
      final existing = [
        SubscriptionEntity(
          id: 'sub_amazon_web_services',
          merchantName: 'Amazon Web Services',
          category: 'Cloud Infrastructure',
          amount: 428.50,
          currency: 'USD',
          billingCycle: BillingCycle.monthly,
          status: SubscriptionStatus.active,
          paymentMethod: 'Executive Titanium Vault',
          nextBillingDate: now.add(const Duration(days: 28)),
          detectedFrequencyDays: 30,
          vendorEmail: 'billing@aws.amazon.com',
          accountReference: 'PV-AWS-9021',
        ),
      ];

      final transactions = [
        TransactionEntity(
          id: 'tx_aws',
          title: 'Amazon Web Services',
          subtitle: 'Cloud Compute',
          amount: 428.50,
          currency: 'USD',
          timestamp: now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
          category: 'Tech/Cloud',
          status: 'Completed',
          type: 'debit',
          referenceId: 'REF-AWS-9021',
        ),
      ];

      final discovered = RecurringScanService.scanTransactions(
        transactions,
        existingSubscriptions: existing,
      );

      expect(discovered, isEmpty);
    });
  });

  group('SubscriptionCancellationNoticeGenerator Tests', () {
    test('Generates formal legal notice with cryptographic dispatch stamp', () {
      final sub = SubscriptionEntity(
        id: 'sub_bloomberg',
        merchantName: 'Bloomberg Professional',
        category: 'Financial Intelligence',
        amount: 2400.00,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        status: SubscriptionStatus.active,
        paymentMethod: 'Executive Titanium Vault (••8812)',
        nextBillingDate: DateTime.now().add(const Duration(days: 10)),
        detectedFrequencyDays: 30,
        vendorEmail: 'billing@bloomberg.com',
        accountReference: 'PV-BLM-1102',
      );

      final notice = SubscriptionCancellationNoticeGenerator.generateNotice(
        subscription: sub,
        userName: 'Safeer Hussain',
        userEmail: 'bcsm-s20-033@superior.edu.pk',
        reason: 'Consolidation of operational recurring expenditures',
      );

      expect(notice, contains('FORMAL NOTICE OF SUBSCRIPTION CANCELLATION'));
      expect(notice, contains('Bloomberg Professional'));
      expect(notice, contains('billing@bloomberg.com'));
      expect(notice, contains('Safeer Hussain'));
      expect(notice, contains('bcsm-s20-033@superior.edu.pk'));
      expect(notice, contains('PV-BLM-1102'));
      expect(notice, contains('USD 2400.00'));
      expect(notice, contains('PV-CANCEL-SEAL-'));
      expect(
        notice,
        contains('REVOCATION OF PRE-AUTHORIZED RECURRING PAYMENT MANDATE'),
      );
    });
  });

  group('SubscriptionRepository & Controller Tests', () {
    late FakeSubscriptionRepository repo;
    late SubscriptionController controller;

    setUp(() {
      repo = FakeSubscriptionRepository();
      controller = SubscriptionController(repo);
    });

    test(
      'Initializes with seeded subscriptions and calculates spend metrics',
      () async {
        await controller.loadSubscriptions();

        expect(controller.subscriptions.isNotEmpty, isTrue);
        expect(
          controller.activeCount,
          3,
        ); // AWS (428.50), Bloomberg (2400), GitHub (21)
        expect(controller.frozenCount, 1); // OpenAI (20)

        // Total monthly active spend: 428.50 + 2400.00 + 21.00 = 2849.50
        expect(controller.totalMonthlySpend, closeTo(2849.50, 0.01));
        expect(controller.annualizedRunRate, closeTo(2849.50 * 12.0, 0.01));
      },
    );

    test('Toggles freeze and unfreeze status immutably', () async {
      await controller.loadSubscriptions();
      final awsSub = controller.subscriptions.firstWhere(
        (s) => s.id == 'sub_aws',
      );
      expect(awsSub.isActive, isTrue);

      await controller.toggleFreeze(awsSub);
      final frozenAws = controller.subscriptions.firstWhere(
        (s) => s.id == 'sub_aws',
      );
      expect(frozenAws.isFrozen, isTrue);
      expect(controller.frozenCount, 2);

      await controller.toggleFreeze(frozenAws);
      final resumedAws = controller.subscriptions.firstWhere(
        (s) => s.id == 'sub_aws',
      );
      expect(resumedAws.isActive, isTrue);
    });

    test('Cancels subscription with bot and stores notice', () async {
      await controller.loadSubscriptions();
      final ghSub = controller.subscriptions.firstWhere(
        (s) => s.id == 'sub_github',
      );

      await controller.cancelSubscriptionWithBot(
        ghSub,
        reason: 'Consolidated developer tooling',
      );

      final cancelledGh = controller.subscriptions.firstWhere(
        (s) => s.id == 'sub_github',
      );
      expect(cancelledGh.isCancelled, isTrue);
      expect(cancelledGh.cancellationReason, 'Consolidated developer tooling');
      expect(cancelledGh.cancellationNotice, contains('PV-CANCEL-SEAL-'));
    });

    test('Filters subscriptions by status accurately', () async {
      await controller.loadSubscriptions();

      controller.setFilter('Active');
      expect(controller.filteredSubscriptions.every((s) => s.isActive), isTrue);

      controller.setFilter('Frozen');
      expect(controller.filteredSubscriptions.every((s) => s.isFrozen), isTrue);

      controller.setFilter('All');
      expect(
        controller.filteredSubscriptions.length,
        controller.subscriptions.length,
      );
    });
  });
}
