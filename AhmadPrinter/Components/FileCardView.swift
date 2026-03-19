import SwiftUI

struct FileCardView: View {
    let file: PrintFile
    var onDelete: (() -> Void)? = nil
    var onPrint: (() -> Void)? = nil
    @State private var isHovered = false
    @State private var isThumbnailHovered = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Thumbnail (tappable → print) ──────────────────
            Button {
                onPrint?()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.96, green: 0.96, blue: 0.97))
                        .frame(height: 160)

                    if let thumbnail = file.thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: file.fileType.sfSymbol)
                            .font(.system(size: 34))
                            .foregroundStyle(file.fileType.color.opacity(0.35))
                    }

                    // Print overlay — appears on hover
                    if isThumbnailHovered {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.38))
                            .frame(height: 160)
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "printer.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            Text("Print")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .onHover { isThumbnailHovered = $0 }
            .animation(.easeInOut(duration: 0.15), value: isThumbnailHovered)

            // ── File info + menu ───────────────────────────────
            HStack(alignment: .center) {
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
                        .frame(width: 28, height: 28)
                        .background(Color.black.opacity(isHovered ? 0.05 : 0))
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isHovered ? 0.10 : 0.05), radius: isHovered ? 10 : 6, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
