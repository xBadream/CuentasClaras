import Foundation
import Observation

@Observable
final class FinanceViewModel {
    var transactions: [Transaction] = []
    private(set) var budgetLimits: [BudgetCategory: Decimal]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "budget_limits_v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var limits = Dictionary(uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, $0.defaultLimit) })
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([String: Decimal].self, from: data) {
            for (key, value) in saved {
                if let category = BudgetCategory(rawValue: key) { limits[category] = value }
            }
        }
        self.budgetLimits = limits
    }

    func limit(for category: BudgetCategory) -> Decimal {
        budgetLimits[category] ?? category.defaultLimit
    }

    /// Gasto (débitos) del mes indicado en la categoría.
    func spent(for category: BudgetCategory, in month: Date = .now) -> Decimal {
        let calendar = Calendar.current
        return transactions
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) && resolvedCategory(of: $0) == category }
            .reduce(Decimal.zero) { $0 + ($1.debitAmount ?? 0) }
    }

    func progress(for category: BudgetCategory) -> Double {
        let limit = limit(for: category)
        guard limit > 0 else { return spent(for: category) > 0 ? 1.01 : 0 }
        return NSDecimalNumber(decimal: spent(for: category) / limit).doubleValue
    }

    func isOverBudget(_ category: BudgetCategory) -> Bool {
        spent(for: category) > limit(for: category)
    }

    func updateBudgetLimit(_ newLimit: Decimal, for category: BudgetCategory) {
        guard newLimit >= 0 else { return }
        budgetLimits[category] = newLimit
        persistLimits()
    }

    func resetBudgetLimit(for category: BudgetCategory) {
        updateBudgetLimit(category.defaultLimit, for: category)
    }

    private func resolvedCategory(of transaction: Transaction) -> BudgetCategory {
        guard let name = transaction.categoryName else { return .otros }
        return BudgetCategory(rawValue: name) ?? .otros
    }

    private func persistLimits() {
        let raw = Dictionary(uniqueKeysWithValues: budgetLimits.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
