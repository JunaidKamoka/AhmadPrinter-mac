import AppKit
import PDFKit
import WebKit
import SwiftUI

final class PrintManager {

    static let shared = PrintManager()
    private init() {}

    // MARK: - Print Any File
    func printFile(_ file: PrintFile) {
        guard let url = file.fileURL else {
            showAlert("No file path available for \(file.name)")
            return
        }
        switch file.fileType {
        case .pdf:      printPDF(url: url)
        case .image:    printImage(url: url)
        case .text:     printTextFile(url: url)
        case .document: openWithDefaultApp(url: url)
        }
    }

    // MARK: - Print PDF
    func printPDF(url: URL) {
        guard let document = PDFDocument(url: url) else {
            showAlert("Could not open PDF: \(url.lastPathComponent)"); return
        }
        let printInfo = buildPrintInfo()
        if let op = document.printOperation(for: printInfo, scalingMode: .pageScaleDownToFit, autoRotate: true) {
            op.jobTitle = url.lastPathComponent
            op.showsPrintPanel = true
            op.run()
        } else {
            // Fallback: open in Preview
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Print Image
    func printImage(url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            showAlert("Could not load image: \(url.lastPathComponent)"); return
        }
        printNSImage(image, title: url.lastPathComponent)
    }

    func printNSImage(_ image: NSImage, title: String = "Image") {
        let printInfo = buildPrintInfo()
        let paperSize = printInfo.paperSize
        let margins = printInfo.leftMargin + printInfo.rightMargin
        let vMargins = printInfo.topMargin + printInfo.bottomMargin
        let printable = NSSize(width: paperSize.width - margins, height: paperSize.height - vMargins)
        let aspect = image.size.width / image.size.height
        var drawSize = printable
        if printable.width / aspect <= printable.height {
            drawSize.height = printable.width / aspect
        } else {
            drawSize.width = printable.height * aspect
        }
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: drawSize))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        let op = NSPrintOperation(view: imageView, printInfo: printInfo)
        op.jobTitle = title
        op.showsPrintPanel = true
        op.run()
    }

    // MARK: - Print Text
    func printText(_ text: String, title: String = "Document") {
        let printInfo = buildPrintInfo()
        let width  = printInfo.paperSize.width  - printInfo.leftMargin - printInfo.rightMargin
        let height = printInfo.paperSize.height - printInfo.topMargin  - printInfo.bottomMargin
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        textView.isEditable = false
        textView.string = text
        textView.font = NSFont.systemFont(ofSize: 12)
        textView.textColor = .black
        textView.backgroundColor = .white
        let op = NSPrintOperation(view: textView, printInfo: printInfo)
        op.jobTitle = title
        op.showsPrintPanel = true
        op.run()
    }

    func printTextFile(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            printText(text, title: url.lastPathComponent)
        } catch {
            showAlert("Could not read file: \(error.localizedDescription)")
        }
    }

    // MARK: - Print Web Page
    func printWebView(_ webView: WKWebView) {
        let printInfo = buildPrintInfo()
        let op = webView.printOperation(with: printInfo)
        // WKPrintingView requires a non-zero frame before knowsPageRange: is called
        if let opView = op.view, opView.frame.isEmpty {
            let paperSize = printInfo.paperSize
            let printableW = paperSize.width  - printInfo.leftMargin - printInfo.rightMargin
            let printableH = paperSize.height - printInfo.topMargin  - printInfo.bottomMargin
            opView.frame = NSRect(x: 0, y: 0, width: printableW, height: printableH)
        }
        op.showsPrintPanel = true
        op.run()
    }

    // MARK: - Print SwiftUI View as Document
    func printView<V: View>(_ view: V, title: String = "Document") {
        let printInfo = buildPrintInfo()
        let pageW = printInfo.paperSize.width  - printInfo.leftMargin - printInfo.rightMargin
        let pageH = printInfo.paperSize.height - printInfo.topMargin  - printInfo.bottomMargin

        let host = NSHostingView(rootView: view.frame(width: pageW).background(Color.white))

        // NSHostingView must be in a window to render properly
        let offscreenWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: pageW, height: pageH),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        offscreenWindow.contentView = host
        offscreenWindow.orderBack(nil)     // keeps it behind everything
        offscreenWindow.setFrameOrigin(NSPoint(x: -10000, y: -10000))

        // Measure true content height
        host.frame = NSRect(x: 0, y: 0, width: pageW, height: pageH)
        host.needsLayout = true
        host.layoutSubtreeIfNeeded()
        let naturalH = max(host.fittingSize.height, pageH)
        host.frame = NSRect(x: 0, y: 0, width: pageW, height: naturalH)
        offscreenWindow.setContentSize(NSSize(width: pageW, height: naturalH))
        host.needsLayout = true
        host.layoutSubtreeIfNeeded()

        // Force a display pass so content is rendered
        host.display()

        // Wrap in a paginating NSView so NSPrintOperation renders each page correctly
        let pageView = PaginatingHostView(inner: host, pageHeight: pageH)
        offscreenWindow.contentView = pageView
        offscreenWindow.setContentSize(pageView.frame.size)
        pageView.display()

        let op = NSPrintOperation(view: pageView, printInfo: printInfo)
        op.jobTitle = title
        op.showsPrintPanel = true
        op.run()

        // Clean up offscreen window
        offscreenWindow.orderOut(nil)
    }

    // MARK: - Export to PDF
    @discardableResult
    func exportToPDF<V: View>(_ view: V, title: String = "Document") -> URL? {
        let printInfo = buildPrintInfo()
        let pageW = printInfo.paperSize.width  - printInfo.leftMargin - printInfo.rightMargin
        let pageH = printInfo.paperSize.height - printInfo.topMargin  - printInfo.bottomMargin

        let host = NSHostingView(rootView: view.frame(width: pageW).background(Color.white))

        // NSHostingView must be in a window to render properly
        let offscreenWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: pageW, height: pageH),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        offscreenWindow.contentView = host
        offscreenWindow.orderBack(nil)
        offscreenWindow.setFrameOrigin(NSPoint(x: -10000, y: -10000))

        host.frame = NSRect(x: 0, y: 0, width: pageW, height: pageH)
        host.needsLayout = true
        host.layoutSubtreeIfNeeded()
        let naturalH = max(host.fittingSize.height, pageH)
        host.frame = NSRect(x: 0, y: 0, width: pageW, height: naturalH)
        offscreenWindow.setContentSize(NSSize(width: pageW, height: naturalH))
        host.needsLayout = true
        host.layoutSubtreeIfNeeded()
        host.display()

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(title).pdf"
        guard panel.runModal() == .OK, let url = panel.url else {
            offscreenWindow.orderOut(nil)
            return nil
        }

        // Build a proper multi-page PDF
        let data = buildMultiPagePDF(from: host, pageWidth: pageW, pageHeight: pageH)
        offscreenWindow.orderOut(nil)
        do {
            try data.write(to: url)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return url
        } catch {
            showAlert("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // Renders a full-height NSView into a multi-page PDF (each page = paper size)
    private func buildMultiPagePDF(from view: NSView, pageWidth: CGFloat, pageHeight: CGFloat) -> Data {
        let totalH    = view.bounds.height
        let pageCount = max(1, Int(ceil(totalH / pageHeight)))
        let pdfData   = NSMutableData()

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return view.dataWithPDF(inside: view.bounds)
        }
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return view.dataWithPDF(inside: view.bounds)
        }

        for page in 0..<pageCount {
            ctx.beginPage(mediaBox: &mediaBox)
            // NSHostingView is flipped (origin top-left), so page 0 is the top slice.
            // In Core Graphics (origin bottom-left) we flip and offset accordingly.
            let sliceY = CGFloat(page) * pageHeight   // flipped-space y of this page's top
            ctx.saveGState()
            ctx.translateBy(x: 0, y: pageHeight)
            ctx.scaleBy(x: 1, y: -1)
            ctx.translateBy(x: 0, y: -sliceY)
            let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: true)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = nsCtx
            view.draw(NSRect(x: 0, y: sliceY, width: pageWidth, height: pageHeight))
            NSGraphicsContext.restoreGraphicsState()
            ctx.restoreGState()
            ctx.endPage()
        }
        ctx.closePDF()
        return pdfData as Data
    }
}

// MARK: - PaginatingHostView
// Wraps an NSHostingView so NSPrintOperation can paginate it correctly.
private class PaginatingHostView: NSView {
    let pageH: CGFloat

    init(inner: NSView, pageHeight: CGFloat) {
        pageH = pageHeight
        super.init(frame: inner.frame)
        addSubview(inner)
        inner.frame = bounds
    }
    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSRange(location: 1, length: max(1, Int(ceil(bounds.height / pageH))))
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        NSRect(x: 0, y: CGFloat(page - 1) * pageH, width: bounds.width, height: pageH)
    }
}

extension PrintManager {

    // MARK: - Available Printers
    func availablePrinters() -> [NSPrinter] {
        NSPrinter.printerNames.compactMap { NSPrinter(name: $0) }
    }

    var defaultPrinterName: String {
        NSPrintInfo.shared.printer.name
    }

    func setDefaultPrinter(named name: String) {
        guard let printer = NSPrinter(name: name) else { return }
        NSPrintInfo.shared.printer = printer
    }

    // MARK: - Open Panel Helpers
    func openFinderPanel(allowedTypes: [UTType] = [.item], allowMultiple: Bool = true, completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = allowMultiple
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            completion(panel.urls)
        }
    }

    func openPhotosPanel(completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .jpeg, .png, .tiff, .heic, .gif, .bmp]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.directoryURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
        panel.message = "Select photos to print"
        if panel.runModal() == .OK {
            completion(panel.urls)
        }
    }

    func openICloudPanel(completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.item]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        // Try iCloud Drive
        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            panel.directoryURL = icloudURL.appendingPathComponent("Documents")
        } else {
            // Fallback: ubiquitous documents
            let ubiquitous = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            panel.directoryURL = ubiquitous
            panel.message = "Navigate to your iCloud Drive folder"
        }
        if panel.runModal() == .OK {
            completion(panel.urls)
        }
    }

    // MARK: - Private
    private func buildPrintInfo() -> NSPrintInfo {
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.leftMargin   = 36
        info.rightMargin  = 36
        info.topMargin    = 36
        info.bottomMargin = 36
        info.isHorizontallyCentered = true
        info.isVerticallyCentered   = false
        info.scalingFactor = 1.0
        return info
    }

    private func openWithDefaultApp(url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func showAlert(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Print Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}

import UniformTypeIdentifiers
