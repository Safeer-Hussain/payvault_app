import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/statement_export_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/statement_repository.dart';
import '../../domain/repositories/transfer_repository.dart';

class LedgerController extends GetxController {
  final TransferRepository _transferRepository;
  final StatementRepository _statementRepository;

  LedgerController(this._transferRepository, this._statementRepository);

  final RxList<TransactionEntity> transactions = <TransactionEntity>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  // Statement Export & Cryptographic Verification State
  final RxBool isExportingStatement = false.obs;
  final Rx<StatementExportEntity?> lastExportedStatement =
      Rx<StatementExportEntity?>(null);
  final RxString selectedStatementCurrency = 'USD'.obs;
  final Rx<DateTime> selectedStatementMonth = DateTime(2026, 11).obs;

  final List<String> categories = [
    'All',
    'Shopping',
    'Dining',
    'Tech/Cloud',
    'Travel',
    'Salary',
    'Investment',
    'Savings',
  ];

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadTransactions() async {
    isLoading.value = true;
    try {
      final loaded = await _transferRepository.getTransactions(
        category: selectedCategory.value,
        searchQuery: searchQuery.value,
      );
      transactions.assignAll(loaded);
    } catch (e) {
      AppFeedback.showError(message: 'Failed to load ledger: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void filterByCategory(String cat) {
    selectedCategory.value = cat;
    loadTransactions();
  }

  void search(String query) {
    searchQuery.value = query;
    loadTransactions();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadTransactions();
  }

  // Analytics Computation
  Map<String, double> get categoryBreakdown {
    final Map<String, double> breakdown = {};
    for (final tx in transactions) {
      if (!tx.isCredit) {
        breakdown[tx.category] = (breakdown[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return breakdown;
  }

  double get totalDebits {
    double sum = 0.0;
    for (final tx in transactions) {
      if (!tx.isCredit) sum += tx.amount;
    }
    return sum;
  }

  double get totalCredits {
    double sum = 0.0;
    for (final tx in transactions) {
      if (tx.isCredit) sum += tx.amount;
    }
    return sum;
  }

  List<double> get weeklyBurnData {
    return [1240.0, 1890.50, 940.20, 1280.0];
  }

  void simulateDownloadReceipt(TransactionEntity tx) {
    AppFeedback.showSuccess(
      title: 'Cryptographic Receipt Exported',
      message: 'Downloaded SHA256-sealed PDF receipt for ${tx.referenceId}',
    );
  }

  // Monthly Statement Generation with Hardware Enclave Seal
  Future<StatementExportEntity?> generateAndExportStatement({
    DateTime? month,
    String? currency,
  }) async {
    isExportingStatement.value = true;
    update();

    try {
      final targetMonth = month ?? selectedStatementMonth.value;
      final targetCurrency = currency ?? selectedStatementCurrency.value;

      final statement = await _statementRepository.generateStatement(
        periodMonth: targetMonth,
        currency: targetCurrency,
      );

      final filePath = await _statementRepository.saveStatementPdf(statement);
      lastExportedStatement.value = statement;

      AppFeedback.showSuccess(
        title: 'Cryptographic Statement Generated',
        message:
            'Statement ${statement.id} verified with SHA-256 seal & saved to $filePath',
      );
      return statement;
    } catch (e) {
      AppFeedback.showError(message: 'Statement generation failed: $e');
      return null;
    } finally {
      isExportingStatement.value = false;
      update();
    }
  }

  Future<bool> verifyStatementSeal(StatementExportEntity statement) async {
    try {
      final isValid = await _statementRepository.verifyStatementIntegrity(
        statementId: statement.id,
        digitalSignature: statement.digitalSignature,
        payloadHash: statement.payloadHash,
      );

      if (isValid) {
        AppFeedback.showSuccess(
          title: 'Signature Validated',
          message:
              'Cryptographic KeyStore seal ${statement.digitalSignature} is authentic & un-tampered',
        );
      } else {
        AppFeedback.showError(
          message: 'Cryptographic verification failed: Seal mismatch detected',
        );
      }
      return isValid;
    } catch (e) {
      AppFeedback.showError(message: 'Verification check failed: $e');
      return false;
    }
  }
}
