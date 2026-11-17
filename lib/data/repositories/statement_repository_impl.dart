import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/crypto/statement_seal_service.dart';
import '../../core/utils/pdf_document_generator.dart';
import '../../domain/entities/statement_export_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/statement_repository.dart';
import '../datasources/local_database.dart';
import '../models/transaction_model.dart';

class StatementRepositoryImpl implements StatementRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<StatementExportEntity> generateStatement({
    required DateTime periodMonth,
    String currency = 'USD',
  }) async {
    final db = await AppDatabase.database;

    // 1. Fetch transactions for the statement
    final maps = await db.query(
      'transactions',
      where: 'currency = ?',
      whereArgs: [currency],
      orderBy: 'timestamp DESC',
    );
    final List<TransactionEntity> transactions = maps
        .map((m) => TransactionModel.fromMap(m))
        .toList();

    // 2. Fetch current wallet balance
    final walletMaps = await db.query(
      'wallets',
      where: 'currency = ?',
      whereArgs: [currency],
      limit: 1,
    );
    final double closingBalance = walletMaps.isNotEmpty
        ? (walletMaps.first['balance'] as num).toDouble()
        : 84250.00;

    // 3. Compute Debits and Credits
    double totalDebits = 0.0;
    double totalCredits = 0.0;
    for (final tx in transactions) {
      if (tx.isCredit) {
        totalCredits += tx.amount;
      } else {
        totalDebits += tx.amount;
      }
    }

    final double openingBalance = closingBalance + totalDebits - totalCredits;
    final now = DateTime.now();
    final String statementId =
        'PV-STMT-${periodMonth.year}${periodMonth.month.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final String periodStr = DateFormat('MMMM yyyy').format(periodMonth);
    const String accountHolder = 'Safeer Hussain';
    const String accountNumber = 'GB29NWBK60161331926819';

    // 4. Cryptographic Sealing
    final String payloadHash = StatementSealService.generatePayloadHash(
      statementId: statementId,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      period: periodStr,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
      transactionCount: transactions.length,
      generatedAtTimestamp: now.millisecondsSinceEpoch,
    );

    final String digitalSignature =
        StatementSealService.generateDigitalSignature(payloadHash: payloadHash);

    final String verificationQrPayload =
        StatementSealService.generateVerificationUri(
          statementId: statementId,
          digitalSignature: digitalSignature,
          payloadHash: payloadHash,
          generatedAtTimestamp: now.millisecondsSinceEpoch,
        );

    const String sealWatermark =
        'PAYVAULT HARDWARE KEYSTORE CRYPTOGRAPHICALLY CERTIFIED';

    // 5. Construct initial Entity
    var statement = StatementExportEntity(
      id: statementId,
      period: periodStr,
      generatedAt: now,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      currency: currency,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
      transactions: transactions,
      payloadHash: payloadHash,
      digitalSignature: digitalSignature,
      verificationQrPayload: verificationQrPayload,
      sealWatermark: sealWatermark,
      pdfBytes: const [],
    );

    // 6. Generate binary %PDF-1.4 stream and validate format
    final pdfBytes = PdfDocumentGenerator.generateStatementPdf(statement);
    final isValid = PdfFormatValidator.isValidPdf(pdfBytes);
    if (!isValid) {
      throw const FormatException(
        'Generated PDF failed structural format validation',
      );
    }

    statement = statement.copyWith(pdfBytes: pdfBytes);
    return statement;
  }

  @override
  Future<bool> verifyStatementIntegrity({
    required String statementId,
    required String digitalSignature,
    required String payloadHash,
  }) async {
    return StatementSealService.verifySignature(
      payloadHash: payloadHash,
      digitalSignature: digitalSignature,
    );
  }

  @override
  Future<String> saveStatementPdf(StatementExportEntity statement) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, '${statement.id}.pdf');
    final file = File(filePath);
    await file.writeAsBytes(statement.pdfBytes, flush: true);
    return file.path;
  }
}
