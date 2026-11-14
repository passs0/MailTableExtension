import SwiftUI

/// Interactive Apple Numbers-inspired table editor used inside the MailKit compose popover and host app.
struct TableBuilderView: View {
    private enum EditorMode: String, CaseIterable, Identifiable {
        case grid = "Editor"
        case importer = "Import"

        var id: String { rawValue }

        var symbolName: String {
            switch self {
            case .grid: return "tablecells"
            case .importer: return "doc.on.clipboard"
            }
        }
    }

    private struct CellCoord: Hashable {
        let row: Int
        let col: Int
    }

    @State private var cells: [[String]] = [
        ["Item", "Owner", "Status"],
        ["Design Review", "Alex", "Ready"],
        ["Release Notes", "Sam", "In Progress"]
    ]
    @State private var options = HTMLTableGenerator.StyleOptions()
    @State private var selectedRow: Int = 0
    @State private var selectedCol: Int = 0
    @State private var mode: EditorMode = .grid
    @State private var importText: String = ""
    @State private var copiedBanner: Bool = false
    @FocusState private var focusedCell: CellCoord?

    private var rowCount: Int { cells.count }
    private var colCount: Int { cells.first?.count ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerBar
            if mode == .grid {
                toolbarBar
                gridEditor
            } else {
                importerView
            }
            footerBar
        }
        .padding(16)
        .frame(minWidth: 540, minHeight: 400)
        .onChange(of: focusedCell) { newValue in
            if let coord = newValue {
                selectedRow = coord.row
                selectedCol = coord.col
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            Label("Cellmate", systemImage: "tablecells")
                .font(.headline)

            Text("\(rowCount) × \(colCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color(nsColor: .quaternaryLabelColor).opacity(0.25))
                .clipShape(Capsule())

            Spacer()

            Picker("", selection: $mode) {
                ForEach(EditorMode.allCases) { item in
                    Label(item.rawValue, systemImage: item.symbolName)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 170)
        }
    }

    // MARK: - Toolbar

    private var toolbarBar: some View {
        HStack(spacing: 10) {
            ControlGroup {
                Button { insertRow(at: selectedRow) } label: {
                    Image(systemName: "arrow.up.to.line")
                }
                .help("Insert Row Above")
                .accessibilityLabel("Insert Row Above")

                Button { insertRow(at: selectedRow + 1) } label: {
                    Image(systemName: "arrow.down.to.line")
                }
                .help("Insert Row Below")
                .accessibilityLabel("Insert Row Below")

                Button { deleteRow(at: selectedRow) } label: {
                    Image(systemName: "minus")
                }
                .disabled(rowCount <= 1)
                .help("Delete Selected Row")
                .accessibilityLabel("Delete Selected Row")
            }

            ControlGroup {
                Button { insertColumn(at: selectedCol) } label: {
                    Image(systemName: "arrow.left.to.line")
                }
                .help("Insert Column Left")
                .accessibilityLabel("Insert Column Left")

                Button { insertColumn(at: selectedCol + 1) } label: {
                    Image(systemName: "arrow.right.to.line")
                }
                .help("Insert Column Right")
                .accessibilityLabel("Insert Column Right")

                Button { deleteColumn(at: selectedCol) } label: {
                    Image(systemName: "minus")
                }
                .disabled(colCount <= 1)
                .help("Delete Selected Column")
                .accessibilityLabel("Delete Selected Column")
            }

            Picker("", selection: $options.alignment) {
                ForEach(HTMLTableGenerator.CellAlignment.allCases) { alignment in
                    Image(systemName: alignment.symbolName)
                        .tag(alignment)
                        .help("Align \(alignment.rawValue)")
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 104)

            Spacer()

            Menu {
                Section("Table Style") {
                    ForEach(HTMLTableGenerator.TableTheme.allCases) { theme in
                        Button {
                            options.theme = theme
                        } label: {
                            if options.theme == theme {
                                Label(theme.rawValue, systemImage: "checkmark")
                            } else {
                                Text(theme.rawValue)
                            }
                        }
                    }
                }

                Divider()

                Toggle("Header Row", isOn: $options.hasHeaderRow)
                Toggle("Cell Borders", isOn: $options.showBorders)
                Toggle("Zebra Stripes", isOn: $options.zebraStriping)

                Divider()

                Button(role: .destructive) {
                    clearAllCells()
                } label: {
                    Label("Clear All Cells", systemImage: "eraser")
                }
            } label: {
                Label(options.theme.rawValue, systemImage: "paintbrush")
            }
            .menuStyle(.borderedButton)
            .fixedSize()
        }
        .controlSize(.small)
    }

    // MARK: - Grid Editor

    private var gridEditor: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<colCount, id: \.self) { col in
                            cellView(row: row, col: col)
                            if col < colCount - 1 {
                                verticalGridDivider(isHeader: options.hasHeaderRow && row == 0)
                            }
                        }
                    }
                    if row < rowCount - 1 {
                        horizontalGridDivider(isHeaderBottom: options.hasHeaderRow && row == 0)
                    }
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .padding(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cellView(row: Int, col: Int) -> some View {
        let isHeader = options.hasHeaderRow && row == 0
        let isSelected = row == selectedRow && col == selectedCol
        let coord = CellCoord(row: row, col: col)

        return TextField("", text: bindingForCell(row: row, col: col))
            .textFieldStyle(.plain)
            .multilineTextAlignment(options.alignment.textAlignment)
            .font(
                isHeader
                ? .system(size: 12.5, weight: .semibold)
                : .system(size: 12.5, weight: .regular)
            )
            .foregroundStyle(isHeader ? options.theme.previewHeaderForeground : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(minWidth: 112, maxWidth: .infinity, alignment: frameAlignment)
            .background(cellBackground(row: row, isHeader: isHeader))
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .focused($focusedCell, equals: coord)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedRow = row
                selectedCol = col
                focusedCell = coord
            }
    }

    private var frameAlignment: Alignment {
        switch options.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private func cellBackground(row: Int, isHeader: Bool) -> Color {
        if isHeader {
            return options.theme.previewHeaderBackground
        }
        if options.zebraStriping && row % 2 == 0 {
            return Color.primary.opacity(0.035)
        }
        return Color.clear
    }

    @ViewBuilder
    private func verticalGridDivider(isHeader: Bool) -> some View {
        if options.theme == .minimal || !options.showBorders {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.25))
                .frame(width: 1)
        } else {
            Rectangle()
                .fill(isHeader && (options.theme == .appleBlue || options.theme == .graphite)
                      ? Color.white.opacity(0.22)
                      : Color(nsColor: .separatorColor))
                .frame(width: 1)
        }
    }

    @ViewBuilder
    private func horizontalGridDivider(isHeaderBottom: Bool) -> some View {
        if isHeaderBottom && options.theme == .minimal {
            Rectangle()
                .fill(Color.primary.opacity(0.65))
                .frame(height: 1.5)
        } else if options.showBorders {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
        } else {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.25))
                .frame(height: 1)
        }
    }

    // MARK: - Importer

    private var importerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste a Markdown pipe table, tab-separated spreadsheet rows, or CSV:")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $importText)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )

            HStack {
                Spacer()
                Button {
                    let parsed = HTMLTableGenerator.parseText(importText)
                    if !parsed.isEmpty {
                        cells = parsed
                        selectedRow = 0
                        selectedCol = 0
                        mode = .grid
                    }
                } label: {
                    Label("Load into Editor", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            if copiedBanner {
                Label("Copied — press ⌘V in Mail", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            } else {
                Text("Press ⌘↩ to copy, then ⌘V in your email.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if HTMLTableGenerator.copyToPasteboard(rows: cells, options: options) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        copiedBanner = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            copiedBanner = false
                        }
                    }
                }
            } label: {
                Label(copiedBanner ? "Copied" : "Copy Table", systemImage: copiedBanner ? "checkmark" : "doc.on.doc")
            }
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Grid Mutations

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
        focusedCell = CellCoord(row: clamped, col: selectedCol)
    }

    private func deleteRow(at index: Int) {
        guard cells.count > 1, index >= 0, index < cells.count else { return }
        cells.remove(at: index)
        selectedRow = min(selectedRow, cells.count - 1)
        focusedCell = CellCoord(row: selectedRow, col: selectedCol)
    }

    private func insertColumn(at index: Int) {
        let clamped = max(0, min(index, colCount))
        for r in cells.indices {
            cells[r].insert("", at: clamped)
        }
        selectedCol = clamped
        focusedCell = CellCoord(row: selectedRow, col: clamped)
    }

    private func deleteColumn(at index: Int) {
        guard colCount > 1, index >= 0, index < colCount else { return }
        for r in cells.indices {
            cells[r].remove(at: index)
        }
        selectedCol = min(selectedCol, colCount - 1)
        focusedCell = CellCoord(row: selectedRow, col: selectedCol)
    }

    private func clearAllCells() {
        cells = Array(
            repeating: Array(repeating: "", count: max(colCount, 1)),
            count: max(rowCount, 1)
        )
    }
}
