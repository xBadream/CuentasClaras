import SwiftUI

struct CreditLineCard: View {
    let approved: Decimal
    let used: Decimal
    let available: Decimal

    private var usageRatio: Double {
        guard approved > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: used / approved).doubleValue
        return min(max(ratio, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Crédito total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(approved.formatted(.currency(code: "CLP")))
                .font(.title3.bold())
            ProgressView(value: usageRatio, total: 1)
                .tint(.orange)
                .accessibilityLabel("Uso de línea de crédito")
                .accessibilityValue("\(Int(usageRatio * 100)) por ciento")
            HStack {
                Text("Usado: \(used.formatted(.currency(code: "CLP")))")
                Spacer()
                Text("Disponible: \(available.formatted(.currency(code: "CLP")))")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
