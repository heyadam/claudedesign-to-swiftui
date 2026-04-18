import SwiftUI

struct SettingsListView: View {
    private struct Row: Identifiable {
        let id = UUID()
        let initial: String
        let iconColor: Color
        let label: String
        let value: String?
    }

    private let rows: [Row] = [
        Row(initial: "A", iconColor: Color(hex: "007AFF"), label: "Account",       value: "adam@example.com"),
        Row(initial: "N", iconColor: Color(hex: "34C759"), label: "Notifications", value: "On"),
        Row(initial: "P", iconColor: Color(hex: "FF9500"), label: "Privacy",       value: nil),
        Row(initial: "H", iconColor: Color(hex: "AF52DE"), label: "Help",          value: nil),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    rowView(row)
                    if index < rows.count - 1 {
                        Rectangle()
                            .fill(Color(hex: "E5E5EA"))
                            .frame(height: 1)
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)

            Spacer()
        }
        .background(Color(hex: "F2F2F7").ignoresSafeArea())
        .foregroundStyle(Color(hex: "1C1C1E"))
    }

    private var header: some View {
        ZStack {
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
            HStack {
                Button {
                    // back
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "007AFF"))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
    }

    private func rowView(_ row: Row) -> some View {
        HStack(spacing: 12) {
            ZStack {
                row.iconColor
                Text(row.initial)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(row.label)
                .font(.system(size: 16))

            Spacer()

            if let value = row.value {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "6B6B70"))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "C7C7CC"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsListView()
}

fileprivate extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6: (r, g, b, a) = (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255, 1)
        case 8: (r, g, b, a) = (Double((v >> 24) & 0xFF) / 255, Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
        default: (r, g, b, a) = (0, 0, 0, 1)
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
