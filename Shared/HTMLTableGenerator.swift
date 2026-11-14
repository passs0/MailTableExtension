import AppKit
import Foundation
import SwiftUI

/// Generates email-safe inline-styled HTML tables and copies them to the macOS pasteboard.
enum HTMLTableGenerator {
    enum TableTheme: String, CaseIterable, Identifiable {
        case classic = "Classic"
        case appleBlue = "Apple Blue"
        case minimal = "Minimal"
        case graphite = "Graphite"

        var id: String { rawValue }

        var headerBackgroundHex: String {
            switch self {
            case .classic: return "#F5F5F7"
            case .appleBlue: return "#007AFF"
            case .minimal: return "#FFFFFF"
            case .graphite: return "#2C2C2E"
            }
        }

        var headerTextHex: String {
            switch self {
            case .classic, .minimal: return "#1D1D1F"
            case .appleBlue, .graphite: return "#FFFFFF"
            }
        }

        var zebraBackgroundHex: String {
            switch self {
            case .classic: return "#FAFAFC"
            case .appleBlue: return "#F5F9FF"
            case .minimal: return "#FAFAFA"
            case .graphite: return "#F5F5F7"
            }
        }

        var borderHex: String {
            switch self {
            case .classic, .minimal: return "#D2D2D7"
            case .appleBlue: return "#C7DDFB"
            case .graphite: return "#D1D1D6"
            }
        }

        var previewHeaderBackground: Color {
            switch self {
            case .classic: return Color(nsColor: .controlBackgroundColor)
            case .appleBlue: return Color.accentColor
            case .minimal: return Color.clear
            case .graphite: return Color(nsColor: .darkGray)
            }
        }

        var previewHeaderForeground: Color {
            switch self {
            case .classic, .minimal: return .primary
            case .appleBlue, .graphite: return .white
            }
        }
    }

    enum CellAlignment: String, CaseIterable, Identifiable {
        case leading = "Left"
        case center = "Center"
        case trailing = "Right"

        var id: String { rawValue }

        var cssValue: String {
            switch self {
            case .leading: return "left"
            case .center: return "center"
            case .trailing: return "right"
            }
        }

        var symbolName: String {
            switch self {
            case .leading: return "text.alignleft"
            case .center: return "text.aligncenter"
            case .trailing: return "text.alignright"
            }
        }

        var textAlignment: TextAlignment {
            switch self {
            case .leading: return .leading
            case .center: return .center
            case .trailing: return .trailing
            }
        }
    }

    struct StyleOptions: Equatable {
        var hasHeaderRow: Bool = true
        var showBorders: Bool = true
        var zebraStriping: Bool = false
        var theme: TableTheme = .classic
        var alignment: CellAlignment = .leading
        var cellPadding: Int = 9
    }

    /// Builds an inline-styled HTML `<table>` string safe for Apple Mail, Gmail, and Outlook.
    static func makeHTML(rows: [[String]], options: StyleOptions) -> String {
        guard !rows.isEmpty else { return "" }

        let borderColor = options.theme.borderHex
        let isMinimal = options.theme == .minimal
        let fullBorder = options.showBorders ? "1px solid \(borderColor)" : "none"
        let headerBottomBorder = isMinimal
            ? "2px solid #1D1D1F"
            : fullBorder
        let rowBottomBorder = isMinimal
            ? (options.showBorders ? "1px solid \(borderColor)" : "none")
            : fullBorder

        var html = """
        <table style="border-collapse: collapse; font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Arial, sans-serif; font-size: 13px; line-height: 1.4; color: #1D1D1F;\(isMinimal ? "" : " border: \(fullBorder);")">
        """

        for (rowIndex, row) in rows.enumerated() {
            let isHeader = options.hasHeaderRow && rowIndex == 0
            let background: String = {
                if isHeader { return options.theme.headerBackgroundHex }
                if options.zebraStriping && rowIndex % 2 == 0 {
                    return options.theme.zebraBackgroundHex
                }
                return "#FFFFFF"
            }()

            if isHeader {
                html += "\n  <thead>"
            } else if rowIndex == (options.hasHeaderRow ? 1 : 0) {
                html += "\n  <tbody>"
            }

            html += "\n    <tr style=\"background-color: \(background);\">"
            let tag = isHeader ? "th" : "td"
            let fontWeight = isHeader ? "600" : "400"
            let textColor = isHeader ? options.theme.headerTextHex : "#1D1D1F"
            let cellBorderCSS: String = {
                if isMinimal {
                    return "border-bottom: \(isHeader ? headerBottomBorder : rowBottomBorder);"
                }
                return "border: \(fullBorder);"
            }()

            for cell in row {
                let escaped = escapeHTML(cell)
                let content = escaped.isEmpty ? "&nbsp;" : escaped
                html += "\n      <\(tag) style=\"\(cellBorderCSS) padding: \(options.cellPadding)px 14px; text-align: \(options.alignment.cssValue); font-weight: \(fontWeight); color: \(textColor); vertical-align: top;\">\(content)</\(tag)>"
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

    /// Parses CSV (including quoted fields), TSV, or Markdown pipe-table text into a 2D array of cells.
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
                let isSeparator = cells.allSatisfy { cell in
                    !cell.isEmpty && cell.allSatisfy { $0 == "-" || $0 == ":" }
                }
                return isSeparator ? nil : cells
            }
            return normalizeColumnCount(parsed)
        }

        // Tab-separated
        if lines.first?.contains("\t") == true {
            let parsed = lines.map { line in
                line.split(separator: "\t", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
            }
            return normalizeColumnCount(parsed)
        }

        // Comma-separated with RFC-4180 quote awareness
        let parsed = lines.map(parseCSVLine)
        return normalizeColumnCount(parsed)
    }

    /// Writes HTML, RTF, and Markdown plain-text representations to `NSPasteboard.general`
    /// so Mail.app pastes a clean native rich table when the user hits Cmd+V.
    @discardableResult
    static func copyToPasteboard(rows: [[String]], options: StyleOptions) -> Bool {
        let html = makeHTML(rows: rows, options: options)
        guard let htmlData = html.data(using: .utf8) else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        item.setData(htmlData, forType: .html)

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

        item.setString(makeMarkdown(rows: rows), forType: .string)
        return pasteboard.writeObjects([item])
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0

        while i < chars.count {
            let ch = chars[i]
            if ch == "\"" {
                if inQuotes, i + 1 < chars.count, chars[i + 1] == "\"" {
                    current.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if ch == ",", !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(ch)
            }
            i += 1
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
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
