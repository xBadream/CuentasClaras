import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(FinanceViewModel.self) private var viewModel
    @Query private var transactions: [Transaction]
    @State private var editingCategory: BudgetCategory?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(BudgetCategory.allCases) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            BudgetRow(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Toca una categoría para editar su límite mensual.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Presupuestos")
            .sheet(item: $editingCategory) { category in
                EditBudgetSheet(category: category)
                    .presentationDetents([.medium])
            }
        }
        .onChange(of: transactions, initial: true) { _, new in
            viewModel.transactions = new
        }
    }
}

private struct BudgetRow: View {
    @Environment(FinanceViewModel.self) private var viewModel
    let category: BudgetCategory

    var body: some View {
        let spent = viewModel.spent(for: category)
        let limit = viewModel.limit(for: category)
        let ratio = viewModel.progress(for: category)
        let over = viewModel.isOverBudget(category)
        let tint: Color = over ? .red : .blue

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name).font(.headline)
                    Text("\(spent.clp) / \(limit.clp)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                Text(ratio, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }

            ProgressView(value: min(max(ratio, 0), 1))
                .tint(tint)
                .animation(.easeInOut, value: ratio)

            if over {
                Label("⚠️ Presupuesto Excedido (+\((spent - limit).clp))", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct EditBudgetSheet: View {
    @Environment(FinanceViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let category: BudgetCategory
    @State private var amount: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Límite mensual · \(category.name)") {
                    TextField("Monto", value: $amount, format: .currency(code: "CLP"))
                        .keyboardType(.numberPad)
                }
                Section {
                    LabeledContent("Gastado este mes", value: viewModel.spent(for: category).clp)
                }
                Section {
                    Button("Restablecer valor por defecto", role: .destructive) {
                        viewModel.resetBudgetLimit(for: category)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Editar presupuesto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        viewModel.updateBudgetLimit(amount, for: category)
                        dismiss()
                    }
                    .disabled(amount < 0)
                }
            }
            .onAppear { amount = viewModel.limit(for: category) }
        }
    }
}

#Preview {
    BudgetsView()
        .environment(FinanceViewModel())
        .modelContainer(for: Transaction.self, inMemory: true)
}
