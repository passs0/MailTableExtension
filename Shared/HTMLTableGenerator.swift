import AppKit
import Foundation

/// Generates email-safe inline-styled HTML tables and copies them to the macOS pasteboard.
enum HTMLTableGenerator {
    struct StyleOptions: Equatable {
        var hasHeaderRow: Bool = true
        var showBorders: Bool = true
        var zebraStriping: Bool = false
        var cellPadding: Int = 8
    }

    /// Builds an inline-styled HTML `<table>` string safe for Apple Mail, Gmail, and Outlook.
    static func makeHTML(rows: [[String]], options: StyleOptions) -> String {
        guard !rows.isEmpty else { return "" }

        let borderStyle = options.showBorders ? "1px solid #d0d7de" : "none"
        var html = """
        <table style="border-collapse: collapse; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 13px; color: #1f2328; border: \(borderStyle);">
        """

        for (rowIndex, row) in rows.enumerated() {
            let isHeader = options.hasHeaderRow && rowIndex == 0
            let background: String = {
                if isHeader { return "#f6f8fa" }
                if options.zebraStriping && rowIndex % 2 == 0 { return "#f9fafb" }
                return "#ffffff"
            }()

            if isHeader {
                html += "\n  <thead>"
            } else if rowIndex == (options.hasHeaderRow ? 1 : 0) {
                html += "\n  <tbody>"
            }

            html += "\n    <tr style=\"background-color: \(background);\">"
            let tag = isHeader ? "th" : "td"
            let fontWeight = isHeader ? "600" : "400"

            for cell in row {
                let escaped = escapeHTML(cell)
                let content = escaped.isEmpty ? "&nbsp;" : escaped
                html += "\n      <\(tag) style=\"border: \(borderStyle); padding: \(options.cellPadding)px 12px; text-align: left; font-weight: \(fontWeight); vertical-align: top;\">\(content)</\(tag)>"
            }
            html += "\n    </tr>"

            if isHeader {
                html += "\n  </thead>"
            }
        }

        if rows.count > (options.hasHeaderRow ? 1 : 0) {
            html += "\n  </tbody>"
        }
        html += "\n</table>"
        return html
    }

    /// Parses simple CSV or Markdown pipe-table text into a 2D array of cells.
    static func parseText(_ input: String) -> [[String]] {
        let lines = input
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return [] }

        // Detect Markdown pipe table (e.g. | Col A | Col B |)
        if lines.first?.contains("|") == true {
            let parsed = lines.compactMap { line -> [String]? in
                let trimmed = line.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                let cells = trimmed.components(separatedBy: "|").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                // Skip Markdown separator rows like | --- | --- |
                let isSeparator = cells.allSatisfy { cell in
                    !cell.isEmpty && cell.allSatisfy { $0 == "-" || $0 == ":" }
                }
                return isSeparator ? nil : cells
            }
            return normalizeColumnCount(parsed)
        }

        // Fallback: tab-separated or comma-separated
        let delimiter: Character = lines.first?.contains("\t") == true ? "\t" : ","
        let parsed = lines.map { line in
            line.split(separator: delimiter, omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        return normalizeColumnCount(parsed)
    }

    /// Writes both HTML and RTF representations to `NSPasteboard.general` so Mail.app
    /// pastes a native-looking rich table when the user hits Cmd+V.
    @discardableResult
    static func copyToPasteboard(rows: [[String]], options: StyleOptions) -> Bool {
        let html = makeHTML(rows: rows, options: options)
        guard let htmlData = html.data(using: .utf8) else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        item.setData(htmlData, forType: .html)

        // Provide an RTF fallback for apps that prefer RTF over raw HTML
        if let attributed = try? NSAttributedString(
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
            item.setData(rtfData, forType: .rtf)
        }

        // Also provide a Markdown plain-text fallback
        item.setString(makeMarkdown(rows: rows), forType: .string)

        return pasteboard.writeObjects([item])
    }

    private static func makeMarkdown(rows: [[String]]) -> String {
        guard let first = rows.first else { return "" }
        var lines: [String] = []
        lines.append("| " + first.joined(separator: " | ") + " |")
        lines.append("| " + first.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in rows.dropFirst() {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }

    private static func normalizeColumnCount(_ rows: [[String]]) -> [[String]] {
        let maxCols = rows.map(\.count).max() ?? 0
        guard maxCols > 0 else { return [] }
        return rows.map { row in
            row + Array(repeating: "", count: max(0, maxCols - row.count))
        }
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}
