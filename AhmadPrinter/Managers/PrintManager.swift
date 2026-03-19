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
        op.showsPrintPanel = true
        op.run()
    }

    // MARK: - Print SwiftUI View as Document
    func printView<V: View>(_ view: V, title: String = "Document") {
        let printInfo = buildPrintInfo()
        let width  = printInfo.paperSize.width  - printInfo.leftMargin - printInfo.rightMargin
        let height = printInfo.paperSize.height - printInfo.topMargin  - printInfo.bottomMargin
        let host = NSHostingView(rootView: view.frame(width: width).background(Color.white))
        host.frame = NSRect(x: 0, y: 0, width: width, height: height)
        let op = NSPrintOperation(view: host, printInfo: printInfo)
        op.jobTitle = title
        op.showsPrintPanel = true
        op.run()
    }

    // MARK: - Export to PDF
    @discardableResult
    func exportToPDF<V: View>(_ view: V, title: String = "Document") -> URL? {
        let printInfo = buildPrintInfo()
        let width  = printInfo.paperSize.width  - printInfo.leftMargin - printInfo.rightMargin
        let height = printInfo.paperSize.height - printInfo.topMargin  - printInfo.bottomMargin
        let host = NSHostingView(rootView: view.frame(width: width).background(Color.white))
        host.frame = NSRect(x: 0, y: 0, width: width, height: height)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(title).pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        let data = host.dataWithPDF(inside: host.bounds)
        do {
            try data.write(to: url)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return url
        } catch {
            showAlert("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

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
