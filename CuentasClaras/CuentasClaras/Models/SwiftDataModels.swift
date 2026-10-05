import Foundation
import SwiftData

@Model
final public class BankAccount {
    @Attribute(.unique) public var bankIdentifier: String
    public var name: String
    public var accountNumberMasked: String
    public var currencyCode: String
    @Relationship(deleteRule: .cascade, inverse: \BankStatement.account) public var statements: [BankStatement] = []

    public init(
        bankIdentifier: String,
        name: String,
        accountNumberMasked: String,
        currencyCode: String = "CLP"
    ) {
        self.bankIdentifier = bankIdentifier
        self.name = name
        self.accountNumberMasked = accountNumberMasked
        self.currencyCode = currencyCode
    }
}

@Model
final public class AccountSummary {
    public var openingBalance: Decimal
    public var totalDebits: Decimal
    public var totalCredits: Decimal
    public var accountingBalance: Decimal
    public var availableBalance: Decimal
    public var totalFees: Decimal
    public var statement: BankStatement?

    public init(
        openingBalance: Decimal,
        totalDebits: Decimal,
        totalCredits: Decimal,
        accountingBalance: Decimal,
        availableBalance: Decimal,
        totalFees: Decimal
    ) {
        self.openingBalance = openingBalance
        self.totalDebits = totalDebits
        self.totalCredits = totalCredits
        self.accountingBalance = accountingBalance
        self.availableBalance = availableBalance
        self.totalFees = totalFees
    }
}

@Model
final public class CreditLine {
    public var approvedAmount: Decimal
    public var usedAmount: Decimal
    public var availableAmount: Decimal
    public var isActive: Bool
    public var statement: BankStatement?

    public init(
        approvedAmount: Decimal,
        usedAmount: Decimal,
        availableAmount: Decimal,
        isActive: Bool = true
    ) {
        self.approvedAmount = approvedAmount
        self.usedAmount = usedAmount
        self.availableAmount = availableAmount
        self.isActive = isActive
    }
}

@Model
final public class BankStatement {
    @Attribute(.unique) public var importFingerprint: String
    public var statementNumber: String
    public var periodStart: Date
    public var periodEnd: Date
    public var issueDate: Date
    public var sourceFileName: String
    public var importedAt: Date
    public var warnings: [String] = []
    public var account: BankAccount?
    public var summary: AccountSummary?
    public var creditLine: CreditLine?
    @Relationship(deleteRule: .cascade, inverse: \Transaction.statement) public var transactions: [Transaction] = []

    public init(
        importFingerprint: String,
        statementNumber: String,
        periodStart: Date,
        periodEnd: Date,
        issueDate: Date,
        sourceFileName: String,
        importedAt: Date = Date(),
        warnings: [String] = []
    ) {
        self.importFingerprint = importFingerprint
        self.statementNumber = statementNumber
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.issueDate = issueDate
        self.sourceFileName = sourceFileName
        self.importedAt = importedAt
        self.warnings = warnings
    }
}

@Model
final public class Transaction {
    @Attribute(.unique) public var importFingerprint: String
    public var date: Date
    public var transactionDescription: String
    public var documentNumber: String
    public var debitAmount: Decimal?
    public var creditAmount: Decimal?
    public var resultingBalance: Decimal
    public var parserConfidence: Double
    public var sourcePage: Int
    public var sourceRawText: String
    public var categoryName: String?
    public var requiresReview: Bool
    public var statement: BankStatement?

    public init(
        importFingerprint: String,
        date: Date,
        transactionDescription: String,
        documentNumber: String,
        debitAmount: Decimal? = nil,
        creditAmount: Decimal? = nil,
        resultingBalance: Decimal,
        parserConfidence: Double,
        sourcePage: Int,
        sourceRawText: String,
        categoryName: String? = nil,
        requiresReview: Bool = false
    ) {
        self.importFingerprint = importFingerprint
        self.date = date
        self.transactionDescription = transactionDescription
        self.documentNumber = documentNumber
        self.debitAmount = debitAmount
        self.creditAmount = creditAmount
        self.resultingBalance = resultingBalance
        self.parserConfidence = parserConfidence
        self.sourcePage = sourcePage
        self.sourceRawText = sourceRawText
        self.categoryName = categoryName
        self.requiresReview = requiresReview
    }
}
