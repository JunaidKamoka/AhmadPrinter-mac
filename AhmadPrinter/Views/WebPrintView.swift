import SwiftUI
import WebKit

struct WebPrintView: View {
    @Environment(\.dismiss) var dismiss
    @State private var urlText = "https://"
    @State private var isLoading = false
    @State private var pageTitle = ""
    @State private var loadError: String? = nil
    @State private var webViewRef: WKWebView? = nil
    @State private var loadTrigger: UUID? = nil   // drives navigation

    var body: some View {
        VStack(spacing: 0) {
            // -- Toolbar --
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                // Back / Forward
                HStack(spacing: 4) {
                    Button { webViewRef?.goBack() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(webViewRef?.canGoBack == true ? Color.primary : Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .disabled(webViewRef?.canGoBack != true)

                    Button { webViewRef?.goForward() } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(webViewRef?.canGoForward == true ? Color.primary : Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .disabled(webViewRef?.canGoForward != true)

                    Button { webViewRef?.reload() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    Image(systemName: "globe").foregroundStyle(.secondary)
                    TextField("Enter URL", text: $urlText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .onSubmit { loadURL() }
                    if isLoading {
                        ProgressView().controlSize(.small)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Go") { loadURL() }
                    .font(.system(size: 13, weight: .semibold))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.primaryRed).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                if !pageTitle.isEmpty {
                    Text(pageTitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 180)
                }

                Button {
                    if let wv = webViewRef {
                        PrintManager.shared.printWebView(wv)
                    }
                } label: {
                    Label("Print Page", systemImage: "printer.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.primaryRed.opacity(webViewRef == nil ? 0.4 : 1))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(webViewRef == nil)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            if let err = loadError {
                Text(err).font(.system(size: 13)).foregroundStyle(.red)
                    .padding(12).frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.08))
            }

            Divider()

            // -- Web View --
            WebViewRepresentable(
                loadTrigger: loadTrigger,
                urlString: urlText,
                isLoading: $isLoading,
                pageTitle: $pageTitle,
                loadError: $loadError,
                webViewRef: $webViewRef
            )
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.white)
    }

    private func loadURL() {
        loadError = nil
        var raw = urlText.trimmingCharacters(in: .whitespaces)
        if !raw.hasPrefix("http://") && !raw.hasPrefix("https://") {
            raw = "https://" + raw
        }
        urlText = raw
        loadTrigger = UUID()   // fires navigation
    }
}

// MARK: - WKWebView Representable
struct WebViewRepresentable: NSViewRepresentable {
    let loadTrigger: UUID?
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    @Binding var loadError: String?
    @Binding var webViewRef: WKWebView?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = true
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true
        DispatchQueue.main.async { self.webViewRef = wv }
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        // Only navigate when loadTrigger changes
        guard let trigger = loadTrigger,
              trigger != context.coordinator.lastTrigger else { return }
        context.coordinator.lastTrigger = trigger

        guard let url = URL(string: urlString), url.scheme != nil else {
            DispatchQueue.main.async { self.loadError = "Invalid URL" }
            return
        }
        wv.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable
        var lastTrigger: UUID?
        init(_ p: WebViewRepresentable) { parent = p }

        func webView(_ wv: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = true; self.parent.loadError = nil }
        }
        func webView(_ wv: WKWebView, didFinish _: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.pageTitle = wv.title ?? ""
            }
        }
        func webView(_ wv: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }
        func webView(_ wv: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }
    }
}
