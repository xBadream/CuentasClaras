import SwiftUI

public struct DashboardView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
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
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DashboardView()
}
