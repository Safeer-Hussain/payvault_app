import '../entities/savings_vault_entity.dart';

abstract class SavingsVaultRepository {
  Future<SavingsVaultEntity> getSavingsVault();

  Future<SavingsVaultEntity> updateRoundupSettings({
    required bool isEnabled,
    required int multiplier,
  });

  Future<void> executeRoundupTransfer({
    required String sourceCurrency,
    required double roundupAmount,
    required String originalTxId,
  });

  Future<void> withdrawToWallet({
    required double amount,
    required String targetCurrency,
  });

  Future<void> depositToSavings({
    required double amount,
    required String sourceCurrency,
  });
}
