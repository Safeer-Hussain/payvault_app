import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../ledger_controller.dart';
import 'statement_verification_dialog.dart';

class StatementExportSheet extends StatefulWidget {
  final LedgerController controller;

  const StatementExportSheet({super.key, required this.controller});

  @override
  State<StatementExportSheet> createState() => _StatementExportSheetState();
}

class _StatementExportSheetState extends State<StatementExportSheet> {
  late DateTime _selectedMonth;
  late String _selectedCurrency;

  final List<DateTime> _availableMonths = [
    DateTime(2026, 11),
    DateTime(2026, 10),
    DateTime(2026, 9),
  ];

  final List<String> _currencies = ['USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.controller.selectedStatementMonth.value;
    _selectedCurrency = widget.controller.selectedStatementCurrency.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
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
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Cryptographic Statement',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Hardware Enclave Signed • SHA-256 Verified',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Statement Period Selector
              Text(
                'STATEMENT BILLING PERIOD',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableMonths.map((m) {
                  final isSelected =
                      _selectedMonth.year == m.year &&
                      _selectedMonth.month == m.month;
                  final label = DateFormat('MMMM yyyy').format(m);
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedMonth = m);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Currency Selector
              Text(
                'SETTLEMENT VAULT CURRENCY',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _currencies.map((curr) {
                  final isSelected = _selectedCurrency == curr;
                  return ChoiceChip(
                    label: Text(curr),
                    selected: isSelected,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCurrency = curr);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Security & Seal Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Cryptographic Watermark',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Generates a hardware-signed %PDF-1.4 ledger statement with embedded QR verification watermark and SHA-256 seal.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Export Button
              Obx(() {
                final isProcessing = controller.isExportingStatement.value;
                return SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    icon: isProcessing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isProcessing
                            ? 'Compiling Cryptographic Statement...'
                            : 'Generate & Export Sealed PDF',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final statement = await controller
                                .generateAndExportStatement(
                                  month: _selectedMonth,
                                  currency: _selectedCurrency,
                                );
                            if (statement != null && context.mounted) {
                              Navigator.of(context).pop();
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => StatementVerificationDialog(
                                  statement: statement,
                                  controller: controller,
                                ),
                              );
                            }
                          },
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
