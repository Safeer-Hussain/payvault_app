import '../../domain/entities/savings_vault_entity.dart';

class SavingsVaultModel extends SavingsVaultEntity {
  const SavingsVaultModel({
    required super.id,
    required super.name,
    required super.currency,
    required super.balance,
    required super.apy,
    required super.isRoundupEnabled,
    required super.roundupMultiplier,
    required super.totalRoundupsCount,
    required super.totalSaved,
    required super.lastRoundupTimestamp,
  });

  factory SavingsVaultModel.fromMap(Map<String, dynamic> map) {
    return SavingsVaultModel(
      id: map['id'] as String,
      name: map['name'] as String,
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
      apy: (map['apy'] as num).toDouble(),
      isRoundupEnabled: (map['isRoundupEnabled'] as int) == 1,
      roundupMultiplier: map['roundupMultiplier'] as int,
      totalRoundupsCount: map['totalRoundupsCount'] as int,
      totalSaved: (map['totalSaved'] as num).toDouble(),
      lastRoundupTimestamp: map['lastRoundupTimestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'balance': balance,
      'apy': apy,
      'isRoundupEnabled': isRoundupEnabled ? 1 : 0,
      'roundupMultiplier': roundupMultiplier,
      'totalRoundupsCount': totalRoundupsCount,
      'totalSaved': totalSaved,
      'lastRoundupTimestamp': lastRoundupTimestamp,
    };
  }
}
