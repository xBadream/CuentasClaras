import Foundation
import SwiftData

public final class EnhancedBankStatementImportCoordinator {
    private let parser: SecurityStatementParserV2
    private let validator: SecurityStatementValidator
    private let reconciler: FinancialReconciliationEngine
    private let mapper: ParsedStatementMapper
    private let repository: StatementImportRepository

    public init(
        parser: SecurityStatementParserV2 = SecurityStatementParserV2(),
        validator: SecurityStatementValidator = SecurityStatementValidator(),
        reconciler: FinancialReconciliationEngine = FinancialReconciliationEngine(),
        mapper: ParsedStatementMapper = ParsedStatementMapper(),
        repository: StatementImportRepository
    ) {
        self.parser = parser
        self.validator = validator
        self.reconciler = reconciler
        self.mapper = mapper
        self.repository = repository
    }

    public enum ImportResult {
        case success(BankStatement)
        case validationFailed([StatementValidationIssue])
        case reconciliationWarning(BankStatement, FinancialReconciliationEngine.ReconciliationResult)
        case duplicateDetected(existingStatement: BankStatement)
        case failed(Error)
    }

    public func importPDF(from url: URL, account: BankAccount? = nil) async -> ImportResult {
        do {
            let extractor = PDFTextExtractor()
            let rawText = try extractor.extractText(from: url)
            let parsed = try parser.parse(rawText, sourceFileName: url.lastPathComponent)

            let isDuplicate = try repository.checkDuplicate(parsed.importFingerprint)
            if isDuplicate {
                let existing = try repository.fetchAllStatements()
                if let found = existing.first(where: { $0.importFingerprint == parsed.importFingerprint }) {
                    return .duplicateDetected(existingStatement: found)
                }
            }

            let validationIssues = validator.validate(parsed)
            if !validator.isValid(parsed) {
                return .validationFailed(validationIssues)
            }

            let statement = mapper.map(parsed, account: account)
            let reconciliation = reconciler.reconcile(parsed)

            if !reconciliation.isValid {
                return .reconciliationWarning(statement, reconciliation)
            }

            try repository.saveStatement(statement)
            return .success(statement)
        } catch {
            return .failed(error)
        }
    }
}
