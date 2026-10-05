import SwiftUI

public struct TransactionDetailView: View {
    let transaction: Transaction

    public init(transaction: Transaction) {
        self.transaction = transaction
    }

    public var body: some View {
        Form {
            Section("Información general") {
                LabeledContent("Fecha", value: transaction.date.formatted(date: .numeric, time: .omitted))
                LabeledContent("Documento", value: transaction.documentNumber)
                LabeledContent("Descripción", value: transaction.transactionDescription)
            }

            Section("Monto") {
                if let debit = transaction.debitAmount {
                    LabeledContent("Cargo", value: debit.clp)
                } else if let credit = transaction.creditAmount {
                    LabeledContent("Abono", value: credit.clp)
                }
                LabeledContent("Saldo resultante", value: transaction.resultingBalance.clp)
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
            }
        }
        .navigationTitle("Detalle de transacción")
    }
}
