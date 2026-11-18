import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../subscription_controller.dart';

class CancellationNoticeDialog extends StatefulWidget {
  final SubscriptionEntity subscription;

  const CancellationNoticeDialog({super.key, required this.subscription});

  @override
  State<CancellationNoticeDialog> createState() =>
      _CancellationNoticeDialogState();
}

class _CancellationNoticeDialogState extends State<CancellationNoticeDialog> {
  final List<String> _reasons = [
    'Consolidation of operational recurring expenditures',
    'Found cost-effective alternative',
    'Service no longer required',
    'Budget reallocation & treasury governance',
    'Licensing audit adjustment',
  ];

  late String _selectedReason;
  late String _currentNotice;

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.subscription.cancellationReason ?? _reasons.first;
    _updateNotice();
  }

  void _updateNotice() {
    final controller = Get.find<SubscriptionController>();
    if (widget.subscription.isCancelled &&
        widget.subscription.cancellationNotice != null) {
      _currentNotice = widget.subscription.cancellationNotice!;
    } else {
      _currentNotice = controller.previewNotice(
        widget.subscription,
        reason: _selectedReason,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<SubscriptionController>();
    final isAlreadyCancelled = widget.subscription.isCancelled;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAlreadyCancelled
                          ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                          : colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAlreadyCancelled
                          ? Icons.verified_user_outlined
                          : Icons.cancel_outlined,
                      color: isAlreadyCancelled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAlreadyCancelled
                              ? 'EXECUTED CANCELLATION NOTICE'
                              : 'AI VENDOR CANCELLATION BOT',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subscription.merchantName,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
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
              const SizedBox(height: 16),

              // Reason dropdown if not yet cancelled
              if (!isAlreadyCancelled) ...[
                Text(
                  'CANCELLATION REASON',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedReason,
                      isExpanded: true,
                      dropdownColor: colorScheme.surfaceContainerHighest,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: colorScheme.onSurface,
                      ),
                      items: _reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            r,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedReason = val;
                            _updateNotice();
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Monospace Notice Body
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _currentNotice,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        height: 1.45,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy Notice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentNotice));
                      AppFeedback.showInfo(
                        title: 'Notice Copied',
                        message: 'Cancellation notice copied to clipboard.',
                      );
                    },
                  ),
                  if (!isAlreadyCancelled)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined, size: 14),
                      label: const Text('Transmit & Cancel Mandate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await controller.cancelSubscriptionWithBot(
                          widget.subscription,
                          reason: _selectedReason,
                        );
                      },
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
