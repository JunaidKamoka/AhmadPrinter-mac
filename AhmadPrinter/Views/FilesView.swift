import SwiftUI

struct FilesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showFilePicker = false
    @State private var searchText = ""
    @State private var showWebPrint  = false
    @State private var showTextPrint = false
    @State private var showOCR       = false

    private let fileColumns = [GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)]

    private var filteredFiles: [PrintFile] {
        if searchText.isEmpty { return appState.recentFiles }
        return appState.recentFiles.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Import From
                VStack(alignment: .leading, spacing: 14) {
                    Text("Import From")
                        .font(.system(size: 20, weight: .bold)).foregroundStyle(.black)

                    HStack(spacing: 14) {
                        ImportSourceCard(icon: "desktopcomputer", title: "Finder",
                                         subtitle: "Browse your Mac for files") {
                            PrintManager.shared.openFinderPanel { urls in appState.addFiles(from: urls) }
                        }
                        ImportSourceCard(icon: "photo.on.rectangle.angled", title: "Photos",
                                         subtitle: "Select from your photo library") {
                            PrintManager.shared.openPhotosPanel { urls in appState.addFiles(from: urls) }
                        }
                        ImportSourceCard(icon: "icloud.fill", title: "iCloud",
                                         subtitle: "Access files from iCloud") {
                            PrintManager.shared.openICloudPanel { urls in appState.addFiles(from: urls) }
                        }
                    }
                }

                // Files header + search
                HStack {
                    Text("Files").font(.system(size: 20, weight: .bold)).foregroundStyle(.black)
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 13))
                        TextField("Search files...", text: $searchText)
                            .textFieldStyle(.plain).font(.system(size: 13)).frame(width: 180)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color.white).clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                }

                // Grid
                if filteredFiles.isEmpty {
                    EmptyFilesView { showFilePicker = true }
                } else {
                    LazyVGrid(columns: fileColumns, spacing: 16) {
                        ForEach(filteredFiles) { file in
                            FileCardView(
                                file: file,
                                onDelete: { appState.removeFile(file) },
                                onPrint:  { appState.printer.printFile(file) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 24)
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
}

// MARK: - Import Source Card
struct ImportSourceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.primaryRed.opacity(0.1)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 22)).foregroundStyle(Color.primaryRed)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(.black)
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Empty State
struct EmptyFilesView: View {
    var onAddFile: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48)).foregroundStyle(Color.primaryRed.opacity(0.4))
            Text("No files yet").font(.system(size: 16, weight: .semibold)).foregroundStyle(.secondary)
            Button("Add Files") { onAddFile() }
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Color.primaryRed).clipShape(Capsule()).buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity).frame(height: 220)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
