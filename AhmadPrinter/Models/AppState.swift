import SwiftUI
import Combine
import UniformTypeIdentifiers

enum NavigationTab: String, CaseIterable {
    case home      = "home"
    case files     = "files"
    case templates = "templates"
}

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab:     NavigationTab = .home
    @Published var recentFiles:     [PrintFile]   = []
    @Published var selectedCountry: String        = "USA"
    @Published var showPaywall:     Bool           = false
    @Published var showSettings:    Bool           = false
    @Published var isDraggingOver:  Bool           = false

    let countries          = PrintTemplate.allCountries
    let templateCategories = PrintTemplate.Category.allCases.map(\.rawValue)

    // Managers (accessed on main actor)
    let store   = StoreKitManager.shared
    let printer = PrintManager.shared
    let ocr     = OCRManager.shared

    var isPro: Bool { store.isPro }

    // MARK: - File Operations
    func addFile(_ file: PrintFile) {
        guard !recentFiles.contains(where: { $0.id == file.id }) else { return }
        recentFiles.insert(file, at: 0)
    }

    func addFiles(from urls: [URL]) {
        print("🔵 [ADD] addFiles called with \(urls.count) URL(s): \(urls.map(\.path))")
        for url in urls {
            print("🔵 [ADD] File exists: \(FileManager.default.fileExists(atPath: url.path)), readable: \(FileManager.default.isReadableFile(atPath: url.path))")
            let type = PrintFile.FileType.detect(url: url)
            print("🔵 [ADD] Detected type: \(type) for \(url.lastPathComponent)")
            let file = PrintFile(name: url.lastPathComponent, date: Date(), fileURL: url, fileType: type)
            addFile(file)
            generateThumbnailAsync(for: url)
        }
        print("🔵 [ADD] recentFiles count after add: \(recentFiles.count)")
    }

    private func generateThumbnailAsync(for url: URL) {
        Task {
            let thumb = await Task.detached(priority: .background) {
                generateThumbnail(url: url)
            }.value
            if let idx = recentFiles.firstIndex(where: { $0.fileURL == url }) {
                recentFiles[idx].thumbnail = thumb
            }
        }
    }

    func removeFile(_ file: PrintFile) {
        recentFiles.removeAll { $0.id == file.id }
    }
}

// MARK: - Thumbnail Generation
func generateThumbnail(url: URL) -> NSImage? {
    let ext = url.pathExtension.lowercased()
    if ["png","jpg","jpeg","heic","tiff","bmp","gif","webp"].contains(ext) {
        return NSImage(contentsOf: url)
    }
    if ext == "pdf" {
        guard let doc = CGPDFDocument(url as CFURL),
              let page = doc.page(at: 1) else { return nil }
        let rect  = page.getBoxRect(.mediaBox)
        let scale: CGFloat = min(200 / rect.width, 200 / rect.height)
        let size  = CGSize(width: rect.width * scale, height: rect.height * scale)
        let img   = NSImage(size: size)
        img.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.scaleBy(x: scale, y: scale)
            ctx.drawPDFPage(page)
        }
        img.unlockFocus()
        return img
    }
    return nil
}
