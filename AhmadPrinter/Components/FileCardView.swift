import SwiftUI

struct FileCardView: View {
    let file: PrintFile
    var onDelete: (() -> Void)? = nil
    var onPrint: (() -> Void)? = nil
    @State private var showMenu = false
    @State private var isHovered = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                    .frame(height: 180)

                if let thumbnail = file.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: file.fileType.sfSymbol)
                            .font(.system(size: 36))
                            .foregroundStyle(file.fileType.color.opacity(0.3))
                    }
                }
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    Text(Self.dateFormatter.string(from: file.date))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button("Print", systemImage: "printer") { onPrint?() }
                    if let url = file.fileURL {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) { onDelete?() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isHovered ? 0.10 : 0.05), radius: isHovered ? 10 : 6, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

