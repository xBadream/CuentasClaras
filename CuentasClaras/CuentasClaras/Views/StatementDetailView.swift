import SwiftUI

public struct StatementDetailView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Resumen financiero")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Saldo inicial", value: "$ 1.000.000")
                    LabeledContent("Abonos", value: "$ 315.000")
                    LabeledContent("Cargos", value: "$ 130.000")
                    LabeledContent("Saldo final", value: "$ 1.185.000")
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Línea de crédito")
                    .font(.headline)
                CreditLineCard(approved: 600_000, used: 170_000, available: 430_000)

                Text("Advertencias")
                    .font(.headline)
                Text("Sin advertencias críticas.")
                    .foregroundStyle(.secondary)

                NavigationLink(destination: TransactionDetailView()) {
                    Label("Ver detalle de transacciones", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Detalle de cartola")
    }
}

#Preview {
    NavigationStack {
        StatementDetailView()
    }
}
