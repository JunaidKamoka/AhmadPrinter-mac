import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct PrintFile: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var date: Date
    var thumbnail: NSImage?
    var fileURL: URL?
    var fileType: FileType

    enum FileType: String {
        case pdf      = "PDF"
        case image    = "Image"
        case document = "Document"
        case text     = "Text"

        var sfSymbol: String {
            switch self {
            case .pdf:      return "doc.richtext.fill"
            case .image:    return "photo.fill"
            case .document: return "doc.fill"
            case .text:     return "doc.text.fill"
            }
        }

        var color: Color {
            switch self {
            case .pdf:      return .red
            case .image:    return .blue
            case .document: return .indigo
            case .text:     return .gray
            }
        }

        static func detect(url: URL) -> FileType {
            switch url.pathExtension.lowercased() {
            case "pdf":                                        return .pdf
            case "png","jpg","jpeg","heic","tiff","bmp","gif": return .image
            case "txt","rtf","md":                             return .text
            default:                                           return .document
            }
        }
    }

    static func == (lhs: PrintFile, rhs: PrintFile) -> Bool { lhs.id == rhs.id }
}
