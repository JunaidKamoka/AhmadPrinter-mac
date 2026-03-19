import SwiftUI

struct TemplateCardView: View {
    let template: PrintTemplate
    var onSelect: (() -> Void)? = nil
    @State private var isHovered = false

    var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.08))
                        .frame(height: 130)

                    // Premium crown
                    if template.isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white)
                                    .padding(5)
                                    .background(Color.getProOrange)
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }

                    Image(systemName: template.category.icon)
                        .font(.system(size: 34))
                        .foregroundStyle(categoryColor.opacity(0.28))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.85))
                        .lineLimit(2)
                    Text(template.category.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(isHovered ? 0.10 : 0.05), radius: isHovered ? 10 : 5, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var categoryColor: Color {
        switch template.category {
        case .business:  return .blue
        case .health:    return .red
        case .education: return .green
        case .legal:     return .purple
        }
    }
}
