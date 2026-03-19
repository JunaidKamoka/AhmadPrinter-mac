import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var isDragging    = false
    @State private var showFilePicker = false
    @State private var showWebPrint  = false
    @State private var showTextPrint = false
    @State private var showOCR       = false

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                DropZoneView(isDragging: $isDragging, onChooseFile: { showFilePicker = true })

                LazyVGrid(columns: columns, spacing: 16) {
                    ImportOptionButton(icon: "photo.stack.fill",   color: .blue,        title: "Photos",        subtitle: "Add photos for print")   { openPhotos() }
                    ImportOptionButton(icon: "icloud.fill",        color: .cyan,        title: "iCloud",        subtitle: "Add iCloud files")       { openICloud() }
                    ImportOptionButton(icon: "doc.text.image.fill", color: .indigo,     title: "Documents",     subtitle: "Add Docs for print")     { showFilePicker = true }
                    ImportOptionButton(icon: "textformat",         color: .orange,      title: "Text",          subtitle: "Type & print text")      { showTextPrint = true }
                    ImportOptionButton(icon: "globe",              color: .teal,        title: "Web pages",     subtitle: "Print any web page")     { showWebPrint = true }
                    ImportOptionButton(icon: "doc.viewfinder.fill", color: .primaryRed, title: "OCR",           subtitle: "Extract & print text")   { showOCR = true }
                    ImportOptionButton(icon: "camera.viewfinder",  color: .purple,      title: "Scan Document", subtitle: "Scan & print document")  { openScan() }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .image, .text, .data, .item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result { appState.addFiles(from: urls) }
        }
        .sheet(isPresented: $showWebPrint)  { WebPrintView() }
        .sheet(isPresented: $showTextPrint) { TextPrintView() }
        .sheet(isPresented: $showOCR)       { OCRView() }
    }

    private func openPhotos() {
        PrintManager.shared.openPhotosPanel { urls in
            appState.addFiles(from: urls)
            if !urls.isEmpty { appState.selectedTab = .files }
        }
    }

    private func openICloud() {
        PrintManager.shared.openICloudPanel { urls in
            appState.addFiles(from: urls)
            if !urls.isEmpty { appState.selectedTab = .files }
        }
    }

    private func openScan() {
        PrintManager.shared.openPhotosPanel { urls in
            appState.addFiles(from: urls)
            if !urls.isEmpty { appState.selectedTab = .files }
        }
    }
}

// MARK: - Drop Zone (Fixed drag & drop)
struct DropZoneView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isDragging: Bool
    var onChooseFile: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
                .foregroundStyle(isDragging ? Color.primaryRed : Color.black.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isDragging ? Color.primaryRed.opacity(0.05) : Color.white.opacity(0.5))
                )
                .frame(maxWidth: .infinity).frame(height: 200)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isDragging ? Color.primaryRed.opacity(0.1) : Color.black.opacity(0.04))
                        .frame(width: 64, height: 64)
                    Image(systemName: "arrow.up.to.line.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(isDragging ? Color.primaryRed : Color.black.opacity(0.5))
                        .symbolEffect(.bounce, value: isDragging)
                }
                HStack(spacing: 4) {
                    Text("Drag & Drop or Choose your")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                    Button("File here") { onChooseFile() }
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(.black).buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            print("🔵 [DROP] onDrop triggered! isDragging=\(isDragging), providers=\(providers.count)")
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        print("🔵 [DROP] handleDrop called with \(providers.count) provider(s)")
        for (index, provider) in providers.enumerated() {
            print("🔵 [DROP] Provider \(index): registeredTypeIdentifiers = \(provider.registeredTypeIdentifiers)")
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                print("🔵 [DROP] loadItem callback — item type: \(type(of: item)), item: \(String(describing: item)), error: \(String(describing: error))")
                var resolved: URL?
                if let url = item as? URL {
                    print("🔵 [DROP] Resolved as URL directly: \(url)")
                    resolved = url
                } else if let data = item as? Data {
                    print("🔵 [DROP] Item is Data (\(data.count) bytes)")
                    // Finder sends file URLs as UTF-8 encoded "file://..." strings (often null-terminated)
                    if let raw = String(data: data, encoding: .utf8) {
                        let cleaned = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
                        print("🔵 [DROP] Data as string: \(cleaned)")
                        if cleaned.hasPrefix("file://") {
                            resolved = URL(string: cleaned)
                        } else if cleaned.hasPrefix("/") {
                            resolved = URL(fileURLWithPath: cleaned)
                        }
                    }
                    if resolved == nil {
                        resolved = URL(dataRepresentation: data, relativeTo: nil)
                        print("🔵 [DROP] Fallback dataRepresentation: \(String(describing: resolved))")
                    }
                } else if let str = item as? String {
                    print("🔵 [DROP] Item is String: \(str)")
                    let cleaned = str.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
                    if cleaned.hasPrefix("file://") {
                        resolved = URL(string: cleaned)
                    } else if cleaned.hasPrefix("/") {
                        resolved = URL(fileURLWithPath: cleaned)
                    }
                } else {
                    print("🔵 [DROP] Item is unknown type: \(String(describing: item))")
                }
                print("🔵 [DROP] Resolved URL: \(String(describing: resolved)), isFileURL: \(resolved?.isFileURL ?? false)")
                guard let url = resolved, url.isFileURL else {
                    print("🔴 [DROP] FAILED — resolved URL is nil or not a file URL")
                    return
                }
                print("🟢 [DROP] SUCCESS — adding file: \(url.path)")
                DispatchQueue.main.async {
                    self.appState.addFiles(from: [url])
                    self.appState.selectedTab = .files
                }
            }
        }
    }
}

// MARK: - Import Option Button
struct ImportOptionButton: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium)).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(.black)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(isHovered ? 0.09 : 0.04), radius: isHovered ? 10 : 5, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
