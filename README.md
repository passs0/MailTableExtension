# MailTableExtension

A macOS **MailKit** compose extension (`MailTableExtension.appex`) embedded in a lightweight host container (`MailTableHost.app`) that adds an interactive table builder to **Apple Mail's compose toolbar**.

## Features
- **Built-in Row & Column Editing:** Insert Row Above/Below, Delete Row, Insert Column Left/Right, Delete Column, and Clear at the selected cell.
- **Formatting Controls:** Toggle header row styling, cell borders, and zebra striping.
- **CSV / TSV / Markdown Importer:** Paste Markdown pipe tables (`| A | B |`), tab-separated spreadsheet rows, or CSV directly into the grid.
- **Copy or Drag into Mail:** Copies inline-styled HTML `<table>` (plus RTF and Markdown fallbacks) to `NSPasteboard` for `⌘V`, or drag the **Drag Table** badge directly into the Mail compose body.

---

## Why can't MailKit insert directly without copy/paste (or drag)?
Apple's **MailKit** (`MEComposeSessionHandler`) is intentionally sandboxed:
- Extensions **cannot** read or mutate the HTML/DOM of the email body being composed. There is no `insertHTML` or `insertTable` API in MailKit.
- Inside the `.appex` sandbox, the extension also cannot send keyboard/AppleEvents to `Mail.app`.
- **Two ways around copy/paste:**
  1. **Drag-and-Drop (included):** Drag the **Drag Table** badge from the popover into Mail's compose area (`NSItemProvider` with `public.html`).
  2. **Accessibility Auto-Paste (not enabled by default):** A non-sandboxed companion helper could listen for a signal from the extension, dismiss the popover, and synthesize `⌘V` via `CGEvent`—but that requires granting **Privacy & Security → Accessibility** permission on top of code-signing.

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
Download `MailTableHost.zip` from the latest GitHub Release, unzip it, and run:
```bash
xattr -cr MailTableHost.app
codesign --force --sign "LocalMailKitDev" --entitlements MailTableExtension/MailTableExtension.entitlements --options runtime MailTableHost.app/Contents/PlugIns/MailTableExtension.appex
codesign --force --sign "LocalMailKitDev" --entitlements MailTableHost/MailTableHost.entitlements --options runtime MailTableHost.app
codesign --verify --deep --strict MailTableHost.app

cp -R MailTableHost.app /Applications/MailTableHost.app
pluginkit -a /Applications/MailTableHost.app/Contents/PlugIns/MailTableExtension.appex
pluginkit -e use -i com.example.MailTableHost.MailTableExtension
```
Restart **Apple Mail**, verify **MailTableExtension** is enabled in **Mail → Settings → Extensions**, open a new compose window, and click the table icon in the toolbar.

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
- **GitHub Actions:** Pushing to `main` runs [.github/workflows/build.yml](.github/workflows/build.yml) on `macos-latest`, generates the Xcode project via XcodeGen, builds `MailTableHost.app`, and uploads `MailTableHost-macOS`.
- **Local Xcode:**
  ```bash
  brew install xcodegen
  xcodegen generate
  open MailTableExtension.xcodeproj
  ```
