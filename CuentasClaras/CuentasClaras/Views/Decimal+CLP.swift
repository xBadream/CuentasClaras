import Foundation

extension Decimal {
    /// Formato de moneda chilena (CLP).
    var clp: String {
        self.formatted(.currency(code: "CLP"))
    }
}
