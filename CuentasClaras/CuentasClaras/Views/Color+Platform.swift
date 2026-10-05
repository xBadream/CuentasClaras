import SwiftUI

extension Color {
    /// Fondo de tarjeta compatible con iOS, macOS y modo oscuro.
    static var cardBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
