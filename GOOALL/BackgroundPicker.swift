import SwiftUI

/// 위젯 배경 색 고르기: Auto + 파스텔 프리셋 (F07-R1)
struct BackgroundPicker: View {
    @Binding var selection: WidgetAppearance

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                chip(id: WidgetBackgrounds.systemID, name: "Auto") {
                    // 라이트/다크 반반
                    Circle()
                        .fill(Color(hex: WidgetBackgrounds.systemLightHex))
                        .overlay {
                            Circle()
                                .trim(from: 0.25, to: 0.75)
                                .fill(Color(hex: WidgetBackgrounds.systemDarkHex))
                        }
                }
                ForEach(WidgetBackgrounds.presets) { preset in
                    chip(id: preset.id, name: LocalizedStringKey(preset.displayName)) {
                        Circle().fill(Color(hex: preset.hex))
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(id: String, name: LocalizedStringKey, @ViewBuilder swatch: () -> some View) -> some View {
        let isSelected = selection.backgroundID == id
        return Button {
            selection = WidgetAppearance(backgroundID: id)
        } label: {
            VStack(spacing: 6) {
                swatch()
                    .frame(width: 40, height: 40)
                    .overlay { Circle().strokeBorder(.black.opacity(0.12), lineWidth: 1) }
                    .padding(3)
                    .overlay {
                        Circle().strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2.5)
                    }
                Text(name)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
