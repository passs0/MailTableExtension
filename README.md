<h1 align="center">Tabulate</h1>

<p align="center">
  <strong>Interactive Table Builder for Apple Mail</strong><br/>
  A minimal macOS <strong>MailKit</strong> compose extension (<code>TabulateExtension.appex</code>) embedded in a lightweight host container (<code>Tabulate.app</code>) that adds an interactive table builder to <strong>Apple Mail's compose toolbar</strong>.
</p>

<p align="center">
  <a href="https://github.com/passs0/Tabulate/releases/latest"><img src="https://img.shields.io/github/v/release/passs0/Tabulate?label=Latest%20Release&color=007AFF" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B%20%7C%20Apple%20Silicon%20%26%20Intel-black?logo=apple" alt="macOS 13.0+" />
  <img src="https://img.shields.io/badge/framework-MailKit%20%7C%20SwiftUI%20%7C%20AppKit-blue" alt="Frameworks" />
</p>

---

> [!NOTE]
> **AI-Generated Tool Disclosure**
> **Tabulate** (including its MailKit compose extension architecture, SwiftUI interactive grid editor, and HTML/RTF/Markdown pasteboard export) is an **AI-generated tool** created with **Antigravity** (Google DeepMind).

---

## Features
- **Built-in Row & Column Editing:** Insert Row Above/Below, Delete Row, Insert Column Left/Right, Delete Column, and Clear at the selected cell.
- **Formatting Controls:** Toggle header row styling, cell borders, and zebra striping.
- **CSV / TSV / Markdown Importer:** Paste Markdown pipe tables (`| A | B |`), tab-separated spreadsheet rows, or CSV directly into the grid.
- **Copy into Mail (`⌘↩` → `⌘V`):** Copies inline-styled HTML `<table>` (plus RTF and Markdown fallbacks) to `NSPasteboard` so `⌘V` pastes a clean native table directly into Mail's compose body.

---

## Why can't MailKit insert directly without copy/paste?
Apple's **MailKit** (`MEComposeSessionHandler`) is intentionally sandboxed:
- Extensions **cannot** read or mutate the HTML/DOM of the email body being composed. There is no `insertHTML` or `insertTable` API in MailKit.
- Inside the `.appex` sandbox, the extension also cannot send keyboard/AppleEvents to `Mail.app` (and out-of-process drag-and-drop into Mail is treated as a file attachment rather than inline rich text).
- **Accessibility Auto-Paste (not enabled by default):** A non-sandboxed companion helper could listen for a signal from the extension, dismiss the popover, and synthesize `⌘V` via `CGEvent`—but that requires granting **Privacy & Security → Accessibility** permission on top of code-signing.

---

## Install Without Xcode (Self-Signed Local Build)

You don't need to download Xcode (10+ GB) to run this on your own Mac. You can download the prebuilt unsigned `.app` from **Releases** (built on GitHub Actions) and sign it locally with a persistent self-signed certificate.

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
Download `Tabulate.zip` from the [latest GitHub Release](https://github.com/passs0/Tabulate/releases/latest), unzip it, and run:
```bash
xattr -cr Tabulate.app
codesign --force --sign "LocalMailKitDev" --entitlements MailTableExtension/MailTableExtension.entitlements --options runtime Tabulate.app/Contents/PlugIns/TabulateExtension.appex
codesign --force --sign "LocalMailKitDev" --entitlements MailTableHost/MailTableHost.entitlements --options runtime Tabulate.app
codesign --verify --deep --strict Tabulate.app

cp -R Tabulate.app /Applications/Tabulate.app
pluginkit -a /Applications/Tabulate.app/Contents/PlugIns/TabulateExtension.appex
pluginkit -e use -i com.example.Tabulate.TabulateExtension
```
Restart **Apple Mail**, verify **Tabulate** is enabled in **Mail → Settings → Extensions**, open a new compose window, and click the table icon in the toolbar.

---

## Why Multiple Authentication / Trust Prompts Are Needed
macOS treats Mail extensions as high-privilege components because they run inside your email client. You will encounter several security boundaries:

1. **Keychain Import & Trust (`security import` / `add-trusted-cert`):**
   Adding a root/code-signing certificate to your `login` keychain requires your macOS password or Touch ID so malicious scripts cannot silently trust rogue certificates.
2. **Ad-Hoc Signing (`codesign -s -`) Is Rejected by `pluginkit`:**
   macOS's `pluginkit` daemon refuses to register ad-hoc signed `com.apple.email.extension` plugins. A persistent, trusted certificate (`LocalMailKitDev` locally, or an Apple Developer certificate for distribution) with Hardened Runtime (`--options runtime`) and App Sandbox entitlements is required.
3. **Mail Settings Approval:**
   Even after `pluginkit` registers the extension, Apple Mail requires explicit user opt-in under **Mail → Settings → Extensions** (or `pluginkit -e use`) before loading it into compose windows.
4. **Gatekeeper / Quarantine (`xattr -cr`):**
   Files downloaded from GitHub carry `com.apple.quarantine`. Clearing quarantine and signing locally replaces Apple's notarization check for personal use on your own Mac.

---

## Building from Source (GitHub Actions or Xcode)
- **GitHub Actions:** Pushing to `main` runs [.github/workflows/build.yml](.github/workflows/build.yml) on `macos-latest`, generates the Xcode project via XcodeGen, builds `Tabulate.app` (with `TabulateExtension.appex` and `Tabulate.icon`), and uploads `Tabulate-macOS`.
- **Local Xcode:**
  ```bash
  brew install xcodegen
  xcodegen generate
  open Tabulate.xcodeproj
  ```
