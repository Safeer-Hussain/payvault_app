import 'package:flutter_test/flutter_test.dart';
import 'package:pay_vault/domain/entities/savings_vault_entity.dart';

import '../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSavingsVaultRepository fakeSavingsRepo;

  setUp(() {
    fakeSavingsRepo = FakeSavingsVaultRepository();
  });

  group('SavingsVaultEntity Math & Logic Tests', () {
    test('Calculates spare change roundup to the nearest dollar correctly', () {
      const entity = SavingsVaultEntity(
        id: 'sv_test',
        name: 'Spare Change Vault',
        currency: 'USD',
        balance: 100.0,
        apy: 4.5,
        isRoundupEnabled: true,
        roundupMultiplier: 1,
        totalRoundupsCount: 10,
        totalSaved: 100.0,
        lastRoundupTimestamp: 1700000000,
      );

      // $14.30 -> ceil is $15.00 -> roundup = $0.70
      expect(entity.calculateRoundup(14.30), equals(0.70));

      // $19.99 -> ceil is $20.00 -> roundup = $0.01
      expect(entity.calculateRoundup(19.99), equals(0.01));

      // $0.05 -> ceil is $1.00 -> roundup = $0.95
      expect(entity.calculateRoundup(0.05), equals(0.95));

      // Whole integer amount: $15.00 -> ceil is $15.00 -> roundup = $0.0
      expect(entity.calculateRoundup(15.00), equals(0.0));

      // Zero or negative amounts return 0.0
      expect(entity.calculateRoundup(0.0), equals(0.0));
      expect(entity.calculateRoundup(-12.50), equals(0.0));
    });

    test('Applies roundup multipliers (2x, 3x, 5x) accurately', () {
      const baseEntity = SavingsVaultEntity(
        id: 'sv_test',
        name: 'Spare Change Vault',
        currency: 'USD',
        balance: 100.0,
        apy: 4.5,
        isRoundupEnabled: true,
        roundupMultiplier: 1,
        totalRoundupsCount: 10,
        totalSaved: 100.0,
        lastRoundupTimestamp: 1700000000,
      );

      // At 2x: $14.30 (diff 0.70) * 2 = $1.40
      final entity2x = baseEntity.copyWith(roundupMultiplier: 2);
      expect(entity2x.calculateRoundup(14.30), equals(1.40));

      // At 3x: $14.30 (diff 0.70) * 3 = $2.10
      final entity3x = baseEntity.copyWith(roundupMultiplier: 3);
      expect(entity3x.calculateRoundup(14.30), equals(2.10));

      // At 5x: $14.30 (diff 0.70) * 5 = $3.50
      final entity5x = baseEntity.copyWith(roundupMultiplier: 5);
      expect(entity5x.calculateRoundup(14.30), equals(3.50));
    });

    test('Returns 0.0 when auto-roundup is disabled', () {
      const disabledEntity = SavingsVaultEntity(
        id: 'sv_test',
        name: 'Spare Change Vault',
        currency: 'USD',
        balance: 100.0,
        apy: 4.5,
        isRoundupEnabled: false,
        roundupMultiplier: 2,
        totalRoundupsCount: 10,
        totalSaved: 100.0,
        lastRoundupTimestamp: 1700000000,
      );

      expect(disabledEntity.calculateRoundup(14.30), equals(0.0));
      expect(disabledEntity.calculateRoundup(99.01), equals(0.0));
    });
  });

  group('SavingsVaultRepository Unit Tests', () {
    test('Loads initial savings vault entity with valid state', () async {
      final vault = await fakeSavingsRepo.getSavingsVault();
      expect(vault.id, equals('sv_spare_change'));
      expect(vault.balance, equals(348.65));
      expect(vault.apy, equals(4.5));
      expect(vault.isRoundupEnabled, isTrue);
      expect(vault.roundupMultiplier, equals(1));
    });

    test('Updates roundup settings atomically', () async {
      final updated = await fakeSavingsRepo.updateRoundupSettings(
        isEnabled: false,
        multiplier: 5,
      );

      expect(updated.isRoundupEnabled, isFalse);
      expect(updated.roundupMultiplier, equals(5));

      final persisted = await fakeSavingsRepo.getSavingsVault();
      expect(persisted.isRoundupEnabled, isFalse);
      expect(persisted.roundupMultiplier, equals(5));
    });

    test('Executes roundup transfer and increments metrics', () async {
      final initial = await fakeSavingsRepo.getSavingsVault();
      const roundupAmount = 0.70;

      await fakeSavingsRepo.executeRoundupTransfer(
        sourceCurrency: 'USD',
        roundupAmount: roundupAmount,
        originalTxId: 'tx_original_01',
      );

      final updated = await fakeSavingsRepo.getSavingsVault();
      expect(updated.balance, closeTo(initial.balance + roundupAmount, 0.001));
      expect(
        updated.totalSaved,
        closeTo(initial.totalSaved + roundupAmount, 0.001),
      );
      expect(
        updated.totalRoundupsCount,
        equals(initial.totalRoundupsCount + 1),
      );
    });

    test('Withdraws funds and throws on overdraft attempt', () async {
      final initial = await fakeSavingsRepo.getSavingsVault();
      const withdrawAmount = 50.0;

      await fakeSavingsRepo.withdrawToWallet(
        amount: withdrawAmount,
        targetCurrency: 'USD',
      );

      final afterWithdraw = await fakeSavingsRepo.getSavingsVault();
      expect(
        afterWithdraw.balance,
        closeTo(initial.balance - withdrawAmount, 0.001),
      );

      // Attempting to withdraw more than remaining balance must throw
      expect(
        () => fakeSavingsRepo.withdrawToWallet(
          amount: 50000.0,
          targetCurrency: 'USD',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
