import Vision
import AppKit
import Combine

final class OCRManager: ObservableObject {

    static let shared = OCRManager()
    private init() {}

    enum OCRError: LocalizedError {
        case invalidImage
        case noTextFound
        case visionError(String)

        var errorDescription: String? {
            switch self {
            case .invalidImage:   return "Could not read the image."
            case .noTextFound:    return "No text detected in the image."
            case .visionError(let msg): return msg
            }
        }
    }

    // MARK: - Recognize Text (async)
    func recognizeText(in image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error.localizedDescription))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                if text.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: text)
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "fr-FR", "de-DE", "it-IT"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.visionError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Recognize Text from URL
    func recognizeText(at url: URL) async throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw OCRError.invalidImage
        }
        return try await recognizeText(in: image)
    }

    // MARK: - Detect Language
    func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}

import NaturalLanguage
