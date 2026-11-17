import 'package:flutter_test/flutter_test.dart';
import 'package:pay_vault/core/crypto/statement_seal_service.dart';
import 'package:pay_vault/core/utils/pdf_document_generator.dart';
import 'package:pay_vault/presentation/analytics_ledger/ledger_controller.dart';

import '../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTransferRepository fakeTransferRepo;
  late FakeStatementRepository fakeStatementRepo;
  late LedgerController ledgerController;

  setUp(() {
    fakeTransferRepo = FakeTransferRepository();
    fakeStatementRepo = FakeStatementRepository();
    ledgerController = LedgerController(fakeTransferRepo, fakeStatementRepo);
  });

  tearDown(() {
    ledgerController.onClose();
  });

  group('StatementSealService Cryptographic Tests', () {
    test('Generates deterministic SHA-256 payload digest', () {
      final hash1 = StatementSealService.generatePayloadHash(
        statementId: 'PV-STMT-202611-001',
        accountHolder: 'Safeer Hussain',
        accountNumber: 'GB29NWBK60161331926819',
        period: 'November 2026',
        openingBalance: 10000.0,
        closingBalance: 14150.0,
        totalDebits: 850.0,
        totalCredits: 5000.0,
        transactionCount: 2,
        generatedAtTimestamp: 1700000000,
      );

      final hash2 = StatementSealService.generatePayloadHash(
        statementId: 'PV-STMT-202611-001',
        accountHolder: 'Safeer Hussain',
        accountNumber: 'GB29NWBK60161331926819',
        period: 'November 2026',
        openingBalance: 10000.0,
        closingBalance: 14150.0,
        totalDebits: 850.0,
        totalCredits: 5000.0,
        transactionCount: 2,
        generatedAtTimestamp: 1700000000,
      );

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex string length
    });

    test('Generates digital signature stamp with PV-SIG prefix', () {
      const payloadHash =
          '4a8f9b2d8e7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a';
      final sig = StatementSealService.generateDigitalSignature(
        payloadHash: payloadHash,
      );

      expect(sig.startsWith('PV-SIG-'), isTrue);
      expect(sig.length, greaterThan(15));
    });

    test('Validates authentic digital signature and rejects tampered hash', () {
      const payloadHash =
          '4a8f9b2d8e7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a';
      final sig = StatementSealService.generateDigitalSignature(
        payloadHash: payloadHash,
      );

      final isValid = StatementSealService.verifySignature(
        payloadHash: payloadHash,
        digitalSignature: sig,
      );
      expect(isValid, isTrue);

      // Tampered payload hash
      const tamperedHash =
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
      final isTamperedValid = StatementSealService.verifySignature(
        payloadHash: tamperedHash,
        digitalSignature: sig,
      );
      expect(isTamperedValid, isFalse);
    });

    test('Generates valid universal verification URI scheme for QR codes', () {
      final uriStr = StatementSealService.generateVerificationUri(
        statementId: 'PV-STMT-202611-XYZ',
        digitalSignature: 'PV-SIG-999',
        payloadHash: '4a8f9b2d8e7c6b5a',
        generatedAtTimestamp: 1700000000,
      );

      final uri = Uri.parse(uriStr);
      expect(uri.scheme, equals('payvault'));
      expect(uri.host, equals('verify-statement'));
      expect(uri.queryParameters['id'], equals('PV-STMT-202611-XYZ'));
      expect(uri.queryParameters['sig'], equals('PV-SIG-999'));
    });
  });

  group('PdfDocumentGenerator & PdfFormatValidator Tests', () {
    test('Generates structurally compliant %PDF-1.4 binary file', () async {
      final statement = await fakeStatementRepo.generateStatement(
        periodMonth: DateTime(2026, 11),
        currency: 'USD',
      );

      final bytes = statement.pdfBytes;
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.length, greaterThan(500)); // Non-trivial PDF size

      // Verify header magic bytes
      final header = String.fromCharCodes(bytes.take(8));
      expect(header.startsWith('%PDF-1.4'), isTrue);

      // Verify trailer and EOF marker
      final tail = String.fromCharCodes(bytes.sublist(bytes.length - 30));
      expect(tail.contains('%%EOF'), isTrue);

      // Verify structural validator
      expect(PdfFormatValidator.isValidPdf(bytes), isTrue);
    });

    test('PdfFormatValidator rejects invalid, empty, or truncated streams', () {
      expect(PdfFormatValidator.isValidPdf([]), isFalse);
      expect(PdfFormatValidator.isValidPdf([1, 2, 3]), isFalse);

      // Fake bytes missing %%EOF
      final incomplete = '%PDF-1.4 some text without trailer or eof'.codeUnits;
      expect(PdfFormatValidator.isValidPdf(incomplete), isFalse);
    });
  });

  group('LedgerController Statement Export & Verification Tests', () {
    test(
      'Compiles and exports monthly statement with cryptographic seal',
      () async {
        final statement = await ledgerController.generateAndExportStatement(
          month: DateTime(2026, 11),
          currency: 'USD',
        );

        expect(statement, isNotNull);
        expect(statement!.id.startsWith('PV-STMT-202611'), isTrue);
        expect(statement.currency, equals('USD'));
        expect(statement.transactions.length, equals(2));
        expect(statement.pdfBytes.isNotEmpty, isTrue);
        expect(ledgerController.lastExportedStatement.value, equals(statement));
        expect(ledgerController.isExportingStatement.value, isFalse);
      },
    );

    test(
      'Validates authentic statement seal and flags tampered statement',
      () async {
        final statement = await ledgerController.generateAndExportStatement(
          month: DateTime(2026, 11),
          currency: 'USD',
        );
        expect(statement, isNotNull);

        // Verify genuine seal
        final isValid = await ledgerController.verifyStatementSeal(statement!);
        expect(isValid, isTrue);

        // Verify tampered statement
        final tampered = statement.copyWith(
          closingBalance: 9999999.0, // Tampered balance
          payloadHash: 'TAMPERED_HASH',
        );
        final isTamperedValid = await ledgerController.verifyStatementSeal(
          tampered,
        );
        expect(isTamperedValid, isFalse);
      },
    );
  });
}
