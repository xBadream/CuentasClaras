import SwiftUI
import SwiftData

@main
struct CuentasClarasApp: App {
    let container: ModelContainer

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
            DashboardView()
                .modelContainer(container)
        }
    }
}
