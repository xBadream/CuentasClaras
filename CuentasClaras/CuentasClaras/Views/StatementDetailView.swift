import SwiftUI
import SwiftData

public struct StatementDetailView: View {
    let statement: BankStatement
    @Query var transactions: [Transaction]

    public init(statement: BankStatement) {
        self.statement = statement
        let predicate = #Predicate<Transaction> { $0.statement?.id == statement.id }
        _transactions = Query(filter: predicate, sort: [SortDescriptor(\.date, order: .reverse)])
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Resumen financiero")
                    .font(.title2.bold())

                if let summary = statement.summary {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Saldo inicial", value: summary.openingBalance.formatted(.currency(code: "CLP")))
                        LabeledContent("Abonos", value: summary.totalCredits.formatted(.currency(code: "CLP")))
                        LabeledContent("Cargos", value: summary.totalDebits.formatted(.currency(code: "CLP")))
                        LabeledContent("Saldo final", value: summary.accountingBalance.formatted(.currency(code: "CLP")))
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
                        ForEach(transactions.prefix(10)) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRowView(transaction: transaction)
                            }
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
                Text(formatDate(transaction.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let debit = transaction.debitAmount {
                    Text("- \(debit.formatted(.currency(code: \"CLP\")))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                } else if let credit = transaction.creditAmount {
                    Text("+ \(credit.formatted(.currency(code: \"CLP\")))")
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let container = try! ModelContainer(for: BankStatement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let statement = BankStatement(
        importFingerprint: "test",
        statementNumber: "SEC-001",
        periodStart: Date().addingTimeInterval(-30*24*3600),
        periodEnd: Date(),
        issueDate: Date(),
        sourceFileName: "test.pdf"
    )
    container.mainContext.insert(statement)
    return NavigationStack {
        StatementDetailView(statement: statement)
            .modelContainer(container)
    }
}
