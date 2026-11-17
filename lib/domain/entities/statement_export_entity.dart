import 'package:intl/intl.dart';

import '../../core/crypto/statement_seal_service.dart';
import 'transaction_entity.dart';

class StatementExportEntity {
  final String id;
  final String period;
  final DateTime generatedAt;
  final String accountHolder;
  final String accountNumber;
  final String currency;
  final double openingBalance;
  final double closingBalance;
  final double totalDebits;
  final double totalCredits;
  final List<TransactionEntity> transactions;
  final String payloadHash;
  final String digitalSignature;
  final String verificationQrPayload;
  final String sealWatermark;
  final List<int> pdfBytes;

  const StatementExportEntity({
    required this.id,
    required this.period,
    required this.generatedAt,
    required this.accountHolder,
    required this.accountNumber,
    required this.currency,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDebits,
    required this.totalCredits,
    required this.transactions,
    required this.payloadHash,
    required this.digitalSignature,
    required this.verificationQrPayload,
    required this.sealWatermark,
    required this.pdfBytes,
  });

  String get formattedGeneratedDate =>
      DateFormat('MMM dd, yyyy • HH:mm:ss').format(generatedAt);

  String get formattedShortGeneratedDate =>
      DateFormat('MMM dd, yyyy').format(generatedAt);

  int get transactionCount => transactions.length;

  /// Cryptographically verifies the statement's digital seal.
  bool verifyIntegrity() {
    return StatementSealService.verifySignature(
      payloadHash: payloadHash,
      digitalSignature: digitalSignature,
    );
  }

  StatementExportEntity copyWith({
    String? id,
    String? period,
    DateTime? generatedAt,
    String? accountHolder,
    String? accountNumber,
    String? currency,
    double? openingBalance,
    double? closingBalance,
    double? totalDebits,
    double? totalCredits,
    List<TransactionEntity>? transactions,
    String? payloadHash,
    String? digitalSignature,
    String? verificationQrPayload,
    String? sealWatermark,
    List<int>? pdfBytes,
  }) {
    return StatementExportEntity(
      id: id ?? this.id,
      period: period ?? this.period,
      generatedAt: generatedAt ?? this.generatedAt,
      accountHolder: accountHolder ?? this.accountHolder,
      accountNumber: accountNumber ?? this.accountNumber,
      currency: currency ?? this.currency,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      totalDebits: totalDebits ?? this.totalDebits,
      totalCredits: totalCredits ?? this.totalCredits,
      transactions: transactions ?? this.transactions,
      payloadHash: payloadHash ?? this.payloadHash,
      digitalSignature: digitalSignature ?? this.digitalSignature,
      verificationQrPayload:
          verificationQrPayload ?? this.verificationQrPayload,
      sealWatermark: sealWatermark ?? this.sealWatermark,
      pdfBytes: pdfBytes ?? this.pdfBytes,
    );
  }
}
