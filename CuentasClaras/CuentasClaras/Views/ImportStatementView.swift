import SwiftUI

public struct ImportStatementView: View {
    @State private var showingFilePicker = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Importar cartola PDF")
                .font(.title2.bold())

            Text("Selecciona un PDF de Banco Security para extraer, validar y guardar movimientos automáticamente.")
                .foregroundStyle(.secondary)

            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Seleccionar PDF")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            VStack(alignment: .leading, spacing: 12) {
                Text("Preview de cartola (ejemplo)")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Período", value: "01/09 - 30/09/2026")
                    LabeledContent("Saldo inicial", value: "$ 1.000.000")
                    LabeledContent("Saldo final", value: "$ 1.185.000")
                    LabeledContent("Movimientos", value: "15")
                    LabeledContent("Advertencias", value: "2")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Confirmar importación") {
                    // Acción de importación
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()
        }
        .padding()
        .navigationTitle("Importar")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            onCompletion: { result in
                if case .success(let url) = result {
                    // Procesar PDF
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        ImportStatementView()
    }
}
