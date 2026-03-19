import SwiftUI

extension Color {
    static let primaryRed    = Color(red: 0.84, green: 0.22, blue: 0.22)
    static let backgroundTop = Color(red: 1.00, green: 0.88, blue: 0.88)
    static let backgroundMid = Color(red: 1.00, green: 0.93, blue: 0.93)
    static let backgroundBot = Color(red: 1.00, green: 0.97, blue: 0.97)
    static let getProOrange  = Color(red: 0.94, green: 0.58, blue: 0.18)
    static let cardWhite     = Color(red: 1.00, green: 0.99, blue: 0.99)
    static let pillBackground = Color(red: 0.96, green: 0.96, blue: 0.96)
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .backgroundTop, location: 0.0),
                .init(color: .backgroundMid, location: 0.45),
                .init(color: .backgroundBot, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
