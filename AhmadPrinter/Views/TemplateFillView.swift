import SwiftUI

struct TemplateFillView: View {
    @Environment(\.dismiss) var dismiss
    @State var template: PrintTemplate
    @State private var showPrintPreview = false

    var body: some View {
        HSplitView {
            // ── Left: Form ────────────────────────────────────
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .bold))
                        HStack(spacing: 6) {
                            Image(systemName: PrintTemplate.Category(rawValue: template.category.rawValue)?.icon ?? "doc.fill")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                            Text(template.category.rawValue)
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                            Text("·").foregroundStyle(.secondary)
                            Text(template.country)
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button { clearAll() } label: {
                        Text("Clear All")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Fields
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(template.sections.indices, id: \.self) { sIdx in
                            FormSection(
                                section: $template.sections[sIdx]
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .frame(minWidth: 340, maxWidth: 440)
            .background(Color(nsColor: .controlBackgroundColor))

            // ── Right: Preview + Print ─────────────────────────
            VStack(spacing: 0) {
                // Preview toolbar
                HStack {
                    Text("Preview").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()

                    Button {
                        PrintManager.shared.printView(
                            TemplateDocumentView(template: template),
                            title: template.name
                        )
                    } label: {
                        Label("Print", systemImage: "printer.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.primaryRed)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        PrintManager.shared.exportToPDF(
                            TemplateDocumentView(template: template),
                            title: template.name
                        )
                    } label: {
                        Label("Export PDF", systemImage: "arrow.down.doc.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Document preview
                ScrollView {
                    TemplateDocumentView(template: template)
                        .frame(width: 540)
                        .background(Color.white)
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                        .padding(32)
                }
                .background(Color(red: 0.88, green: 0.88, blue: 0.88))
            }
            .frame(minWidth: 580)
        }
        .frame(minWidth: 940, minHeight: 620)
    }

    private func clearAll() {
        for sIdx in template.sections.indices {
            for fIdx in template.sections[sIdx].fields.indices {
                template.sections[sIdx].fields[fIdx].value = ""
            }
        }
    }
}

// MARK: - Form Section
struct FormSection: View {
    @Binding var section: TemplateSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.primaryRed)
                .padding(.bottom, 2)

            ForEach(section.fields.indices, id: \.self) { idx in
                FieldInput(field: $section.fields[idx])
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Individual Field Input
struct FieldInput: View {
    @Binding var field: TemplateField

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3) {
                Text(field.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.black.opacity(0.7))
                if field.isRequired {
                    Text("*").foregroundStyle(.red).font(.system(size: 11))
                }
            }

            switch field.fieldType {
            case .multiLine:
                ZStack(alignment: .topLeading) {
                    if field.value.isEmpty {
                        Text(field.placeholder)
                            .foregroundStyle(.secondary.opacity(0.6))
                            .font(.system(size: 13))
                            .padding(.top, 8).padding(.leading, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $field.value)
                        .font(.system(size: 13))
                        .frame(minHeight: 64, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.1), lineWidth: 1))

            case .date:
                DateFieldInput(value: $field.value, placeholder: field.placeholder)

            case .currency:
                HStack {
                    Text(currencySymbol).font(.system(size: 13)).foregroundStyle(.secondary)
                    TextField(field.placeholder, text: $field.value)
                        .textFieldStyle(.plain).font(.system(size: 13))
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.1), lineWidth: 1))

            default:
                TextField(field.placeholder, text: $field.value)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.1), lineWidth: 1))
            }
        }
    }

    private var currencySymbol: String {
        if field.label.contains("£") { return "£" }
        if field.label.contains("€") { return "€" }
        if field.label.contains("CA$") { return "CA$" }
        return "$"
    }
}

struct DateFieldInput: View {
    @Binding var value: String
    let placeholder: String
    @State private var date: Date = Date()
    @State private var showPicker = false

    var body: some View {
        HStack {
            TextField(placeholder, text: $value)
                .textFieldStyle(.plain).font(.system(size: 13))
            Button { showPicker.toggle() } label: {
                Image(systemName: "calendar").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPicker) {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .onChange(of: date) { _, d in
                        let f = DateFormatter()
                        f.dateStyle = .medium
                        value = f.string(from: d)
                        showPicker = false
                    }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Document Render View (used for preview AND printing)
struct TemplateDocumentView: View {
    let template: PrintTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Letterhead
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name.uppercased())
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.primaryRed)
                        Text(template.country)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    // Print date
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Smart Printer")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Rectangle().fill(Color.primaryRed).frame(height: 2)
            }
            .padding(.bottom, 20)

            // Sections
            ForEach(template.sections) { section in
                let filled = section.fields.filter { !$0.value.isEmpty }
                if !filled.isEmpty {
                    DocumentSection(section: section)
                }
            }

            Spacer(minLength: 40)

            // Footer
            VStack(spacing: 4) {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                HStack {
                    Text("Generated by Smart Printer")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                    Spacer()
                    Text(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}

struct DocumentSection: View {
    let section: TemplateSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.primaryRed.opacity(0.8))
                .tracking(1.2)
                .padding(.bottom, 2)

            ForEach(section.fields) { field in
                if !field.value.isEmpty {
                    DocumentFieldRow(field: field)
                }
            }
        }
        .padding(.bottom, 16)
    }
}

struct DocumentFieldRow: View {
    let field: TemplateField

    var body: some View {
        if field.fieldType == .multiLine {
            VStack(alignment: .leading, spacing: 3) {
                Text(field.label + ":")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(field.value)
                    .font(.system(size: 11))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 8)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        } else {
            HStack(alignment: .top) {
                Text(field.label + ":")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 140, alignment: .leading)
                Text(field.value)
                    .font(.system(size: 11))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
