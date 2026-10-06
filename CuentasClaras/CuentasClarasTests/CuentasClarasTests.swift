//
//  CuentasClarasTests.swift
//  CuentasClarasTests
//
//  Created by Judith Aravena Medina on 04-10-26.
//

import XCTest
@testable import CuentasClaras

final class CuentasClarasTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testSpentDefaultsToLatestTransactionMonth() {
        let month = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
        let transaction = Transaction(
            importFingerprint: "budget-test",
            date: month,
            transactionDescription: "Compra supermercado",
            documentNumber: "1234567",
            debitAmount: 45_000,
            resultingBalance: 0,
            parserConfidence: 1,
            sourcePage: 1,
            sourceRawText: "",
            categoryName: BudgetCategory.supermercado.rawValue
        )
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let viewModel = FinanceViewModel(defaults: defaults)
        viewModel.transactions = [transaction]

        XCTAssertTrue(Calendar.current.isDate(viewModel.budgetMonth, equalTo: month, toGranularity: .month))
        XCTAssertEqual(viewModel.spent(for: .supermercado), Decimal(45_000))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
