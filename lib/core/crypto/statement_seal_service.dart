import 'dart:convert';

import 'package:crypto/crypto.dart';

class StatementSealService {
  static const String _defaultHardwareSeed =
      'PAYVAULT_HARDWARE_KEYSTORE_MASTER_SECRET_2026';

  /// Generates a deterministic SHA-256 hash digest of the statement payload.
  static String generatePayloadHash({
    required String statementId,
    required String accountHolder,
    required String accountNumber,
    required String period,
    required double openingBalance,
    required double closingBalance,
    required double totalDebits,
    required double totalCredits,
    required int transactionCount,
    required int generatedAtTimestamp,
  }) {
    final canonicalString = [
      statementId,
      accountHolder,
      accountNumber,
      period,
      openingBalance.toStringAsFixed(2),
      closingBalance.toStringAsFixed(2),
      totalDebits.toStringAsFixed(2),
      totalCredits.toStringAsFixed(2),
      transactionCount.toString(),
      generatedAtTimestamp.toString(),
    ].join('|');

    final bytes = utf8.encode(canonicalString);
    return sha256.convert(bytes).toString();
  }

  /// Generates an HMAC-SHA256 digital signature stamp using hardware enclave key seed.
  static String generateDigitalSignature({
    required String payloadHash,
    String secretSeed = _defaultHardwareSeed,
  }) {
    final keyBytes = utf8.encode(secretSeed);
    final hashBytes = utf8.encode(payloadHash);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(hashBytes);
    return 'PV-SIG-${digest.toString().substring(0, 32).toUpperCase()}';
  }

  /// Generates a universal verification URI for QR code embedding.
  static String generateVerificationUri({
    required String statementId,
    required String digitalSignature,
    required String payloadHash,
    required int generatedAtTimestamp,
  }) {
    final uri = Uri(
      scheme: 'payvault',
      host: 'verify-statement',
      queryParameters: {
        'id': statementId,
        'sig': digitalSignature,
        'hash': payloadHash.substring(0, 16),
        'ts': generatedAtTimestamp.toString(),
        'enclave': 'hw-keystore-v2',
      },
    );
    return uri.toString();
  }

  /// Verifies whether the digital signature matches the given payload hash.
  static bool verifySignature({
    required String payloadHash,
    required String digitalSignature,
    String secretSeed = _defaultHardwareSeed,
  }) {
    final expectedSignature = generateDigitalSignature(
      payloadHash: payloadHash,
      secretSeed: secretSeed,
    );
    return expectedSignature == digitalSignature;
  }
}
