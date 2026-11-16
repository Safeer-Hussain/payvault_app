import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_feedback.dart';
import '../vault_controller.dart';

class SpareChangeVaultCard extends StatelessWidget {
  const SpareChangeVaultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = Get.find<VaultController>();

    return Obx(() {
      final vault = controller.savingsVault.value;
      if (vault == null) {
        return const SizedBox.shrink();
      }

      final isEnabled = vault.isRoundupEnabled;
      final currentMultiplier = vault.roundupMultiplier;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled
                ? colorScheme.primary.withValues(alpha: 0.35)
                : colorScheme.outlineVariant,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Vault Title & APY Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vault.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Auto-Spare Change Micro-Yield',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 13,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${vault.apy}% APY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balance & Stats Section
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$${vault.balance.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vault.currency,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lifetime Saved: \$${vault.totalSaved.toStringAsFixed(2)} • ${vault.totalRoundupsCount} roundups',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Divider
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 10),

            // Auto-Roundup Switch Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Roundup',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        isEnabled
                            ? 'Rounding debit transactions to nearest \$1'
                            : 'Auto-roundup is currently paused',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isEnabled,
                  activeTrackColor: colorScheme.primary,
                  onChanged: (val) => controller.toggleAutoRoundup(val),
                ),
              ],
            ),

            if (isEnabled) ...[
              const SizedBox(height: 8),
              // Multiplier Selector Chips (Wrap for responsiveness)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Multiplier:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  for (final multiplier in [1, 2, 3, 5])
                    ChoiceChip(
                      label: Text('${multiplier}x'),
                      selected: currentMultiplier == multiplier,
                      selectedColor: colorScheme.primaryContainer,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: currentMultiplier == multiplier
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentMultiplier == multiplier
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (_) {
                        controller.setRoundupMultiplier(multiplier);
                      },
                    ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Responsive Action Buttons (Wrap with runSpacing for narrow viewport immunity)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 120,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_upward_outlined, size: 14),
                    label: const Text(
                      'Withdraw',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showWithdrawalSheet(context, controller),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome_outlined, size: 14),
                    label: const Text(
                      'Simulate \$14.30',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      controller.simulateDebitWithRoundup(
                        spendAmount: 14.30,
                        currency: 'USD',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showWithdrawalSheet(BuildContext context, VaultController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountTextController = TextEditingController(text: '50.00');
    final selectedTargetCurrency = 'USD'.obs;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Withdraw Savings to Primary Vault',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Available in Spare Change Vault: \$${controller.savingsVault.value?.balance.toStringAsFixed(2) ?? '0.00'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Amount TextField
                  TextField(
                    controller: amountTextController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Withdrawal Amount',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Target Vault Selector
                  Text(
                    'Destination Currency Vault',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    return Wrap(
                      spacing: 8,
                      children: ['USD', 'EUR', 'GBP'].map((curr) {
                        final isSel = selectedTargetCurrency.value == curr;
                        return ChoiceChip(
                          label: Text(curr),
                          selected: isSel,
                          onSelected: (_) {
                            selectedTargetCurrency.value = curr;
                          },
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final amount = double.tryParse(
                          amountTextController.text.trim(),
                        );
                        if (amount == null || amount <= 0) {
                          AppFeedback.showError(
                            message: 'Please enter a valid withdrawal amount',
                          );
                          return;
                        }
                        final available =
                            controller.savingsVault.value?.balance ?? 0.0;
                        if (amount > available) {
                          AppFeedback.showError(
                            message:
                                'Withdrawal exceeds available balance (\$${available.toStringAsFixed(2)})',
                          );
                          return;
                        }

                        Navigator.of(ctx).pop();
                        await controller.withdrawSavings(
                          amount: amount,
                          targetCurrency: selectedTargetCurrency.value,
                        );
                      },
                      child: const Text(
                        'Confirm Withdrawal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
