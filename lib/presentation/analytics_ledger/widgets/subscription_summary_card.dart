import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../subscription_controller.dart';
import 'subscription_bot_sheet.dart';

class SubscriptionSummaryCard extends StatelessWidget {
  const SubscriptionSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<SubscriptionController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SUBSCRIPTION CANCELLATION BOT',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => Text(
                        '${controller.activeCount} Active Mandates • \$${controller.totalMonthlySpend.toStringAsFixed(2)}/mo',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.tune_outlined, size: 14),
                label: const Text(
                  'Manage',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => SubscriptionBotSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Obx(
                    () => controller.isScanning.value
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.radar_outlined,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                  ),
                  label: Obx(
                    () => Text(
                      controller.isScanning.value
                          ? 'Scanning...'
                          : 'Scan Recurring Charges',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => controller.scanRecurringCharges(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text(
                    'Open Bot Terminal',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.8),
                    foregroundColor: colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => SubscriptionBotSheet.show(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
