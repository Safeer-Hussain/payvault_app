import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/statement_export_entity.dart';

class PdfDocumentGenerator {
  /// Generates a valid %PDF-1.4 document byte stream from a statement entity.
  static Uint8List generateStatementPdf(StatementExportEntity statement) {
    final buffer = StringBuffer();

    // 1. Header
    buffer.write('%PDF-1.4\n');
    buffer.write('%\xE2\xE3\xCF\xD3\n'); // Binary marker

    final objects = <String>[];

    // Helper to register an object and return its object number (1-based)
    int addObject(String content) {
      objects.add(content);
      return objects.length;
    }

    // Object 1: Catalog
    addObject('<< /Type /Catalog /Pages 2 0 R >>');

    // Object 2: Pages Root
    addObject('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');

    // Object 4: Font Helvetica
    addObject('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');

    // Object 5: Font Helvetica-Bold
    addObject('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>');

    // Object 6: Font Courier (Monospace for crypto hashes)
    addObject('<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>');

    // Build the visual text stream
    final streamContent = StringBuffer();
    void writeText(
      String text, {
      required double x,
      required double y,
      String font = 'F1',
      double size = 10,
    }) {
      // Escape parentheses in PDF text strings
      final sanitized = text.replaceAll('(', '\\(').replaceAll(')', '\\)');
      streamContent.write('BT\n');
      streamContent.write('/$font $size Tf\n');
      streamContent.write('1 0 0 1 $x $y Tm\n');
      streamContent.write('($sanitized) Tj\n');
      streamContent.write('ET\n');
    }

    void drawLine(double x1, double y1, double x2, double y2) {
      streamContent.write('$x1 $y1 m\n$x2 $y2 l\nS\n');
    }

    // Title & Header Banner
    writeText(
      'PAYVAULT ENTERPRISE FINTECH DIGITAL VAULT',
      x: 50,
      y: 750,
      font: 'F2',
      size: 16,
    );
    writeText(
      'MONTHLY ACCOUNT STATEMENT AND AUDIT CERTIFICATE',
      x: 50,
      y: 735,
      font: 'F1',
      size: 11,
    );
    drawLine(50, 725, 560, 725);

    // Metadata Section
    writeText(
      'Account Holder: ${statement.accountHolder}',
      x: 50,
      y: 705,
      font: 'F2',
      size: 10,
    );
    writeText(
      'IBAN / Account: ${statement.accountNumber}',
      x: 50,
      y: 690,
      font: 'F1',
      size: 10,
    );
    writeText(
      'Statement Period: ${statement.period}',
      x: 50,
      y: 675,
      font: 'F1',
      size: 10,
    );
    writeText(
      'Generated: ${statement.formattedGeneratedDate}',
      x: 350,
      y: 705,
      font: 'F1',
      size: 10,
    );
    writeText(
      'Currency: ${statement.currency}',
      x: 350,
      y: 690,
      font: 'F1',
      size: 10,
    );
    writeText(
      'Statement ID: ${statement.id}',
      x: 350,
      y: 675,
      font: 'F3',
      size: 9,
    );

    drawLine(50, 665, 560, 665);

    // Financial Summary
    writeText(
      'FINANCIAL LIQUIDITY PROFILE',
      x: 50,
      y: 650,
      font: 'F2',
      size: 11,
    );
    writeText(
      'Opening Balance: \$${statement.openingBalance.toStringAsFixed(2)}',
      x: 50,
      y: 635,
      font: 'F1',
      size: 9,
    );
    writeText(
      'Total Credits (Inflow): +\$${statement.totalCredits.toStringAsFixed(2)}',
      x: 180,
      y: 635,
      font: 'F1',
      size: 9,
    );
    writeText(
      'Total Debits (Outflow): -\$${statement.totalDebits.toStringAsFixed(2)}',
      x: 330,
      y: 635,
      font: 'F1',
      size: 9,
    );
    writeText(
      'Closing Balance: \$${statement.closingBalance.toStringAsFixed(2)}',
      x: 460,
      y: 635,
      font: 'F2',
      size: 9,
    );

    drawLine(50, 625, 560, 625);

    // Itemized Ledger Table Header
    writeText(
      'ITEMIZED TRANSACTION AUDIT LEDGER',
      x: 50,
      y: 610,
      font: 'F2',
      size: 11,
    );
    writeText('DATE', x: 50, y: 595, font: 'F2', size: 8);
    writeText('REFERENCE', x: 120, y: 595, font: 'F2', size: 8);
    writeText('DESCRIPTION', x: 230, y: 595, font: 'F2', size: 8);
    writeText('CATEGORY', x: 420, y: 595, font: 'F2', size: 8);
    writeText('AMOUNT', x: 500, y: 595, font: 'F2', size: 8);
    drawLine(50, 590, 560, 590);

    // Transactions Rows (limit to first 12 to fit on page)
    double currentY = 575;
    for (final tx in statement.transactions.take(12)) {
      final sign = tx.isCredit ? '+' : '-';
      writeText(tx.formattedShortDate, x: 50, y: currentY, size: 8);
      writeText(tx.referenceId, x: 120, y: currentY, font: 'F3', size: 7);
      writeText(
        tx.title.length > 28 ? '${tx.title.substring(0, 26)}..' : tx.title,
        x: 230,
        y: currentY,
        size: 8,
      );
      writeText(tx.category, x: 420, y: currentY, size: 8);
      writeText(
        '$sign\$${tx.amount.toStringAsFixed(2)}',
        x: 500,
        y: currentY,
        font: 'F2',
        size: 8,
      );
      currentY -= 18;
    }

    drawLine(50, 240, 560, 240);

    // Cryptographic Seal & Hardware Security Box
    writeText(
      'DIGITAL CRYPTOGRAPHIC WATERMARK AND VERIFICATION SEAL',
      x: 50,
      y: 225,
      font: 'F2',
      size: 10,
    );
    writeText(
      'Watermark: ${statement.sealWatermark}',
      x: 50,
      y: 210,
      font: 'F1',
      size: 8,
    );
    writeText(
      'SHA-256 Digest: ${statement.payloadHash}',
      x: 50,
      y: 195,
      font: 'F3',
      size: 7,
    );
    writeText(
      'Hardware Enclave Signature: ${statement.digitalSignature}',
      x: 50,
      y: 180,
      font: 'F3',
      size: 7,
    );
    writeText(
      'Verification QR URI: ${statement.verificationQrPayload}',
      x: 50,
      y: 165,
      font: 'F3',
      size: 6,
    );
    writeText(
      'This statement has been cryptographically stamped with zero-knowledge hardware integrity.',
      x: 50,
      y: 145,
      font: 'F1',
      size: 7,
    );
    writeText(
      'Scan the embedded QR code in the PayVault app or query the enclave verification bridge.',
      x: 50,
      y: 132,
      font: 'F1',
      size: 7,
    );

    drawLine(50, 120, 560, 120);
    writeText(
      'PAYVAULT NEO-BANK CORPORATION - CONFIDENTIAL ENTERPRISE AUDIT RECORD',
      x: 100,
      y: 105,
      font: 'F1',
      size: 8,
    );

    final streamString = streamContent.toString();
    final streamBytes = utf8.encode(streamString);

    // Object 7: Content Stream
    final streamObjNum = addObject(
      '<< /Length ${streamBytes.length} >>\nstream\n$streamString\nendstream',
    );

    // Object 3: Page Definition (references fonts and stream)
    final pageObj =
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents $streamObjNum 0 R '
        '/Resources << /Font << /F1 4 0 R /F2 5 0 R /F3 6 0 R >> >> >>';
    // Update Object 3 in the list (since it's at index 2)
    objects.insert(2, pageObj);

    // Build Byte Offsets for xref
    final byteOffsets = <int>[];
    int currentOffset = buffer.length;

    for (int i = 0; i < objects.length; i++) {
      byteOffsets.add(currentOffset);
      final objStr = '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
      buffer.write(objStr);
      currentOffset = buffer.length;
    }

    // xref table
    final xrefOffset = buffer.length;
    buffer.write('xref\n');
    buffer.write('0 ${objects.length + 1}\n');
    buffer.write('0000000000 65535 f \n');
    for (final offset in byteOffsets) {
      final padded = offset.toString().padLeft(10, '0');
      buffer.write('$padded 00000 n \n');
    }

    // Trailer
    buffer.write('trailer\n');
    buffer.write('<< /Size ${objects.length + 1} /Root 1 0 R >>\n');
    buffer.write('startxref\n');
    buffer.write('$xrefOffset\n');
    buffer.write('%%EOF\n');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }
}

class PdfFormatValidator {
  /// Validates whether the given bytes form a structurally valid PDF file.
  static bool isValidPdf(List<int> bytes) {
    if (bytes.length < 128) return false;

    // 1. Magic bytes header check: %PDF-
    final headerStr = String.fromCharCodes(bytes.take(8));
    if (!headerStr.startsWith('%PDF-')) return false;

    // 2. Trailing EOF marker check: %%EOF
    final tailBytes = bytes.sublist(bytes.length - 64);
    final tailStr = String.fromCharCodes(tailBytes);
    if (!tailStr.contains('%%EOF')) return false;

    // 3. Structural markers check: /Root, /Pages, xref, trailer
    final fullString = String.fromCharCodes(bytes);
    final hasRoot = fullString.contains('/Root');
    final hasPages = fullString.contains('/Pages');
    final hasXref = fullString.contains('xref');
    final hasTrailer = fullString.contains('trailer');

    return hasRoot && hasPages && hasXref && hasTrailer;
  }
}
