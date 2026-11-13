import SwiftUI
import UniformTypeIdentifiers

/// Interactive table editor used inside the MailKit compose popover (and host app).
struct TableBuilderView: View {
    @State private var cells: [[String]] = [
        ["Header 1", "Header 2", "Header 3"],
        ["Row 1", "Value", "Value"],
        ["Row 2", "Value", "Value"]
    ]
    @State private var options = HTMLTableGenerator.StyleOptions()
    @State private var selectedRow: Int = 0
    @State private var selectedCol: Int = 0
    @State private var importText: String = ""
    @State private var showingImporter: Bool = false
    @State private var copiedBanner: Bool = false

    private var rowCount: Int { cells.count }
    private var colCount: Int { cells.first?.count ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBar
            structureBar
            styleBar

            if showingImporter {
                importerView
            } else {
                gridEditor
            }

            footerBar
        }
        .padding(14)
        .frame(minWidth: 500, minHeight: 380)
    }

    private var headerBar: some View {
        HStack {
            Label("Insert Table", systemImage: "table")
                .font(.headline)
            Spacer()
            Button(showingImporter ? "Grid Editor" : "Paste CSV / Markdown") {
                showingImporter.toggle()
            }
            .buttonStyle(.link)
        }
    }

    private var structureBar: some View {
        HStack(spacing: 8) {
            Group {
                Button { insertRow(at: selectedRow) } label: {
                    Label("Row Above", systemImage: "arrow.up.to.line")
                }
                Button { insertRow(at: selectedRow + 1) } label: {
                    Label("Row Below", systemImage: "arrow.down.to.line")
                }
                Button { deleteRow(at: selectedRow) } label: {
                    Label("Del Row", systemImage: "minus.circle")
                }
                .disabled(rowCount <= 1)
            }

            Divider().frame(height: 16)

            Group {
                Button { insertColumn(at: selectedCol) } label: {
                    Label("Col Left", systemImage: "arrow.left.to.line")
                }
                Button { insertColumn(at: selectedCol + 1) } label: {
                    Label("Col Right", systemImage: "arrow.right.to.line")
                }
                Button { deleteColumn(at: selectedCol) } label: {
                    Label("Del Col", systemImage: "minus.circle")
                }
                .disabled(colCount <= 1)
            }
        }
        .font(.caption)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var styleBar: some View {
        HStack(spacing: 14) {
            Text("\(rowCount) × \(colCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Toggle("Header", isOn: $options.hasHeaderRow)
            Toggle("Borders", isOn: $options.showBorders)
            Toggle("Stripes", isOn: $options.zebraStriping)

            Spacer()

            Button("Clear") {
                cells = Array(
                    repeating: Array(repeating: "", count: max(colCount, 1)),
                    count: max(rowCount, 1)
                )
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
        .font(.caption)
    }

    private var gridEditor: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(0..<rowCount, id: \.self) { r in
                    GridRow {
                        ForEach(0..<colCount, id: \.self) { c in
                            TextField("", text: bindingForCell(row: r, col: c))
                                .textFieldStyle(.roundedBorder)
                                .font(
                                    options.hasHeaderRow && r == 0
                                    ? .system(size: 12, weight: .semibold)
                                    : .system(size: 12)
                                )
                                .frame(minWidth: 95)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(
                                            (r == selectedRow && c == selectedCol)
                                            ? Color.accentColor.opacity(0.6)
                                            : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                                .onTapGesture {
                                    selectedRow = r
                                    selectedCol = c
                                }
                        }
                    }
                }
            }
            .padding(6)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }

    private var importerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste Markdown pipe table, TSV, or CSV:")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $importText)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )
            HStack {
                Spacer()
                Button("Load into Grid") {
                    let parsed = HTMLTableGenerator.parseText(importText)
                    if !parsed.isEmpty {
                        cells = parsed
                        selectedRow = 0
                        selectedCol = 0
                        showingImporter = false
                    }
                }
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var footerBar: some View {
        HStack {
            if copiedBanner {
                Label("Copied! Press ⌘V in your email.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Click Copy (or drag this badge) into Mail's compose body.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("Drag Table", systemImage: "hand.draw")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onDrag {
                    let html = HTMLTableGenerator.makeHTML(rows: cells, options: options)
                    let provider = NSItemProvider()
                    if let htmlData = html.data(using: .utf8),
                       let attributed = try? NSAttributedString(
                           data: htmlData,
                           options: [
                               .documentType: NSAttributedString.DocumentType.html,
                               .characterEncoding: String.Encoding.utf8.rawValue
                           ],
                           documentAttributes: nil
                       ),
                       let rtfData = try? attributed.data(
                           from: NSRange(location: 0, length: attributed.length),
                           documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                       ) {
                        provider.registerDataRepresentation(
                            forTypeIdentifier: UTType.rtf.identifier,
                            visibility: .all
                        ) { completion in
                            completion(rtfData, nil)
                            return nil
                        }
                    }
                    return provider
                }

            Button("Copy Table") {
                if HTMLTableGenerator.copyToPasteboard(rows: cells, options: options) {
                    copiedBanner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        copiedBanner = false
                    }
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(.borderedProminent)
        }
    }

    private func bindingForCell(row: Int, col: Int) -> Binding<String> {
        Binding(
            get: {
                guard row < cells.count, col < cells[row].count else { return "" }
                return cells[row][col]
            },
            set: { newValue in
                guard row < cells.count, col < cells[row].count else { return }
                cells[row][col] = newValue
            }
        )
    }

    private func insertRow(at index: Int) {
        let clamped = max(0, min(index, cells.count))
        cells.insert(Array(repeating: "", count: max(colCount, 1)), at: clamped)
        selectedRow = clamped
    }

    private func deleteRow(at index: Int) {
        guard cells.count > 1, index >= 0, index < cells.count else { return }
        cells.remove(at: index)
        selectedRow = min(selectedRow, cells.count - 1)
    }

    private func insertColumn(at index: Int) {
        let clamped = max(0, min(index, colCount))
        for r in cells.indices {
            cells[r].insert("", at: clamped)
        }
        selectedCol = clamped
    }

    private func deleteColumn(at index: Int) {
        guard colCount > 1, index >= 0, index < colCount else { return }
        for r in cells.indices {
            cells[r].remove(at: index)
        }
        selectedCol = min(selectedCol, colCount - 1)
    }
}
