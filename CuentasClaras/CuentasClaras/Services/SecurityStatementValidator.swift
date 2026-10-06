import Foundation

public struct StatementValidationIssue {
    public let message: String
    public let isBlocking: Bool
}

public final class SecurityStatementValidator {
    public init() {}

    public func validate(_ statement: ParsedStatement) -> [StatementValidationIssue] {
        var issues: [StatementValidationIssue] = []

        let computedBalance = statement.openingBalance + statement.totalCredits - statement.totalDebits
        if computedBalance != statement.accountingBalance {
            issues.append(.init(message: "La suma contable no coincide con el saldo final del extracto.", isBlocking: true))
        }

        var runningBalance = statement.openingBalance
        for transaction in statement.transactions {
            if transaction.requiresReview {
                runningBalance = transaction.resultingBalance
                continue
            }
            let expected: Decimal
            if let debit = transaction.debitAmount {
                expected = runningBalance - debit
                if expected != transaction.resultingBalance {
                    issues.append(.init(message: "Inconsistencia en el saldo previo para la operación \(transaction.transactionDescription).", isBlocking: false))
                }
                runningBalance = transaction.resultingBalance
            } else if let credit = transaction.creditAmount {
                expected = runningBalance + credit
                if expected != transaction.resultingBalance {
                    issues.append(.init(message: "Inconsistencia en el saldo previo para la operación \(transaction.transactionDescription).", isBlocking: false))
                }
                runningBalance = transaction.resultingBalance
            }
        }

        if statement.transactions.contains(where: { $0.requiresReview }) {
            issues.append(.init(message: "Existen movimientos pendientes de revisión manual.", isBlocking: false))
        }

        return issues
    }

    public func isValid(_ statement: ParsedStatement) -> Bool {
        validate(statement).filter { $0.isBlocking }.isEmpty
    }
}
