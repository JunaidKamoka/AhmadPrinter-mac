import SwiftUI

struct TextPrintView: View {
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var fontSize: CGFloat = 12
    @State private var fontName = "Helvetica"
    @State private var isBold = false
    @State private var isItalic = false
    @State private var title = "Untitled Document"

    private let fonts = ["Helvetica", "Times New Roman", "Courier", "Georgia", "Arial", "Palatino"]

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──────────────────────────────────────
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                TextField("Document Title", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 200)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Divider().frame(height: 24)

                // Font picker
                Picker("Font", selection: $fontName) {
                    ForEach(fonts, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 160)
                .labelsHidden()

                // Font size
                HStack(spacing: 4) {
                    Button { if fontSize > 8 { fontSize -= 1 } } label: { Image(systemName: "minus") }
                        .buttonStyle(.plain)
                    Text("\(Int(fontSize))pt").font(.system(size: 12, weight: .medium)).frame(width: 36)
                    Button { if fontSize < 72 { fontSize += 1 } } label: { Image(systemName: "plus") }
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Bold / Italic
                Toggle(isOn: $isBold) {
                    Text("B").font(.system(size: 14, weight: .bold))
                }
                .toggleStyle(.button)

                Toggle(isOn: $isItalic) {
                    Text("I").font(.system(size: 14)).italic()
                }
                .toggleStyle(.button)

                Spacer()

                // Word count
                Text("\(wordCount) words")
                    .font(.system(size: 11)).foregroundStyle(.secondary)

                Button {
                    PrintManager.shared.printText(text, title: title)
                } label: {
                    Label("Print", systemImage: "printer.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(text.isEmpty ? Color.gray.opacity(0.4) : Color.primaryRed)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // ── Paper View ────────────────────────────────────
            ScrollView {
                ZStack {
                    Color(nsColor: .controlBackgroundColor)
                    VStack(spacing: 0) {
                        // Page shadow
                        TextEditor(text: $text)
                            .font(editorFont)
                            .padding(48)
                            .frame(minHeight: 680, alignment: .topLeading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
                            .padding(32)
                    }
                }
            }
            .background(Color(red: 0.9, green: 0.9, blue: 0.9))
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private var editorFont: Font {
        var f = Font.custom(fontName, size: fontSize)
        if isBold   { f = f.bold() }
        if isItalic { f = f.italic() }
        return f
    }

    private var wordCount: Int {
        text.split { $0.isWhitespace }.count
    }
}
