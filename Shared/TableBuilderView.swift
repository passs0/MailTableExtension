import SwiftUI

/// Interactive table editor used inside the MailKit compose popover (and host app).
struct TableBuilderView: View {
    @State private var rowCount: Int = 3
    @State private var colCount: Int = 3
    @State private var cells: [[String]] = [
        ["Header 1", "Header 2", "Header 3"],
        ["Row 1", "Value", "Value"],
        ["Row 2", "Value", "Value"]
    ]
    @State private var options = HTMLTableGenerator.StyleOptions()
    @State private var importText: String = ""
    @State private var showingImporter: Bool = false
    @State private var copiedBanner: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerBar
            controlsBar

            if showingImporter {
                importerView
            } else {
                gridEditor
            }

            footerBar
        }
        .padding(14)
        .frame(minWidth: 440, minHeight: 340)
    }

    private var headerBar: some View {
        HStack {
            Label("Insert Table", systemImage: "tablecells")
                .font(.headline)
            Spacer()
            Button(showingImporter ? "Grid Editor" : "Paste CSV / Markdown") {
                showingImporter.toggle()
            }
            .buttonStyle(.link)
        }
    }

    private var controlsBar: some View {
        HStack(spacing: 16) {
            Stepper("Rows: \(rowCount)", value: $rowCount, in: 1...20)
                .onChange(of: rowCount) { _ in resizeGrid() }

            Stepper("Cols: \(colCount)", value: $colCount, in: 1...10)
                .onChange(of: colCount) { _ in resizeGrid() }

            Spacer()

            Toggle("Header", isOn: $options.hasHeaderRow)
            Toggle("Borders", isOn: $options.showBorders)
            Toggle("Stripes", isOn: $options.zebraStriping)
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
                                .frame(minWidth: 90)
                        }
                    }
                }
            }
            .padding(4)
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
                        rowCount = parsed.count
                        colCount = parsed.first?.count ?? 1
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
                Text("Click Copy, then press ⌘V in the Mail compose body.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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
                resizeGrid()
                cells[row][col] = newValue
            }
        )
    }

    private func resizeGrid() {
        while cells.count < rowCount {
            cells.append(Array(repeating: "", count: colCount))
        }
        if cells.count > rowCount {
            cells = Array(cells.prefix(rowCount))
        }
        for i in cells.indices {
            while cells[i].count < colCount {
                cells[i].append("")
            }
            if cells[i].count > colCount {
                cells[i] = Array(cells[i].prefix(colCount))
            }
        }
    }
}
