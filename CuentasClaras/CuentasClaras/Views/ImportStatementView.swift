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
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Información del documento")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.blue)
                            Text("Formato soportado: PDF")
                        }
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundStyle(.blue)
                            Text("Banco: Security")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                            Text("Validación automática")
                        }
                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.blue)
                            Text("Deduplicación segura")
                        }
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

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
    }

    private func processFile(_ url: URL) {
        isProcessing = true
        Task {
            defer { isProcessing = false }

            do {
                let extractor = PDFTextExtractor()
                let rawText = try extractor.extractText(from: url)

                let parser = SecurityStatementParserV2()
                let parsed = try parser.parse(rawText, sourceFileName: url.lastPathComponent)

                let validator = SecurityStatementValidator()
                guard validator.isValid(parsed) else {
                    let issues = validator.validate(parsed)
                    let messages = issues.compactMap { $0.message }
                    resultMessage = "Validación fallida:\n\(messages.joined(separator: "\n"))"
                    resultIsSuccess = false
                    showResult = true
                    return
                }

                let repository = StatementImportRepository(modelContext: modelContext)
                let isDuplicate = try repository.checkDuplicate(parsed.importFingerprint)
                if isDuplicate {
                    resultMessage = "Esta cartola ya fue importada anteriormente."
                    resultIsSuccess = false
                    showResult = true
                    return
                }

                let mapper = ParsedStatementMapper()
                let statement = mapper.map(parsed)
                try repository.saveStatement(statement)

                resultMessage = "Cartola importada exitosamente.\n\n" +
                    "Período: \(formatDate(parsed.periodStart)) - \(formatDate(parsed.periodEnd))\n" +
                    "Movimientos: \(parsed.transactions.count)\n" +
                    "Saldo: \(parsed.accountingBalance.formatted(.currency(code: \"CLP\")))"
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ImportStatementView()
            .modelContainer(for: BankStatement.self, inMemory: true)
    }
}
