import SwiftUI
import SwiftData

public struct DashboardView: View {
    @Query var statements: [BankStatement]
    @Query var accounts: [BankAccount]

    public init() {}

    var totalBalance: Decimal {
        statements.compactMap { $0.summary?.availableBalance }.reduce(Decimal.zero, +)
    }

    var totalAccountingBalance: Decimal {
        statements.compactMap { $0.summary?.accountingBalance }.reduce(Decimal.zero, +)
    }

    var totalDebits: Decimal {
        statements.compactMap { $0.summary?.totalDebits }.reduce(Decimal.zero, +)
    }

    var totalCredits: Decimal {
        statements.compactMap { $0.summary?.totalCredits }.reduce(Decimal.zero, +)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                        SummaryCard(
                            title: "Saldo disponible",
                            value: totalBalance.formatted(.currency(code: "CLP"))
                        )
                        SummaryCard(
                            title: "Saldo contable",
                            value: totalAccountingBalance.formatted(.currency(code: "CLP"))
                        )
                        SummaryCard(
                            title: "Total cargos",
                            value: totalDebits.formatted(.currency(code: "CLP"))
                        )
                        SummaryCard(
                            title: "Total abonos",
                            value: totalCredits.formatted(.currency(code: "CLP"))
                        )
                    }

                    if let latestStatement = statements.last, let creditLine = latestStatement.creditLine {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Líneas de crédito")
                                .font(.headline)
                            CreditLineCard(
                                approved: creditLine.approvedAmount,
                                used: creditLine.usedAmount,
                                available: creditLine.availableAmount
                            )
                        }
                    }

                    NavigationLink(destination: StatementsView()) {
                        Text("Ver cartolas")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if statements.isEmpty {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Sin cartolas importadas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            NavigationLink(destination: ImportStatementView()) {
                                Text("Importar primera cartola")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundStyle(.white)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .navigationTitle("CuentasClaras")
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: BankStatement.self, inMemory: true)
}
