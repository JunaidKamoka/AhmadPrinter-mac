import SwiftUI
import Vision

struct OCRView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: NSImage? = nil
    @State private var imageURL: URL? = nil
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var error: String? = nil
    @State private var showFilePicker = false
    @State private var confidence: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──────────────────────────────────────
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("OCR — Extract Text from Image")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Button {
                    showFilePicker = true
                } label: {
                    Label("Open Image", systemImage: "photo.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                if selectedImage != nil {
                    Button {
                        Task { await runOCR() }
                    } label: {
                        Group {
                            if isProcessing {
                                ProgressView().controlSize(.small)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                            } else {
                                Label("Recognize Text", systemImage: "doc.viewfinder")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                            }
                        }
                        .background(Color.primaryRed)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                if !recognizedText.isEmpty {
                    Button {
                        PrintManager.shared.printText(recognizedText, title: "OCR Result")
                    } label: {
                        Label("Print Text", systemImage: "printer.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(recognizedText, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.gray.opacity(0.15))
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if let err = error {
                Text(err).foregroundStyle(.red).font(.system(size: 13))
                    .padding(12).frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.07))
            }

            // ── Content ───────────────────────────────────────
            HSplitView {
                // Left: Image
                ZStack {
                    Color(nsColor: .controlBackgroundColor)
                    if let img = selectedImage {
                        Image(nsImage: img)
                            .resizable().scaledToFit()
                            .padding(20)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 48)).foregroundStyle(Color.primaryRed.opacity(0.4))
                            Text("Select an image to extract text")
                                .font(.system(size: 14)).foregroundStyle(.secondary)
                            Button("Choose Image") { showFilePicker = true }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Color.primaryRed)
                                .clipShape(Capsule())
                                .buttonStyle(.plain)
                        }
                    }
                    if isProcessing {
                        Color.black.opacity(0.35)
                        VStack(spacing: 12) {
                            ProgressView().controlSize(.large).tint(.white)
                            Text("Recognizing text…").foregroundStyle(.white).font(.system(size: 14))
                        }
                    }
                }
                .frame(minWidth: 350)

                // Right: Text result
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Recognized Text")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                        if !confidence.isEmpty {
                            Text("· \(confidence)")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !recognizedText.isEmpty {
                            Text("\(recognizedText.split(separator: " ").count) words")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

                    Divider()

                    TextEditor(text: $recognizedText)
                        .font(.system(size: 13))
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                }
                .frame(minWidth: 350)
                .background(Color.white)
            }
        }
        .frame(minWidth: 800, minHeight: 580)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image, .jpeg, .png, .tiff, .heic, .bmp, .gif],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                imageURL = url
                selectedImage = NSImage(contentsOf: url)
                recognizedText = ""
                error = nil
            }
        }
    }

    private func runOCR() async {
        guard let img = selectedImage else { return }
        isProcessing = true
        error = nil
        do {
            let text = try await OCRManager.shared.recognizeText(in: img)
            recognizedText = text
        } catch {
            self.error = error.localizedDescription
        }
        isProcessing = false
    }
}
