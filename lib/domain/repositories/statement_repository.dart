import '../entities/statement_export_entity.dart';

abstract class StatementRepository {
  /// Generates a complete cryptographically sealed monthly statement entity with PDF payload.
  Future<StatementExportEntity> generateStatement({
    required DateTime periodMonth,
    String currency = 'USD',
  });

  /// Verifies the digital signature and payload hash of a statement.
  Future<bool> verifyStatementIntegrity({
    required String statementId,
    required String digitalSignature,
    required String payloadHash,
  });

  /// Saves the statement PDF bytes to the filesystem and returns the absolute file path.
  Future<String> saveStatementPdf(StatementExportEntity statement);
}
