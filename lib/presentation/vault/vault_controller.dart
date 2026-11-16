import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/savings_vault_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/savings_vault_repository.dart';
import '../../domain/repositories/vault_repository.dart';

class VaultController extends GetxController {
  final VaultRepository _vaultRepository;
  final SavingsVaultRepository _savingsVaultRepository;

  VaultController(this._vaultRepository, this._savingsVaultRepository);

  final RxList<WalletEntity> wallets = <WalletEntity>[].obs;
  final RxList<TransactionEntity> recentTransactions =
      <TransactionEntity>[].obs;
  final Rx<SavingsVaultEntity?> savingsVault = Rx<SavingsVaultEntity?>(null);
  final RxString selectedCurrency = 'USD'.obs;
  final RxBool isLoading = false.obs;

  // Currency Exchange State
  final RxString sourceCurrency = 'USD'.obs;
  final RxString targetCurrency = 'EUR'.obs;
  final RxDouble exchangeAmount = 1000.0.obs;
  final TextEditingController amountController = TextEditingController(
    text: '1000',
  );

  @override
  void onInit() {
    super.onInit();
    loadVaultData();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  Future<void> loadVaultData() async {
    isLoading.value = true;
    try {
      final loadedWallets = await _vaultRepository.getWallets();
      final loadedTx = await _vaultRepository.getRecentTransactions(limit: 6);
      final loadedSavings = await _savingsVaultRepository.getSavingsVault();
      wallets.assignAll(loadedWallets);
      recentTransactions.assignAll(loadedTx);
      savingsVault.value = loadedSavings;
    } catch (e) {
      AppFeedback.showError(message: 'Failed to load vault data: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  WalletEntity? get currentWallet {
    return wallets.firstWhereOrNull(
          (w) => w.currency == selectedCurrency.value,
        ) ??
        (wallets.isNotEmpty ? wallets.first : null);
  }

  double get totalNetWorthUsd {
    double total = 0.0;
    for (final w in wallets) {
      total += w.balanceInUsd;
    }
    if (savingsVault.value != null) {
      // Savings vault is USD denominated
      total += savingsVault.value!.balance;
    }
    return total;
  }

  void selectCurrency(String currency) {
    selectedCurrency.value = currency;
    update();
  }

  // FX Calculation
  double get conversionRate {
    final src = wallets.firstWhereOrNull(
      (w) => w.currency == sourceCurrency.value,
    );
    final tgt = wallets.firstWhereOrNull(
      (w) => w.currency == targetCurrency.value,
    );
    if (src == null || tgt == null || tgt.exchangeRateToUsd == 0) return 1.0;
    return src.exchangeRateToUsd / tgt.exchangeRateToUsd;
  }

  double get calculatedTargetAmount {
    return exchangeAmount.value * conversionRate;
  }

  double get transparentFeeAmount {
    return exchangeAmount.value * 0.001; // 0.1% transparent spread
  }

  Future<bool> executeExchange() async {
    final src = wallets.firstWhereOrNull(
      (w) => w.currency == sourceCurrency.value,
    );
    if (src == null) {
      AppFeedback.showError(message: 'Invalid source currency selected');
      return false;
    }

    final totalDeduction = exchangeAmount.value + transparentFeeAmount;
    if (src.balance < totalDeduction) {
      AppFeedback.showError(
        message:
            'Insufficient balance in ${sourceCurrency.value} vault. Required: ${totalDeduction.toStringAsFixed(2)} ${sourceCurrency.value}',
      );
      return false;
    }

    try {
      await _vaultRepository.executeCurrencyExchange(
        sourceCurrency: sourceCurrency.value,
        targetCurrency: targetCurrency.value,
        sourceAmount: exchangeAmount.value,
        targetAmount: calculatedTargetAmount,
        feeAmount: transparentFeeAmount,
      );

      await loadVaultData();
      AppFeedback.showSuccess(
        title: 'FX Swap Executed',
        message:
            'Exchanged ${exchangeAmount.value.toStringAsFixed(2)} ${sourceCurrency.value} for ${calculatedTargetAmount.toStringAsFixed(2)} ${targetCurrency.value}',
      );
      return true;
    } catch (e) {
      AppFeedback.showError(message: 'Exchange failed: $e');
      return false;
    }
  }

  // Spare Change Savings Vault Operations
  Future<void> toggleAutoRoundup(bool enabled) async {
    final current = savingsVault.value;
    final multiplier = current?.roundupMultiplier ?? 1;
    try {
      final updated = await _savingsVaultRepository.updateRoundupSettings(
        isEnabled: enabled,
        multiplier: multiplier,
      );
      savingsVault.value = updated;
      update();
      AppFeedback.showInfo(
        message: enabled
            ? 'Auto-Roundup Active (${multiplier}x multiplier)'
            : 'Auto-Roundup Paused',
      );
    } catch (e) {
      AppFeedback.showError(message: 'Failed to update roundup settings: $e');
    }
  }

  Future<void> setRoundupMultiplier(int multiplier) async {
    final current = savingsVault.value;
    final isEnabled = current?.isRoundupEnabled ?? true;
    try {
      final updated = await _savingsVaultRepository.updateRoundupSettings(
        isEnabled: isEnabled,
        multiplier: multiplier,
      );
      savingsVault.value = updated;
      update();
      AppFeedback.showInfo(message: 'Roundup multiplier set to ${multiplier}x');
    } catch (e) {
      AppFeedback.showError(message: 'Failed to set multiplier: $e');
    }
  }

  Future<bool> withdrawSavings({
    required double amount,
    required String targetCurrency,
  }) async {
    try {
      await _savingsVaultRepository.withdrawToWallet(
        amount: amount,
        targetCurrency: targetCurrency,
      );
      await loadVaultData();
      AppFeedback.showSuccess(
        title: 'Savings Transferred',
        message:
            'Transferred \$${amount.toStringAsFixed(2)} from Spare Change Vault to $targetCurrency primary vault',
      );
      return true;
    } catch (e) {
      AppFeedback.showError(message: 'Withdrawal failed: $e');
      return false;
    }
  }

  Future<bool> simulateDebitWithRoundup({
    double spendAmount = 14.30,
    String currency = 'USD',
  }) async {
    final current = savingsVault.value;
    if (current == null) return false;

    final roundup = current.calculateRoundup(spendAmount);
    final wallet = wallets.firstWhereOrNull((w) => w.currency == currency);
    if (wallet == null) {
      AppFeedback.showError(message: 'Wallet $currency not found');
      return false;
    }

    if (wallet.balance < (spendAmount + roundup)) {
      AppFeedback.showError(
        message:
            'Insufficient balance in $currency wallet for debit and roundup',
      );
      return false;
    }

    try {
      // 1. Deduct primary spend from wallet
      await _vaultRepository.updateWalletBalance(
        currency,
        wallet.balance - spendAmount,
      );

      // 2. Transfer roundup to savings vault if applicable
      if (roundup > 0) {
        await _savingsVaultRepository.executeRoundupTransfer(
          sourceCurrency: currency,
          roundupAmount: roundup,
          originalTxId: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      await loadVaultData();
      final totalDebited = spendAmount + roundup;
      AppFeedback.showSuccess(
        title: 'Auto-Roundup Executed',
        message:
            'Debited \$${spendAmount.toStringAsFixed(2)}, rounded up to \$${totalDebited.toStringAsFixed(2)} (+\$${roundup.toStringAsFixed(2)} to Savings Vault)',
      );
      return true;
    } catch (e) {
      AppFeedback.showError(message: 'Simulation failed: $e');
      return false;
    }
  }
}
