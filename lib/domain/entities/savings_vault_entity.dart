class SavingsVaultEntity {
  final String id;
  final String name;
  final String currency;
  final double balance;
  final double apy;
  final bool isRoundupEnabled;
  final int roundupMultiplier;
  final int totalRoundupsCount;
  final double totalSaved;
  final int lastRoundupTimestamp;

  const SavingsVaultEntity({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.apy,
    required this.isRoundupEnabled,
    required this.roundupMultiplier,
    required this.totalRoundupsCount,
    required this.totalSaved,
    required this.lastRoundupTimestamp,
  });

  /// Calculates spare change roundup to the nearest whole integer of the currency unit.
  /// If amount is whole integer, roundup is 0.0.
  /// Result is multiplied by [roundupMultiplier] and rounded to 2 decimal places.
  double calculateRoundup(double amount) {
    if (!isRoundupEnabled || amount <= 0) return 0.0;
    final ceil = amount.ceilToDouble();
    final diff = ceil > amount ? (ceil - amount) : 0.0;
    if (diff == 0.0) return 0.0;
    final total = diff * roundupMultiplier;
    return double.parse(total.toStringAsFixed(2));
  }

  SavingsVaultEntity copyWith({
    String? id,
    String? name,
    String? currency,
    double? balance,
    double? apy,
    bool? isRoundupEnabled,
    int? roundupMultiplier,
    int? totalRoundupsCount,
    double? totalSaved,
    int? lastRoundupTimestamp,
  }) {
    return SavingsVaultEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      apy: apy ?? this.apy,
      isRoundupEnabled: isRoundupEnabled ?? this.isRoundupEnabled,
      roundupMultiplier: roundupMultiplier ?? this.roundupMultiplier,
      totalRoundupsCount: totalRoundupsCount ?? this.totalRoundupsCount,
      totalSaved: totalSaved ?? this.totalSaved,
      lastRoundupTimestamp: lastRoundupTimestamp ?? this.lastRoundupTimestamp,
    );
  }
}
