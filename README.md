# MailTableExtension

A macOS **MailKit** compose extension (`.appex`) + host app that adds a table builder to Apple Mail's compose toolbar.

Because MailKit's sandbox does not allow extensions to directly mutate the compose body HTML, the extension generates an inline-styled HTML `<table>` (plus RTF and Markdown fallbacks) on `NSPasteboard` so you can paste (`⌘V`) a clean, formatted table directly into your email.

## Features
- Interactive row/column grid editor (`1–20` rows, `1–10` columns)
- Toggleable header row, borders, and zebra striping
- Paste CSV, TSV, or Markdown pipe tables (`| A | B |`) to populate the grid
- Copies HTML + RTF + plain-text Markdown to `NSPasteboard`

## Building with Xcode

> **Prerequisite:** Full **Xcode** (from the Mac App Store or developer.apple.com) is required to build `.appex` MailKit extensions. Command Line Tools alone cannot build macOS app bundles/extensions.

### Option A: Generate `.xcodeproj` with XcodeGen (recommended)
```bash
brew install xcodegen
xcodegen generate
open MailTableExtension.xcodeproj
```

### Option B: Manual Xcode setup
1. Create a new **macOS App** project in Xcode (`MailTableHost`).
2. Add a new target: **Mail Extension** (`MailTableExtension`), choosing **Compose** capability.
3. Replace the generated files with the files in `MailTableHost/`, `MailTableExtension/`, and `Shared/` (adding `Shared/` files to both targets).

### Running & Enabling in Mail
1. Select your **Development Team** under **Signing & Capabilities** for both `MailTableHost` and `MailTableExtension` (macOS requires signed extensions for Mail to load them).
2. Build and run `MailTableHost` (`⌘R`).
3. Open **Mail → Settings → Extensions** and check **MailTableExtension**.
4. Open a new compose window and click the **table** icon in the toolbar.
5. Build your table, click **Copy Table**, and press `⌘V` in the email body.
