import SwiftUI
import SwiftData

@main
struct CuentasClarasApp: App {
    let container: ModelContainer
    @State private var financeViewModel = FinanceViewModel()

    init() {
        let schema = Schema([
            BankAccount.self,
            BankStatement.self,
            AccountSummary.self,
            CreditLine.self,
            Transaction.self
        ])
        let configuration = ModelConfiguration("CuentasClarasModel")
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("No se pudo crear ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem { Label("Resumen", systemImage: "house.fill") }
                BudgetsView()
                    .tabItem { Label("Presupuestos", systemImage: "chart.pie.fill") }
            }
            .environment(financeViewModel)
            .modelContainer(container)
            .task {
                StatementImportService.importBundledStatement(into: container.mainContext)
            }
        }
    }
}
