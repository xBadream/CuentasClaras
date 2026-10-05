import Foundation
import SwiftData

public final class ParsedStatementMapper {
    public init() {}

    public func map(_ parsed: ParsedStatement, account: BankAccount? = nil) -> BankStatement {
        let statement = BankStatement(
            importFingerprint: parsed.importFingerprint,
            statementNumber: parsed.statementNumber,
            periodStart: parsed.periodStart,
            periodEnd: parsed.periodEnd,
            issueDate: parsed.issueDate,
            sourceFileName: parsed.sourceFileName,
            importedAt: Date(),
            warnings: parsed.warnings
        )

        if let account {
            statement.account = account
        }

        let summary = AccountSummary(
            openingBalance: parsed.openingBalance,
            totalDebits: parsed.totalDebits,
            totalCredits: parsed.totalCredits,
            accountingBalance: parsed.accountingBalance,
            availableBalance: parsed.availableBalance,
            totalFees: parsed.totalFees
        )
        statement.summary = summary

        let line = CreditLine(
            approvedAmount: parsed.availableBalance,
            usedAmount: parsed.totalDebits,
            availableAmount: max(parsed.availableBalance - parsed.totalDebits, .zero),
            isActive: true
        )
        statement.creditLine = line

        statement.transactions = parsed.transactions.map { parsedTransaction in
            let transaction = Transaction(
                importFingerprint: parsedTransaction.importFingerprint,
                date: parsedTransaction.date,
                transactionDescription: parsedTransaction.transactionDescription,
                documentNumber: parsedTransaction.documentNumber,
                debitAmount: parsedTransaction.debitAmount,
                creditAmount: parsedTransaction.creditAmount,
                resultingBalance: parsedTransaction.resultingBalance,
                parserConfidence: parsedTransaction.parserConfidence,
                sourcePage: parsedTransaction.sourcePage,
                sourceRawText: parsedTransaction.sourceRawText,
                categoryName: parsedTransaction.categoryName,
                requiresReview: parsedTransaction.requiresReview
            )
            transaction.statement = statement
            return transaction
        }

        return statement
    }
}
