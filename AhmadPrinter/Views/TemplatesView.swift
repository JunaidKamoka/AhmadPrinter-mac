import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTemplate: PrintTemplate? = nil
    @State private var searchText = ""

    private var filteredTemplates: [PrintTemplate] {
        let byCountry = PrintTemplate.templates(for: appState.selectedCountry)
        if searchText.isEmpty { return byCountry }
        return byCountry.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func templates(for categoryName: String) -> [PrintTemplate] {
        filteredTemplates.filter { $0.category.rawValue == categoryName }
    }

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 170), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(.plain).font(.system(size: 13))
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                .frame(maxWidth: 360)
                Spacer()
            }
            .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Country pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(appState.countries, id: \.self) { country in
                                CountryPill(country: country, isSelected: appState.selectedCountry == country) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        appState.selectedCountry = country
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Categories
                    ForEach(PrintTemplate.Category.allCases, id: \.self) { cat in
                        let items = templates(for: cat.rawValue)
                        if !items.isEmpty {
                            CategorySection(category: cat, templates: items, columns: columns) { tpl in
                                if tpl.isPremium && !appState.isPro {
                                    appState.showPaywall = true
                                } else {
                                    selectedTemplate = tpl
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 12)
            }
        }
        .sheet(item: $selectedTemplate) { tpl in
            TemplateFillView(template: tpl)
                .environmentObject(appState)
        }
    }
}

// MARK: - Country Pill
struct CountryPill: View {
    let country: String
    let isSelected: Bool
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(country)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .black)
                .padding(.horizontal, 22).padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.primaryRed : (isHovered ? Color.black.opacity(0.07) : Color.white)))
                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: PrintTemplate.Category
    let templates: [PrintTemplate]
    let columns: [GridItem]
    var onSelect: (PrintTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primaryRed)
                Text(category.rawValue)
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.black)
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(templates) { tpl in
                    TemplateCardView(template: tpl) { onSelect(tpl) }
                }
            }
        }
    }
}
