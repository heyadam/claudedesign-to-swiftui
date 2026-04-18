import SwiftUI

struct WelcomeCardView: View {
    var body: some View {
        ZStack {
            Color(hex: "F2F2F7").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text("A")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Welcome to Acme")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "1C1C1E"))

                Text("Get started in seconds. Connect your account and we'll handle the rest.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "6B6B70"))
                    .lineSpacing(4)

                Button {
                    // action
                } label: {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color(hex: "007AFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    // action
                } label: {
                    Text("I already have an account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "007AFF"))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "007AFF"), lineWidth: 1)
                        )
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(24)
        }
    }
}

#Preview {
    WelcomeCardView()
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
