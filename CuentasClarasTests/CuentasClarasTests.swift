import XCTest
import SwiftData
@testable import CuentasClaras

final class SecurityBankParsingTests: XCTestCase {
    let parser = SecurityStatementParserV2()

    func testParsesSecuritySampleLine1() throws {
        let sample = """
        CARTOLA BANCO SECURITY - SALDOS Y MOVIMIENTOS
        Cuenta: 0001234567 (Corriente)
        Periodo: 01/09 al 30/09/2026
        Saldo inicial: 1.000.000
        0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
        """

        let parsed = try parser.parse(sample, sourceFileName: "security-sample.pdf")
        XCTAssertEqual(parsed.statementNumber, "CARTOLA BANCO SECURITY - SALDOS Y MOVIMIENTOS")
        XCTAssertEqual(parsed.openingBalance, Decimal(1_000_000))
    }

    func testParsesSecuritySampleLine2() throws {
        let sample = """
        CARTOLA BANCO SECURITY
        Saldo inicial: 4.000.000
        1015910136 TRANSFERENCIA DESDE Chile DE PERSONA 03/09 72.999 2.695.705
        """

        let parsed = try parser.parse(sample, sourceFileName: "security-sample.pdf")
        XCTAssertGreaterThanOrEqual(parsed.transactions.count, 1)
    }

    func testParsesSecurityColumnarRowsInChronologicalOrder() throws {
        let sample = """
        Cuenta Corriente
        Emitido 04-10-2026
        Número de cuenta 918443560 Saldo contable $ 3.994.460
        Desde 01-09-2026 Hasta el 30-09-2026
        Saldos y movimientos
        Fecha Descripción del movimiento Nº documento Cargos Abonos Saldo
        30\u{00AD}09\u{00AD}2026
        COMPRA AP BUIN
        00000126434
        \u{00AD}$ 24.000
        $ 8.047.847
        30\u{00AD}09\u{00AD}2026
        COMPRA CAMION 7
        00000176497
        \u{00AD}$ 54.600
        $ 8.071.847
        30\u{00AD}09\u{00AD}2026
        COMPRA CUGAT BUIN
        00000114551
        \u{00AD}$ 99.189
        $ 8.126.447
        30\u{00AD}09\u{00AD}2026
        TRANSFERENCIA DESDE Chile DE Judith Aravena
        01034181537
        $ 339.400
        $ 8.225.636
        29\u{00AD}09\u{00AD}2026
        ABONO DE REMUNERACIONES
        00000000000
        $ 7.880.192
        $ 7.886.236
        """

        let parsed = try parser.parse(sample, sourceFileName: "security-columnar.pdf")

        XCTAssertEqual(parsed.openingBalance, Decimal(6_044))
        XCTAssertEqual(parsed.transactions.count, 5)
        XCTAssertEqual(parsed.totalDebits, Decimal(177_789))
        XCTAssertEqual(parsed.totalCredits, Decimal(8_219_592))
        XCTAssertEqual(parsed.accountingBalance, Decimal(8_047_847))
        XCTAssertEqual(parsed.transactions.first?.transactionDescription, "ABONO DE REMUNERACIONES")
        XCTAssertEqual(parsed.transactions.last?.transactionDescription, "COMPRA AP BUIN")
        XCTAssertTrue(SecurityStatementValidator().isValid(parsed))
    }

    func testRejectsEmptyZeroBalanceStatement() {
        let statement = ParsedStatement(
            statementNumber: "SEC-EMPTY",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "empty.pdf",
            openingBalance: 0,
            totalDebits: 0,
            totalCredits: 0,
            accountingBalance: 0,
            availableBalance: 0,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "empty"
        )

        XCTAssertFalse(SecurityStatementValidator().isValid(statement))
    }

    func testValidatesAccountingEquality() throws {
        let validator = SecurityStatementValidator()
        let statement = ParsedStatement(
            statementNumber: "SEC-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "test.pdf",
            openingBalance: 1_000_000,
            totalDebits: 49_980,
            totalCredits: 72_999,
            accountingBalance: 1_023_019,
            availableBalance: 1_023_019,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        XCTAssertTrue(validator.isValid(statement))
    }

    func testDetectsDuplicates() throws {
        let fingerprint = FinancialHashing.statementFingerprint(
            fileName: "security-sample.pdf",
            issueDate: Date(),
            statementNumber: "SEC-001"
        )
        let fingerprint2 = FinancialHashing.statementFingerprint(
            fileName: "security-sample.pdf",
            issueDate: Date(),
            statementNumber: "SEC-001"
        )
        XCTAssertEqual(fingerprint, fingerprint2)
    }
}

final class FinancialReconciliationTests: XCTestCase {
    let reconciler = FinancialReconciliationEngine()

    func testReconciliationSucceedsWithValidBalance() {
        let statement = ParsedStatement(
            statementNumber: "SEC-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "test.pdf",
            openingBalance: 1_000_000,
            totalDebits: 120_000,
            totalCredits: 315_000,
            accountingBalance: 1_195_000,
            availableBalance: 1_195_000,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        let result = reconciler.reconcile(statement)
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.confidence, 0.95)
    }

    func testReconciliationFailsWithMismatchedBalance() {
        let statement = ParsedStatement(
            statementNumber: "SEC-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "test.pdf",
            openingBalance: 1_000_000,
            totalDebits: 120_000,
            totalCredits: 315_000,
            accountingBalance: 999_999,
            availableBalance: 999_999,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        let result = reconciler.reconcile(statement)
        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThan(result.issues.count, 0)
    }
}
