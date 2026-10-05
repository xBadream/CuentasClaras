import SwiftUI
import SwiftData

public struct StatementDetailView: View {
    let statement: BankStatement
    @Query var transactions: [Transaction]

    public init(statement: BankStatement) {
        self.statement = statement
        let statementID = statement.persistentModelID
        let predicate = #Predicate<Transaction> { $0.statement?.persistentModelID == statementID }
        _transactions = Query(filter: predicate, sort: [SortDescriptor(\.date, order: .reverse)])
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Resumen financiero")
                    .font(.title2.bold())

                if let summary = statement.summary {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Saldo inicial", value: summary.openingBalance.clp)
                        LabeledContent("Abonos", value: summary.totalCredits.clp)
                        LabeledContent("Cargos", value: summary.totalDebits.clp)
                        LabeledContent("Saldo final", value: summary.accountingBalance.clp)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if let creditLine = statement.creditLine {
                    Text("Línea de crédito")
                        .font(.headline)
                    CreditLineCard(
                        approved: creditLine.approvedAmount,
                        used: creditLine.usedAmount,
                        available: creditLine.availableAmount
                    )
                }

                if !statement.warnings.isEmpty {
                    Text("Advertencias")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statement.warnings, id: \.self) { warning in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 20)
                                Text(warning)
                                    .font(.caption)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Transacciones (\(transactions.count))")
                        .font(.headline)
                    if transactions.isEmpty {
                        Text("Sin transacciones registradas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(transactions) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRowView(transaction: transaction)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detalle de cartola")
    }
}

private struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.transactionDescription)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let debit = transaction.debitAmount {
                    Text("- \(debit.clp)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                } else if let credit = transaction.creditAmount {
                    Text("+ \(credit.clp)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                Text("Conf: \(Int(transaction.parserConfidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
