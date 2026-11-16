import 'package:flutter_test/flutter_test.dart';
import 'package:pay_vault/presentation/vault/vault_controller.dart';

import '../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultRepository fakeVaultRepo;
  late FakeSavingsVaultRepository fakeSavingsVaultRepo;
  late VaultController controller;

  setUp(() {
    fakeVaultRepo = FakeVaultRepository();
    fakeSavingsVaultRepo = FakeSavingsVaultRepository();
    controller = VaultController(fakeVaultRepo, fakeSavingsVaultRepo);
  });

  tearDown(() {
    controller.onClose();
  });

  group('VaultController Unit Tests', () {
    test('Calculates total liquid net worth in USD accurately across multi-currency vaults plus savings vault', () async {
      await controller.loadVaultData();

      // USD: 10000 * 1.0 = 10000
      // EUR: 5000 * 1.10 = 5500
      // GBP: 2000 * 1.25 = 2500
      // Savings Vault: 348.65
      // Total = 18348.65 USD
      expect(controller.totalNetWorthUsd, equals(18348.65));
      expect(controller.wallets.length, equals(3));
      expect(controller.savingsVault.value?.balance, equals(348.65));
    });

    test('Switches active selected currency vault', () async {
      await controller.loadVaultData();
      expect(controller.selectedCurrency.value, equals('USD'));

      controller.selectCurrency('EUR');
      expect(controller.selectedCurrency.value, equals('EUR'));
      expect(controller.currentWallet?.currency, equals('EUR'));
    });

    test(
      'Calculates transparent 0.1% FX spread fee and target amount',
      () async {
        await controller.loadVaultData();
        controller.sourceCurrency.value = 'USD';
        controller.targetCurrency.value = 'EUR';
        controller.exchangeAmount.value = 1000.0;

        // Fee: 1000 * 0.001 = 1.0
        expect(controller.transparentFeeAmount, equals(1.0));

        // Conversion rate: 1.0 / 1.10
        final expectedTarget = 1000.0 * (1.0 / 1.10);
        expect(
          controller.calculatedTargetAmount,
          closeTo(expectedTarget, 0.01),
        );
      },
    );

    test('Executes FX swap deducting source vault balance and crediting target vault', () async {
      await controller.loadVaultData();
      controller.sourceCurrency.value = 'USD';
      controller.targetCurrency.value = 'EUR';
      controller.exchangeAmount.value = 1000.0;

      final success = await controller.executeExchange();
      expect(success, isTrue);

      // USD: 10000 - (1000 + 1) = 8999.0
      final usdWallet = await fakeVaultRepo.getWalletByCurrency('USD');
      expect(usdWallet?.balance, equals(8999.0));

      // EUR: 5000 + (1000 * (1.0 / 1.10))
      final eurWallet = await fakeVaultRepo.getWalletByCurrency('EUR');
      final expectedEur = 5000.0 + (1000.0 * (1.0 / 1.10));
      expect(eurWallet?.balance, closeTo(expectedEur, 0.01));
    });

    test('Toggles auto-roundup active status and updates multiplier', () async {
      await controller.loadVaultData();
      expect(controller.savingsVault.value?.isRoundupEnabled, isTrue);

      await controller.toggleAutoRoundup(false);
      expect(controller.savingsVault.value?.isRoundupEnabled, isFalse);

      await controller.setRoundupMultiplier(3);
      expect(controller.savingsVault.value?.roundupMultiplier, equals(3));
    });

    test(
      'Withdraws savings from Spare Change Vault to primary wallet',
      () async {
        await controller.loadVaultData();
        final initialSavings = controller.savingsVault.value!.balance;
        const withdrawalAmount = 100.0;

        final success = await controller.withdrawSavings(
          amount: withdrawalAmount,
          targetCurrency: 'USD',
        );

        expect(success, isTrue);
        expect(
          controller.savingsVault.value?.balance,
          equals(initialSavings - withdrawalAmount),
        );
      },
    );

    test(
      'Simulates debit transaction with spare change auto-roundup',
      () async {
        await controller.loadVaultData();
        final initialSavings = controller.savingsVault.value!.balance;
        final initialUsd = controller.currentWallet!.balance;

        // Spend 14.30 USD -> round up to nearest $1: diff = 0.70 USD
        final success = await controller.simulateDebitWithRoundup(
          spendAmount: 14.30,
          currency: 'USD',
        );

        expect(success, isTrue);
        // Wallet should have spent 14.30
        final usdWallet = await fakeVaultRepo.getWalletByCurrency('USD');
        expect(usdWallet?.balance, equals(initialUsd - 14.30));

        // Savings vault should have gained 0.70
        expect(
          controller.savingsVault.value?.balance,
          closeTo(initialSavings + 0.70, 0.001),
        );
      },
    );
  });
}
