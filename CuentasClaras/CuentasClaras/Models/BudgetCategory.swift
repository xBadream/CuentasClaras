import Foundation

enum BudgetCategory: String, CaseIterable, Identifiable, Codable {
    case supermercado = "Supermercado"
    case familiaYSalidas = "Familia y Salidas"
    case serviciosBasicos = "Servicios Básicos"
    case transporte = "Transporte"
    case otros = "Otros"

    var id: String { rawValue }
    var name: String { rawValue }

    var icon: String {
        switch self {
        case .supermercado: "cart.fill"
        case .familiaYSalidas: "figure.2.and.child.holdinghands"
        case .serviciosBasicos: "bolt.fill"
        case .transporte: "car.fill"
        case .otros: "ellipsis.circle.fill"
        }
    }

    /// Límite mensual por defecto (CLP).
    var defaultLimit: Decimal {
        switch self {
        case .supermercado: 350_000
        case .familiaYSalidas: 200_000
        case .serviciosBasicos: 150_000
        case .transporte: 100_000
        case .otros: 80_000
        }
    }
}
