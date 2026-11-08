# GhostChat v2.0.0

[![Version](https://img.shields.io/badge/version-2.0.0-brightgreen.svg)](#) [![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.7-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://www.android.com)
[![Android](https://img.shields.io/badge/Android-13%20(API%2033)-3DDC84?logo=android)](https://www.android.com)
[![Rust](https://img.shields.io/badge/Rust-1.86-000000?logo=rust)](https://www.rust-lang.org)
[![Sponsor](https://img.shields.io/badge/Sponsor-ai--tech--db-pink?logo=github-sponsors)](https://github.com/sponsors/ai-tech-db)

**Anonymous, end-to-end encrypted, ephemeral chat** — built entirely on an Android phone. No accounts, no servers, no logs.

GhostChat turns an Android device into a self-contained chat server:
- Runs an HTTP/WebSocket server on 127.0.0.1
- Exposes it to the internet via Cloudflare Quick Tunnel
- Generates a passphrase (E2EE) and 3 invite codes
- Participants open a link in any browser, enter the passphrase, and chat

The session is ephemeral: it lives as long as the app is running. No messages are stored anywhere. No metadata survives the session.


## What's new in v2.0.0

- **New Rust crate (v0.4.0)**: Replaced `webpki-roots` with `rustls-platform-verifier`. TLS certificate validation now follows the Android OS, eliminating the need to manually update bundled Mozilla CA certificates.
- **Image Privacy**: Photos taken from the camera or selected from the gallery are resized (max 1280px, JPEG 0.82) and **all EXIF metadata (GPS, device, date) are stripped** via an in-browser canvas before sending.
- **Camera Fix**: Fixed an issue on Samsung devices where the camera intent returned a deleted temporary file. The app now correctly resizes and sends camera photos.

---

## Features

- **End-to-end encryption** (AES-GCM 256, PBKDF2 250k, ECDSA P-256)
- **Forward secrecy per message** (HKDF-derived key per message)
- **No sniffing / No server-side decryption** — messages are encrypted with AES-GCM 256 client-side; the server (and any network eavesdropper) sees only ciphertext.
- **Zero persistence** — server is a blind relay, no logs, no database
- **Zero accounts** — no email, no phone number, no registration
- **Privacy-first images** — resized to max 1280px and stripped of all EXIF data (GPS, device) before being encoded in Base64 and end-to-end encrypted for transport.
- **Anonymous nicknames** — generated client-side
- **Multi-language UI** — Italiano, English, Español
- **Embedded Cloudflare Tunnel** — no port forwarding, no public IP
- **Foreground Service** — resists aggressive Android ROMs (EMUI, MIUI)
- **Reconnect** — automatic reconnect with grace period after network drops
- **Ghost emoji reactions** — 👻❤️ 👻🔥 👻💀 and more
- **FLAG_SECURE** — blocks screenshots of the app

## Why GhostChat?

Running Cloudflare Tunnel on Android without root has been **broken for years**. The official `cloudflared` (Go) fails because its DNS resolver tries `[::1]:53`, which doesn't exist on non-rooted Android.

GhostChat solves this by using a **pure-Rust QUIC client** ([`cloudflare-quick-tunnel-rs`](https://github.com/shadow3aaa/cloudflare-quick-tunnel-rs)) forked with:

- **JNI bindings** to call it from Flutter
- **Custom DoH resolver** (hickory) to bypass OEM DNS filtering
- **`rustls-platform-verifier`** for native OS certificate validation (no manual CA updates)

Result: a **native Android app** that runs Cloudflare Quick Tunnel with **no root, no Termux, no VPS, no `cloudflared` subprocess**.

---

## Demo

<img src="assets/branding/APP-trimmed.png" alt="GhostChat demo" width="600">

🎬 [Watch the demo video](assets/branding/GhostChat-compressed.mp4)

---

## Architecture
ANDROID HOST
Flutter App (Dart)

SessionServer (HTTP + WS on 127.0.0.1:8080)

MethodChannel -> Kotlin

UI (IT/EN/ES)
|
v JNI
libqttunnel_jni.so (C wrapper, ~6 KB)
|
v FFI
libqttunnel.so (Rust, ~14 MB)

cloudflare-quick-tunnel-rs (fork)

QUIC + capnp-RPC to CF edge

DoH resolver (hickory) for filtered DNS
|
v QUIC
Cloudflare Edge
|
v HTTPS/WSS
Browser A, Browser B, Browser C                                                                                                                                                                                                                                                                   
---

## Tech stack

| Layer | Technology |
|---|---|
| UI (host) | Flutter 3.35.7 (Dart) |
| Bridge | Kotlin + JNI |
| Tunnel | Rust (forked cloudflare-quick-tunnel-rs) |
| DNS | hickory-resolver (DoH) |
| Server | Dart (shelf + shelf_web_socket) |
| Client | Vanilla JS + WebCrypto |
| Crypto | AES-GCM 256, PBKDF2-SHA256, HKDF-SHA256, ECDSA P-256 |

---

## Build

### Prerequisites

| Component | Version |
|---|---|
| Flutter | 3.27+ |
| Rust | 1.86+ |
| NDK Android | 27.0.12077973 |
| patchelf | 0.18+ |
| gcc | 12+ |
| JDK | 17+ |

### 1. Clone the repository

```bash
git clone https://github.com/ai-tech-db/GhostChat-v2.0.0.git
cd GhostChat-v2.0.0
```

### 2. Build the Rust tunnel

The `v2.0.0` crate uses `rustls-platform-verifier`, which requires a specific Android AAR dependency.

```bash
cd rust/cloudflare-quick-tunnel-rs

export NDK=$HOME/android-sdk/ndk/27.0.12077973
export NDK_BIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
export CC_aarch64_linux_android=$NDK_BIN/aarch64-linux-android26-clang
export CXX_aarch64_linux_android=$NDK_BIN/aarch64-linux-android26-clang++
export AR_aarch64_linux_android=$NDK_BIN/llvm-ar
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$CC_aarch64_linux_android

# Build the Rust library (this generates libdl_cloudflare_quick_tunnel_v2.so)
cargo build --release --target aarch64-linux-android

# Copy and rename it to the name expected by Android
cp target/aarch64-linux-android/release/libdl_cloudflare_quick_tunnel_v2.so \
   ../../android/app/src/main/jniLibs/arm64-v8a/libqttunnel.so

# Set the correct soname
patchelf --set-soname libqttunnel.so \
   ../../android/app/src/main/jniLibs/arm64-v8a/libqttunnel.so
```

### 3. Build the JNI wrapper

```bash
cd ../..

NDK=$HOME/android-sdk/ndk/27.0.12077973
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CC=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android26-clang

$CC -shared -fPIC \
  -Wl,-soname,libqttunnel_jni.so \
  -I$SYSROOT/usr/include \
  -o android/app/src/main/jniLibs/arm64-v8a/libqttunnel_jni.so \
  android/app/src/main/cpp/qttunnel_jni.c \
  android/app/src/main/jniLibs/arm64-v8a/libqttunnel.so \
  -llog
```

### 4. Build the APK

**Important:** Gradle needs to find the `rustls-platform-verifier-android` AAR. Our `android/settings.gradle.kts` runs `cargo metadata` to locate it. Ensure `cargo` is in your `PATH`.

Debug build:

```bash
flutter pub get
flutter build apk --debug
```

Release build (requires a keystore):

1. Generate a keystore:

```bash
keytool -genkey -v \
  -keystore android/app/ghostchat-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ghostchat
```

2. Create `android/key.properties`:

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=ghostchat
storeFile=ghostchat-release.jks
```

3. Build:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Docker alternative

A `Dockerfile` is provided to reproduce the environment. It pre-installs Rust, `cargo-ndk`, and the Android NDK.

```bash
docker build -t ghostchat-v2-builder .
docker run --rm -v "$PWD":/workspace -w /workspace ghostchat-v2-builder \
  bash -c "flutter pub get && flutter build apk --debug"
```

## Security

GhostChat uses a defense-in-depth approach:

- **E2EE** (AES-GCM 256) — server never sees plaintext
- **PBKDF2** (250k iterations) — resists offline brute force
- **Forward secrecy per message** (HKDF) — each message uses a unique key
- **ECDSA P-256 signatures** — prevents spoofing
- **Padding** (256-byte blocks) — hides message length
- **Replay protection** — monotonic per-sender counter
- **Blind relay** — server doesn't decrypt, doesn't persist
- **HTTP security headers** — CSP, X-Frame-Options, Referrer-Policy

**What it does NOT protect against**:
- Metadata visible to Cloudflare (IP, timestamp)
- Compromised client browser (extensions, malware)
- Anyone who knows the passphrase (group chat)
- Full forward secrecy (no DH ratchet, not Signal protocol)

See SECURITY.md for the full threat model.

---

## Project structure

```
ghostchat/
  android/                       # Android app (Kotlin + C)
    app/src/main/
      cpp/qttunnel_jni.c         # JNI wrapper
      jniLibs/arm64-v8a/         # Native libraries
      kotlin/com/aitechdb/ghostchat/
        MainActivity.kt
        GhostChatService.kt
      res/                       # Icons, styles
  assets/
    icons/                       # App icon (SVG + PNG)
    web_client/                  # Web client (HTML/CSS/JS)
      index.html
      style.css
      app.js                     # E2EE + WebSocket
      strings_web.js             # IT/EN/ES translations
  lib/                           # Flutter app (Dart)
    main.dart                    # UI
    l10n/strings.dart            # IT/EN/ES translations
    server/                      # Embedded HTTP/WS server
      session_server.dart
      token.dart
      models/session.dart
  rust/
    cloudflare-quick-tunnel-rs/  # Fork of the Rust tunnel
  LICENSE                        # Apache 2.0
  NOTICE                         # Third-party attributions
  SECURITY.md                    # Threat model
  README.md                      # This file
```

---

## Credits

- **Fork base**: shadow3aaa/cloudflare-quick-tunnel-rs (MIT OR Apache-2.0)
- **Flutter SDK**: The Flutter Authors (BSD-3-Clause)
- **Dart packages**: see pubspec.yaml (MIT/BSD)
- **Rust crates**: see Cargo.lock (MIT/Apache-2.0/BSD)

See NOTICE for full attributions.

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0-or-later)**.
See LICENSE for the full text.

**What this means in practice:**
- You can use, modify, and distribute GhostChat for any purpose, including commercial use.
- If you distribute a modified version, you must make the source code available under the GPL-3.0.
- You cannot take this code and incorporate it into a proprietary, closed-source product.

---

## Contributing

See CONTRIBUTING.md for guidelines.

---

## Contact

- **Issues**: https://github.com/ai-tech-db/GhostChat-v2.0.0/issues
- **Discussions**: https://github.com/ai-tech-db/GhostChat-v2.0.0/discussions

---

**GhostChat** — You enter. You chat. You disappear.

Made with ❤️ by AI-Tech-DB
