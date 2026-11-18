import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class DetectedRecurringPattern {
  final String merchantName;
  final String category;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final int frequencyDays;
  final DateTime nextBillingDate;
  final String vendorEmail;
  final String accountReference;
  final double confidenceScore;

  const DetectedRecurringPattern({
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.frequencyDays,
    required this.nextBillingDate,
    required this.vendorEmail,
    required this.accountReference,
    required this.confidenceScore,
  });
}

class RecurringScanService {
  // Known recurring merchant dictionary for high-precision entity extraction
  static final Map<String, Map<String, String>> _knownMerchants = {
    'amazon web services': {
      'merchant': 'Amazon Web Services',
      'category': 'Cloud Infrastructure',
      'email': 'billing@aws.amazon.com',
      'refPrefix': 'PV-AWS',
    },
    'aws': {
      'merchant': 'Amazon Web Services',
      'category': 'Cloud Infrastructure',
      'email': 'billing@aws.amazon.com',
      'refPrefix': 'PV-AWS',
    },
    'bloomberg': {
      'merchant': 'Bloomberg Professional',
      'category': 'Financial Intelligence',
      'email': 'billing@bloomberg.com',
      'refPrefix': 'PV-BLM',
    },
    'netflix': {
      'merchant': 'Netflix Premium',
      'category': 'Streaming Media',
      'email': 'support@netflix.com',
      'refPrefix': 'PV-NFLX',
    },
    'github': {
      'merchant': 'GitHub Enterprise',
      'category': 'Developer Tools',
      'email': 'support@github.com',
      'refPrefix': 'PV-GH',
    },
    'openai': {
      'merchant': 'OpenAI ChatGPT Plus',
      'category': 'AI Services',
      'email': 'ar@openai.com',
      'refPrefix': 'PV-OAI',
    },
    'spotify': {
      'merchant': 'Spotify HiFi',
      'category': 'Audio Entertainment',
      'email': 'billing@spotify.com',
      'refPrefix': 'PV-SPOT',
    },
    'slack': {
      'merchant': 'Slack Enterprise Grid',
      'category': 'Team Collaboration',
      'email': 'billing@slack.com',
      'refPrefix': 'PV-SLCK',
    },
    'adobe': {
      'merchant': 'Adobe Creative Cloud',
      'category': 'Design & Creative',
      'email': 'billing@adobe.com',
      'refPrefix': 'PV-ADBE',
    },
    'google': {
      'merchant': 'Google Workspace Enterprise',
      'category': 'Cloud Productivity',
      'email': 'workspace-billing@google.com',
      'refPrefix': 'PV-GWRK',
    },
  };

  /// Analyzes transaction history and extracts recurring merchant subscriptions.
  static List<SubscriptionEntity> scanTransactions(
    List<TransactionEntity> transactions, {
    List<SubscriptionEntity> existingSubscriptions = const [],
  }) {
    final existingIds = existingSubscriptions.map((s) => s.id).toSet();
    final existingMerchants = existingSubscriptions
        .map((s) => s.merchantName.toLowerCase())
        .toSet();

    final debits = transactions.where((tx) => tx.isDebit).toList();
    final Map<String, List<TransactionEntity>> grouped = {};

    for (final tx in debits) {
      final key = _normalizeMerchantKey(tx.title);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final List<SubscriptionEntity> discovered = [];

    grouped.forEach((key, txList) {
      // Sort chronologically descending
      txList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestTx = txList.first;
      final known = _findKnownMerchant(key);

      if (known != null) {
        // High confidence recurring merchant
        final merchantName = known['merchant']!;
        if (!existingMerchants.contains(merchantName.toLowerCase())) {
          final id = 'sub_${_slugify(merchantName)}';
          if (!existingIds.contains(id)) {
            final latestDt = DateTime.fromMillisecondsSinceEpoch(
              latestTx.timestamp,
            );
            final nextBilling = latestDt.add(const Duration(days: 30));
            discovered.add(
              SubscriptionEntity(
                id: id,
                merchantName: merchantName,
                category: known['category']!,
                amount: latestTx.amount,
                currency: latestTx.currency,
                billingCycle: BillingCycle.monthly,
                status: SubscriptionStatus.active,
                paymentMethod: 'Executive Titanium Vault (••8812)',
                nextBillingDate: nextBilling,
                detectedFrequencyDays: 30,
                vendorEmail: known['email']!,
                accountReference:
                    '${known['refPrefix']}-${latestTx.referenceId.replaceAll('REF-', '')}',
              ),
            );
          }
        }
      } else if (txList.length >= 2) {
        // Statistical frequency cadence detection
        final latest = txList[0];
        final previous = txList[1];
        final latestDt = DateTime.fromMillisecondsSinceEpoch(latest.timestamp);
        final previousDt = DateTime.fromMillisecondsSinceEpoch(
          previous.timestamp,
        );
        final diffDays = latestDt.difference(previousDt).inDays.abs();

        final amountDeltaPercent =
            (latest.amount - previous.amount).abs() / latest.amount;

        if (amountDeltaPercent <= 0.15 && diffDays >= 20 && diffDays <= 45) {
          final merchantName = latest.title;
          if (!existingMerchants.contains(merchantName.toLowerCase())) {
            final id = 'sub_${_slugify(merchantName)}';
            if (!existingIds.contains(id)) {
              final nextBilling = latestDt.add(Duration(days: diffDays));
              discovered.add(
                SubscriptionEntity(
                  id: id,
                  merchantName: merchantName,
                  category: latest.category.isNotEmpty
                      ? latest.category
                      : 'Recurring SaaS',
                  amount: latest.amount,
                  currency: latest.currency,
                  billingCycle: BillingCycle.monthly,
                  status: SubscriptionStatus.active,
                  paymentMethod: 'Executive Titanium Vault (••8812)',
                  nextBillingDate: nextBilling,
                  detectedFrequencyDays: diffDays,
                  vendorEmail: 'billing@${_slugify(merchantName)}.com',
                  accountReference: 'PV-SUB-${latest.referenceId}',
                ),
              );
            }
          }
        }
      }
    });

    return discovered;
  }

  static String _normalizeMerchantKey(String title) {
    return title.toLowerCase().trim();
  }

  static Map<String, String>? _findKnownMerchant(String key) {
    for (final entry in _knownMerchants.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
