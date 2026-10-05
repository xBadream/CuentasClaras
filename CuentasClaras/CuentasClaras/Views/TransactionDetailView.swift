import SwiftUI

public struct TransactionDetailView: View {
    public init() {}

    public var body: some View {
        Form {
            Section("Movimiento") {
                LabeledContent("Fecha", value: "03/09/2026")
                LabeledContent("Documento", value: "1015910136")
                LabeledContent("Descripción", value: "TRANSFERENCIA DESDE CHILE DE PERSONA")
                LabeledContent("Cargo / Abono", value: "Abono")
                LabeledContent("Saldo resultante", value: "$ 2.695.705")
                LabeledContent("Categoría", value: "Transferencia")
                LabeledContent("Confianza", value: "98%")
            }
        }
        .navigationTitle("Detalle de transacción")
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView()
    }
}
