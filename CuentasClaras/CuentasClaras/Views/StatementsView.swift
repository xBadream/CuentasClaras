import SwiftUI
import SwiftData

public struct StatementsView: View {
    @Query(sort: \BankStatement.issueDate, order: .reverse) var statements: [BankStatement]
    @Environment(\.modelContext) var modelContext

    public init() {}

    public var body: some View {
        ZStack {
            if statements.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Sin cartolas importadas")
                        .font(.headline)
                    Text("Importa tu primera cartola de Banco Security")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(statements) { statement in
                        NavigationLink(destination: StatementDetailView(statement: statement)) {
                            StatementRow(
                                title: statement.statementNumber,
                                range: formatDateRange(start: statement.periodStart, end: statement.periodEnd),
                                total: statement.summary?.accountingBalance.formatted(.currency(code: "CLP")) ?? "$ 0"
                            )
                        }
                    }
                    .onDelete(perform: deleteStatements)
                }
            }
        }
        .navigationTitle("Cartolas")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                NavigationLink(destination: ImportStatementView()) {
                    Image(systemName: "square.and.arrow.down")
                        .accessibilityLabel("Importar cartola")
                }
            }
        }
    }

    private func deleteStatements(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(statements[index])
        }
        try? modelContext.save()
    }

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

private struct StatementRow: View {
    let title: String
    let range: String
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(range)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(total)
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        StatementsView()
            .modelContainer(for: BankStatement.self, inMemory: true)
    }
}
