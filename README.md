<p align="center">
  <img src="assets/icon.png" width="128" alt="Cellmate Icon" />
</p>

<h1 align="center">Cellmate</h1>

<p align="center">
  <strong>Tables for Apple Mail, the Apple way.</strong><br/>
  A native macOS <strong>MailKit</strong> compose extension (<code>CellmateExtension.appex</code>) embedded in a lightweight host app (<code>Cellmate.app</code>) with an Apple Numbers–inspired grid editor right in <strong>Apple Mail's compose toolbar</strong>.
</p>

<p align="center">
  <a href="https://github.com/passs0/Cellmate/releases/latest"><img src="https://img.shields.io/github/v/release/passs0/Cellmate?label=Latest%20Release&color=007AFF" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B%20%7C%20Apple%20Silicon%20%26%20Intel-black?logo=apple" alt="macOS 13.0+" />
  <img src="https://img.shields.io/badge/framework-MailKit%20%7C%20SwiftUI%20%7C%20AppKit-blue" alt="Frameworks" />
</p>

---

> [!NOTE]
> **AI-Generated Tool Disclosure**
> **Cellmate** (reprised from *Tabulate* — including its MailKit compose extension architecture, SwiftUI interactive grid editor, and HTML/RTF/Markdown pasteboard export) is an **AI-generated tool** created with **Antigravity** (Google DeepMind).

---

## Features
- **Apple-Native Design:** Built with SwiftUI, AppKit materials, SF Symbols, and a layered Apple Icon Composer (`Cellmate.icon`) app icon.
- **Seamless Grid Editor:** Click or `Tab` between cells with live WYSIWYG preview of header styling, zebra striping, borders, and text alignment.
- **Curated Apple Themes:** Switch between **Classic**, **Apple Blue**, **Minimal**, and **Graphite** inline-styled HTML palettes.
- **Row & Column Controls:** Native macOS `ControlGroup` actions to insert/delete rows and columns around the focused cell, plus Left / Center / Right alignment.
- **CSV / TSV / Markdown Importer:** Paste Markdown pipe tables (`| A | B |`), tab-separated spreadsheet rows, or quoted CSV directly into the editor.
- **Embedded Playground:** Test the table editor directly inside `Cellmate.app` before opening Mail.
- **Copy into Mail (`⌘↩` → `⌘V`):** Copies inline-styled HTML `<table>` (plus RTF and Markdown fallbacks) to `NSPasteboard` so `⌘V` pastes a clean native table into Mail's compose body.

---

## Why can't MailKit insert directly without copy/paste?
Apple's **MailKit** (`MEComposeSessionHandler`) is intentionally sandboxed:
- Extensions **cannot** read or mutate the HTML/DOM of the email body being composed. There is no `insertHTML` or `insertTable` API in MailKit.
- Inside the `.appex` sandbox, the extension also cannot send keyboard/AppleEvents to `Mail.app` (and out-of-process drag-and-drop into Mail is treated as a file attachment rather than inline rich text).

---

## Install Without Xcode (Self-Signed Local Build)

You don't need to download Xcode (10+ GB) to run this on your own Mac. You can download the prebuilt unsigned `.app` from **Releases** (or **Actions** artifacts, built on GitHub Actions) and sign it locally with a persistent self-signed certificate.

### 1. Create & Trust a Local Code-Signing Certificate
```bash
TMPDIR=$(mktemp -d)
openssl req -x509 -newkey rsa:2048 -days 3650 \
  -keyout "$TMPDIR/dev.key" -out "$TMPDIR/dev.crt" -nodes \
  -subj "/CN=LocalMailKitDev" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=codeSigning"

openssl pkcs12 -export \
  -in "$TMPDIR/dev.crt" -inkey "$TMPDIR/dev.key" \
  -out "$TMPDIR/dev.p12" -password pass:dev

security import "$TMPDIR/dev.p12" -k ~/Library/Keychains/login.keychain-db -P dev -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k ~/Library/Keychains/login.keychain-db "$TMPDIR/dev.crt"
rm -rf "$TMPDIR"
```

### 2. Download, Sign & Register
Download `Cellmate.zip` from the [latest GitHub Release](https://github.com/passs0/Cellmate/releases/latest) (or Actions artifact), unzip it, and run:
```bash
xattr -cr Cellmate.app
codesign --force --sign "LocalMailKitDev" --entitlements CellmateExtension/CellmateExtension.entitlements --options runtime Cellmate.app/Contents/PlugIns/CellmateExtension.appex
codesign --force --sign "LocalMailKitDev" --entitlements CellmateHost/CellmateHost.entitlements --options runtime Cellmate.app
codesign --verify --deep --strict Cellmate.app

cp -R Cellmate.app /Applications/Cellmate.app
pluginkit -a /Applications/Cellmate.app/Contents/PlugIns/CellmateExtension.appex
pluginkit -e use -i com.passs0.Cellmate.CellmateExtension
```
Restart **Apple Mail**, verify **Cellmate** is enabled in **Mail → Settings → Extensions**, open a new compose window, and click the table icon (`tablecells`) in the toolbar.

---

## Building from Source (GitHub Actions or Xcode)
- **GitHub Actions:** Pushing to `main` runs [.github/workflows/build.yml](.github/workflows/build.yml) on `macos-latest`, generates the Xcode project via XcodeGen, builds `Cellmate.app` (with `CellmateExtension.appex` and `Cellmate.icon`), and uploads `Cellmate-macOS`.
- **Local Xcode:**
  ```bash
  brew install xcodegen
  xcodegen generate
  open Cellmate.xcodeproj
  ```
