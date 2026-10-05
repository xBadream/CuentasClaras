import SwiftUI

public struct DashboardView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dashboard")
                        .font(.largeTitle.bold())

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                        SummaryCard(title: "Saldo disponible", value: "$ 1.250.000")
                        SummaryCard(title: "Saldo contable", value: "$ 1.285.000")
                        SummaryCard(title: "Total cargos", value: "$ 120.000")
                        SummaryCard(title: "Total abonos", value: "$ 155.000")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Líneas de crédito")
                            .font(.headline)
                        CreditLineCard(approved: 600_000, used: 170_000, available: 430_000)
                    }

                    NavigationLink(destination: StatementsView()) {
                        Text("Ver cartolas")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("CuentasClaras")
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct CreditLineCard: View {
    let approved: Decimal
    let used: Decimal
    let available: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Crédito total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(approved.formatted(.currency(code: "CLP")))
                .font(.title3.bold())
            ProgressView(value: used / approved, total: 1)
                .tint(.orange)
            HStack {
                Text("Usado: \(used.formatted(.currency(code: "CLP")))")
                Spacer()
                Text("Disponible: \(available.formatted(.currency(code: "CLP")))")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    DashboardView()
}
