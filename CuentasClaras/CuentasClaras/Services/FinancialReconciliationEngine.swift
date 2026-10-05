import Foundation

public final class FinancialReconciliationEngine {
    public init() {}

    public struct ReconciliationResult {
        public let isValid: Bool
        public let issues: [ReconciliationIssue]
        public let confidence: Double
    }

    public struct ReconciliationIssue {
        public let transactionIndex: Int
        public let message: String
        public let severity: Severity

        public enum Severity {
            case critical
            case warning
            case info
        }
    }

    public func reconcile(_ statement: ParsedStatement) -> ReconciliationResult {
        var issues: [ReconciliationIssue] = []
        var confidence: Double = 1.0

        let computedBalance = statement.openingBalance + statement.totalCredits - statement.totalDebits
        if abs(computedBalance - statement.accountingBalance) > 0.01 {
            issues.append(.init(
                transactionIndex: -1,
                message: "Saldo contable no coincide: esperado \(computedBalance), obtenido \(statement.accountingBalance)",
                severity: .critical
            ))
            confidence -= 0.3
        }

        var runningBalance = statement.openingBalance
        for (index, transaction) in statement.transactions.enumerated() {
            let delta: Decimal
            if let debit = transaction.debitAmount {
                delta = -debit
            } else if let credit = transaction.creditAmount {
                delta = credit
            } else {
                delta = 0
            }

            let expected = runningBalance + delta
            if abs(expected - transaction.resultingBalance) > 0.01 {
                issues.append(.init(
                    transactionIndex: index,
                    message: "Saldo no concilia: esperado \(expected), obtenido \(transaction.resultingBalance) en '\(transaction.transactionDescription)'",
                    severity: .critical
                ))
                confidence -= 0.2
            }

            if transaction.parserConfidence < 0.95 {
                issues.append(.init(
                    transactionIndex: index,
                    message: "Confianza baja en parseo: \(Int(transaction.parserConfidence * 100))% en '\(transaction.transactionDescription)'",
                    severity: .warning
                ))
                confidence -= 0.05
            }

            runningBalance = transaction.resultingBalance
        }

        return ReconciliationResult(
            isValid: issues.filter { $0.severity == .critical }.isEmpty,
            issues: issues,
            confidence: max(0.0, min(1.0, confidence))
        )
    }
}
