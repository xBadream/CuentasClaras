import SwiftUI

public struct StatementsView: View {
    public init() {}

    public var body: some View {
        List {
            StatementRow(title: "Cartola Banco Security", range: "01/09 - 30/09", total: "$ 1.285.000")
            StatementRow(title: "Cartola Banco Security", range: "01/08 - 31/08", total: "$ 1.240.000")
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
}

private struct StatementRow: View {
    let title: String
    let range: String
    let total: String

    var body: some View {
        NavigationLink(destination: StatementDetailView()) {
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
}

#Preview {
    NavigationStack {
        StatementsView()
    }
}
