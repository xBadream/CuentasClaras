import SwiftUI

public struct TransactionDetailView: View {
    let transaction: Transaction

    public init(transaction: Transaction) {
        self.transaction = transaction
    }

    public var body: some View {
        Form {
            Section("Información general") {
                LabeledContent("Fecha", value: formatDate(transaction.date))
                LabeledContent("Documento", value: transaction.documentNumber)
                LabeledContent("Descripción", value: transaction.transactionDescription)
            }

            Section("Monto") {
                if let debit = transaction.debitAmount {
                    LabeledContent("Cargo", value: debit.formatted(.currency(code: "CLP")))
                } else if let credit = transaction.creditAmount {
                    LabeledContent("Abono", value: credit.formatted(.currency(code: "CLP")))
                }
                LabeledContent("Saldo resultante", value: transaction.resultingBalance.formatted(.currency(code: "CLP")))
            }

            Section("Metadata") {
                LabeledContent("Confianza del parser", value: "\(Int(transaction.parserConfidence * 100))%")
                if let category = transaction.categoryName {
                    LabeledContent("Categoría", value: category)
                }
                LabeledContent("Página", value: String(transaction.sourcePage))
                if transaction.requiresReview {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Requiere revisión manual")
                    }
                }
            }

            Section("Texto original") {
                Text(transaction.sourceRawText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        }
        .navigationTitle("Detalle de transacción")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let container = try! ModelContainer(for: Transaction.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let transaction = Transaction(
        importFingerprint: "test",
        date: Date(),
        transactionDescription: "TRANSFERENCIA DESDE CHILE DE PERSONA",
        documentNumber: "1015910136",
        creditAmount: 72_999,
        resultingBalance: 2_695_705,
        parserConfidence: 0.98,
        sourcePage: 1,
        sourceRawText: "1015910136 TRANSFERENCIA DESDE CHILE DE PERSONA 03/09 72.999 2.695.705"
    )
    container.mainContext.insert(transaction)
    return NavigationStack {
        TransactionDetailView(transaction: transaction)
            .modelContainer(container)
    }
}
