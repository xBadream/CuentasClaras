import SwiftUI
import UniformTypeIdentifiers

public struct ImportStatementView: View {
    @State private var showingFilePicker = false
    @State private var selectedFileName: String?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Importar cartola PDF")
                .font(.title2.bold())

            Text("Selecciona un PDF de Banco Security para extraer, validar y guardar movimientos automáticamente.")
                .foregroundStyle(.secondary)

            Button(action: { showingFilePicker = true }) {
                Label("Seleccionar PDF", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let selectedFileName {
                Label(selectedFileName, systemImage: "doc.fill")
                    .font(.callout)
            }

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
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Confirmar importación") {
                    // TODO: conectar con EnhancedBankStatementImportCoordinator
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()
        }
        .padding()
        .navigationTitle("Importar")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.pdf],
            onCompletion: { result in
                if case .success(let url) = result {
                    selectedFileName = url.lastPathComponent
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
