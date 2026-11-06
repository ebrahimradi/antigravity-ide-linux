# Antigravity IDE & 1-Click Updater for Ubuntu / Linux

An open-source installer and automated updater for **Google Antigravity IDE** on Ubuntu and Debian-based Linux systems.

Google currently offers the Antigravity CLI via Snap, but does not provide an official package repository for the **Antigravity IDE** desktop application. This installer automates downloading, desktop environment integration, and updates directly from Google's official release CDN.

---

## ⚡ Quick Install (1-Line Command)

Open your terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ebrahimradi/antigravity-ide-linux/main/install.sh | bash
```

*(You will be prompted for your `sudo` password to install system-wide into `/opt/antigravity-ide` and `/usr/local/bin`)*

---

## ✨ What It Does

1. **Auto-Detects Architecture**:
   - Intel/AMD 64-bit (`x86_64` / `amd64`)
   - ARM 64-bit (`aarch64` / `arm64`)
2. **Zero Maintenance for You**:
   - The script queries Google's official download portal (`https://antigravity.google/download`) in real-time.
   - It always discovers and downloads the latest official Google release dynamically. Whenever Google releases an update, users get it immediately without you ever having to update the code in your GitHub repository!
3. **Desktop Integration**:
   - Adds **Antigravity IDE** to your Ubuntu applications grid with the official high-resolution icon.
   - Registers MIME associations for folders, text files, and workspace files.
4. **1-Click Updater App**:
   - Adds a second launcher: **Update Antigravity IDE** in your app menu.
   - Sets up a passwordless `sudoers` entry for the updater script, so clicking the icon checks and updates your IDE without repeatedly asking for passwords.

---

## 🔄 How to Update

Whenever Google publishes an update, users have two ways to update:

- **From Ubuntu App Menu**: Click the **"Update Antigravity IDE"** application icon.
- **From Terminal**: Run:
  ```bash
  update-antigravity-ide
  ```

---

## 🗑️ Uninstall

To cleanly remove Antigravity IDE, updater scripts, desktop entries, and icons:

```bash
curl -fsSL https://raw.githubusercontent.com/ebrahimradi/antigravity-ide-linux/main/uninstall.sh | bash
```

---

## 📄 License

MIT License. Antigravity IDE is developed by Google. This repository is an open-source community installer and helper.
