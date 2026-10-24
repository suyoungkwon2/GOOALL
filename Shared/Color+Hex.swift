import SwiftUI

extension Color {
    /// "#RRGGBB" → Color. 형식이 틀리면 흰색 (theme.json의 overlayTextColor 기본값과 같음).
    init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard digits.count == 6, let rgb = UInt32(digits, radix: 16) else {
            self = .white
            return
        }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
