import SwiftUI
import UniformTypeIdentifiers
import SwiftData

public struct ImportStatementView: View {
    @State private var showingFilePicker = false
    @State private var selectedURL: URL?
    @State private var isProcessing = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var resultIsSuccess = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Importar cartola PDF")
                .font(.title2.bold())

            Text("Selecciona un PDF de Banco Security para extraer, validar y guardar movimientos automáticamente.")
                .foregroundStyle(.secondary)

            Button(action: { showingFilePicker = true }) {
                if isProcessing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Seleccionar PDF", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)

            if let url = selectedURL {
                VStack(alignment: .leading, spacing: 10) {
                    Label(url.lastPathComponent, systemImage: "doc.fill")
                        .font(.callout)
                        .lineLimit(1)

                    Button("Procesar e importar") {
                        processFile(url)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(isProcessing)
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Formato soportado: PDF", systemImage: "doc.text")
                Label("Banco: Security", systemImage: "building.2")
                Label("Validación automática", systemImage: "checkmark.circle")
                Label("Deduplicación segura", systemImage: "lock")
            }
            .font(.caption)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding()
        .navigationTitle("Importar")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.pdf],
            onCompletion: { result in
                if case .success(let url) = result {
                    selectedURL = url
                }
            }
        )
        .alert("Resultado de importación", isPresented: $showResult) {
            Button("OK") {
                if resultIsSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(resultMessage)
        }
    }

    private func processFile(_ url: URL) {
        isProcessing = true
        defer { isProcessing = false }

        // Archivos elegidos con fileImporter requieren acceso con ámbito de seguridad.
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let extractor = PDFTextExtractor()
            let rawText = try extractor.extractText(from: url)

            let parser = SecurityStatementParserV2()
            let parsed = try parser.parse(rawText, sourceFileName: url.lastPathComponent)

            let validator = SecurityStatementValidator()
            guard validator.isValid(parsed) else {
                let messages = validator.validate(parsed).map { $0.message }
                resultMessage = "Validación fallida:\n" + messages.joined(separator: "\n")
                resultIsSuccess = false
                showResult = true
                return
            }

            let repository = StatementImportRepository(modelContext: modelContext)
            if try repository.checkDuplicate(parsed.importFingerprint) {
                resultMessage = "Esta cartola ya fue importada anteriormente."
                resultIsSuccess = false
                showResult = true
                return
            }

            let statement = ParsedStatementMapper().map(parsed)
            try repository.saveStatement(statement)

            let balanceText = parsed.accountingBalance.clp
            resultMessage = "Cartola importada exitosamente.\n\n"
                + "Movimientos: \(parsed.transactions.count)\n"
                + "Saldo: \(balanceText)"
            resultIsSuccess = true
            showResult = true
            selectedURL = nil
        } catch {
            resultMessage = "Error al procesar: \(error.localizedDescription)"
            resultIsSuccess = false
            showResult = true
        }
    }
}
