import Foundation
import SwiftData

struct StatementImportOutcome {
    let message: String
    let isSuccess: Bool
    let isDuplicate: Bool
}

enum StatementImportService {
    static let preloadedStatementName = "Banco Security - SaldosyMovimientos 4-10-2026"

    /// Mismo flujo que "Procesar e importar" en ImportStatementView.
    static func importStatement(at url: URL, into modelContext: ModelContext) -> StatementImportOutcome {
        do {
            let rawText = try PDFTextExtractor().extractText(from: url)
            let parsed = try SecurityStatementParserV2().parse(rawText, sourceFileName: url.lastPathComponent)

            let validator = SecurityStatementValidator()
            guard validator.isValid(parsed) else {
                let messages = validator.validate(parsed).map { $0.message }
                return StatementImportOutcome(
                    message: "Validación fallida:\n" + messages.joined(separator: "\n"),
                    isSuccess: false, isDuplicate: false)
            }

            let repository = StatementImportRepository(modelContext: modelContext)
            if try repository.checkDuplicate(parsed.importFingerprint) {
                return StatementImportOutcome(
                    message: "Esta cartola ya fue importada anteriormente.",
                    isSuccess: false, isDuplicate: true)
            }

            try repository.saveStatement(ParsedStatementMapper().map(parsed))

            return StatementImportOutcome(
                message: "Cartola importada exitosamente.\n\n"
                    + "Movimientos: \(parsed.transactions.count)\n"
                    + "Saldo: \(parsed.accountingBalance.clp)",
                isSuccess: true, isDuplicate: false)
        } catch {
            return StatementImportOutcome(
                message: "Error al procesar: \(error.localizedDescription)",
                isSuccess: false, isDuplicate: false)
        }
    }

    /// Importa la cartola incluida en el bundle (si existe). Los duplicados se ignoran.
    @discardableResult
    static func importBundledStatement(into modelContext: ModelContext) -> StatementImportOutcome? {
        guard let url = Bundle.main.url(forResource: preloadedStatementName, withExtension: "pdf") else {
            return nil
        }
        return importStatement(at: url, into: modelContext)
    }
}
