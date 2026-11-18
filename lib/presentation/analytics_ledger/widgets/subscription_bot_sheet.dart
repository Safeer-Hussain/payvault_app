import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/subscription_entity.dart';
import '../subscription_controller.dart';
import 'cancellation_notice_dialog.dart';

class SubscriptionBotSheet extends StatelessWidget {
  const SubscriptionBotSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionBotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<SubscriptionController>();
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.95
            : mediaQuery.size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUTONOMOUS FINTECH BOT',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Subscription Cancellation Bot',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metrics Strip
                    Obx(
                      () => _buildMetricsCard(context, colorScheme, controller),
                    ),
                    const SizedBox(height: 12),

                    // Scan & Trigger Action
                    Obx(
                      () => OutlinedButton.icon(
                        icon: controller.isScanning.value
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.radar_outlined,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                        label: Text(
                          controller.isScanning.value
                              ? 'Scanning Ledger Records...'
                              : 'Scan Ledger for Recurring Merchant Charges',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: controller.isScanning.value
                            ? null
                            : () => controller.scanRecurringCharges(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips
                    Obx(
                      () => _buildFilterChips(context, colorScheme, controller),
                    ),
                    const SizedBox(height: 14),

                    // Subscription Items
                    Obx(() {
                      final items = controller.filteredSubscriptions;
                      if (items.isEmpty) {
                        return _buildEmptyState(context, colorScheme);
                      }
                      return Column(
                        children: items.map((sub) {
                          return _buildSubscriptionCard(
                            context,
                            colorScheme,
                            controller,
                            sub,
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(
    BuildContext context,
    ColorScheme colorScheme,
    SubscriptionController controller,
  ) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final monthly = currencyFormatter.format(controller.totalMonthlySpend);
    final annual = currencyFormatter.format(controller.annualizedRunRate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTHLY BURN',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    monthly,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANNUAL RUN RATE',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      annual,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE SUBS',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${controller.activeCount} Subscriptions',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    ColorScheme colorScheme,
    SubscriptionController controller,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: controller.filterOptions.map((filter) {
          final isSelected = controller.selectedFilter.value == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              onSelected: (_) => controller.setFilter(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    ColorScheme colorScheme,
    SubscriptionController controller,
    SubscriptionEntity sub,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final nextDate = dateFormat.format(sub.nextBillingDate);
    final daysUntil = sub.nextBillingDate.difference(DateTime.now()).inDays;

    final Color statusColor;
    final String statusLabel;
    if (sub.isCancelled) {
      statusColor = colorScheme.outlineVariant;
      statusLabel = 'CANCELLED';
    } else if (sub.isFrozen) {
      statusColor = Colors.orangeAccent;
      statusLabel = 'FROZEN';
    } else {
      statusColor = colorScheme.primary;
      statusLabel = 'ACTIVE';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sub.isFrozen
              ? Colors.orangeAccent.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Avatar + Title + Status + Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(sub.category),
                  color: colorScheme.onSurface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.merchantName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sub.category} • Ref: ${sub.accountReference}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sub.currency} ${sub.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata row: next renewal + payment instrument
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sub.isCancelled
                      ? 'Revoked • No future debits scheduled'
                      : 'Next debit: $nextDate (${daysUntil > 0 ? '$daysUntil days' : 'due today'})',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (!sub.isCancelled) ...[
                // Freeze / Unfreeze
                OutlinedButton.icon(
                  icon: Icon(
                    sub.isFrozen
                        ? Icons.play_arrow_outlined
                        : Icons.pause_circle_outline,
                    size: 14,
                  ),
                  label: Text(
                    sub.isFrozen ? 'Resume Mandate' : 'Hold / Freeze',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => controller.toggleFreeze(sub),
                ),
                // Cancel with Bot
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text(
                    'Cancel with Bot',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error.withValues(alpha: 0.9),
                    foregroundColor: colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          CancellationNoticeDialog(subscription: sub),
                    );
                  },
                ),
              ] else ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined, size: 14),
                  label: const Text(
                    'View Cancellation Notice',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          CancellationNoticeDialog(subscription: sub),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 38,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'No Subscriptions Matching Filter',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select "All" or scan the transaction ledger to refresh.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cloud infrastructure':
      case 'tech/cloud':
        return Icons.cloud_outlined;
      case 'financial intelligence':
        return Icons.insights_outlined;
      case 'streaming media':
        return Icons.movie_outlined;
      case 'developer tools':
        return Icons.code_outlined;
      case 'ai services':
        return Icons.psychology_outlined;
      case 'audio entertainment':
        return Icons.headphones_outlined;
      default:
        return Icons.credit_card_outlined;
    }
  }
}
