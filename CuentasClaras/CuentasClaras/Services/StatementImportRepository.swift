import Foundation
import SwiftData

public final class StatementImportRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func checkDuplicate(_ fingerprint: String) throws -> Bool {
        let predicate = #Predicate<BankStatement> { $0.importFingerprint == fingerprint }
        let descriptor = FetchDescriptor(predicate: predicate)
        let existing = try modelContext.fetch(descriptor)
        return !existing.isEmpty
    }

    public func saveStatement(_ statement: BankStatement) throws {
        modelContext.insert(statement)
        try modelContext.save()
    }

    public func fetchAllStatements() throws -> [BankStatement] {
        let descriptor = FetchDescriptor<BankStatement>()
        return try modelContext.fetch(descriptor)
    }

    public func deleteStatement(_ statement: BankStatement) throws {
        modelContext.delete(statement)
        try modelContext.save()
    }
}
