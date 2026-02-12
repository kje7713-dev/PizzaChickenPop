# Pizza Chicken (SpriteKit) – GitHub Actions Pipeline Build + Game Center Leaderboard

This repo is designed to **build from a GitHub pipeline** (not “open Xcode on a Mac and press Run”).
It builds, signs, and exports an `.ipa` on **GitHub Actions** and can optionally upload to **TestFlight** via **fastlane**.

Tech:
- Swift + SpriteKit
- GitHub Actions (macOS runner)
- Codesigning via **certificate + provisioning profile** (manual signing) OR **fastlane match**
- Optional: fastlane `upload_to_testflight` (pilot)

---

## Game Concept (short)

- Tap/double-tap pizza → chicken “eats” → score increments
- At threshold → chicken explodes (cartoony particles) → run ends
- Submit score to Game Center leaderboard (optional)
- Reset and replay

---

## Pipeline Overview

**GitHub Actions does:**
1. Checkout repo
2. Select Xcode
3. Resolve dependencies (SPM)
4. Install signing cert + provisioning profile
5. Build archive (`xcodebuild archive`)
6. Export IPA (`xcodebuild -exportArchive`)
7. (Optional) Upload to TestFlight using fastlane

---

## Required Accounts / Access

- Apple Developer Program membership (for distribution cert/profile)
- App Store Connect access (for TestFlight upload)
- A Mac is **not required** for the build, but you still need Apple dev assets.

---

## Secrets You Must Add (GitHub → Settings → Secrets and variables → Actions)

### Minimal manual signing (recommended to start)

Create these repository secrets:

- `IOS_P12_BASE64`  
  Base64 of your **.p12 distribution certificate** (includes private key)

- `IOS_P12_PASSWORD`  
  Password used when exporting the .p12

- `IOS_MOBILEPROVISION_BASE64`  
  Base64 of your **.mobileprovision** profile (App Store / Ad Hoc, depending on export method)

- `IOS_KEYCHAIN_PASSWORD`  
  Any random string. Used to create a temporary keychain on the runner.

- `IOS_EXPORT_OPTIONS_PLIST_BASE64`  
  Base64 of your `ExportOptions.plist` (controls export: app-store/ad-hoc, etc.)

Optional (for TestFlight upload):
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_KEY_P8_BASE64`  (base64 of the App Store Connect API `.p8` key)

> Apple only lets you download the `.p8` once. Store it like it’s a family heirloom.

---

## How to Generate the Base64 Secrets (local one-time prep)

### 1) Convert files to base64
Run locally on macOS:

```bash
base64 -i path/to/cert.p12 | pbcopy
base64 -i path/to/profile.mobileprovision | pbcopy
base64 -i path/to/ExportOptions.plist | pbcopy
base64 -i path/to/AuthKey_XXXXXXXXXX.p8 | pbcopy
```

Paste each into the matching GitHub Action secret.

### 2) Where ExportOptions.plist comes from
Easiest method:
- Do a successful archive/export once locally in Xcode
- In the export folder, grab `ExportOptions.plist`

---

## GitHub Actions Workflow (build + export IPA)

Create:

`.github/workflows/ios-build.yml`

```yaml
name: iOS Build (IPA)

on:
  workflow_dispatch:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: macos-14

    env:
      SCHEME: PizzaChicken
      CONFIGURATION: Release
      WORKSPACE: PizzaChicken.xcworkspace
      PROJECT: PizzaChicken.xcodeproj
      SDK: iphoneos
      ARCHIVE_PATH: ${{ github.workspace }}/build/PizzaChicken.xcarchive
      EXPORT_PATH: ${{ github.workspace }}/build/export

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # If you use SPM only and no workspace, you can remove WORKSPACE env and use PROJECT.
      - name: Select Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "15.4"

      - name: Create build folders
        run: |
          mkdir -p build
          mkdir -p "${EXPORT_PATH}"

      - name: Install Apple Certificate & Provisioning Profile
        env:
          IOS_P12_BASE64: ${{ secrets.IOS_P12_BASE64 }}
          IOS_P12_PASSWORD: ${{ secrets.IOS_P12_PASSWORD }}
          IOS_MOBILEPROVISION_BASE64: ${{ secrets.IOS_MOBILEPROVISION_BASE64 }}
          IOS_KEYCHAIN_PASSWORD: ${{ secrets.IOS_KEYCHAIN_PASSWORD }}
        run: |
          set -euo pipefail

          CERT_PATH="$RUNNER_TEMP/dist.p12"
          PP_PATH="$RUNNER_TEMP/profile.mobileprovision"
          KEYCHAIN_PATH="$RUNNER_TEMP/build.keychain-db"

          echo "$IOS_P12_BASE64" | base64 --decode > "$CERT_PATH"
          echo "$IOS_MOBILEPROVISION_BASE64" | base64 --decode > "$PP_PATH"

          security create-keychain -p "$IOS_KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$IOS_KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          security import "$CERT_PATH" -P "$IOS_P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
          security list-keychains -d user -s "$KEYCHAIN_PATH"
          security set-key-partition-list -S apple-tool:,apple: -s -k "$IOS_KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
          cp "$PP_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/"

      - name: Resolve Swift Package dependencies (if any)
        run: |
          xcodebuild -resolvePackageDependencies             -project "${PROJECT}"             -scheme "${SCHEME}"

      - name: Archive
        run: |
          set -euo pipefail
          xcodebuild clean archive             -project "${PROJECT}"             -scheme "${SCHEME}"             -configuration "${CONFIGURATION}"             -sdk "${SDK}"             -archivePath "${ARCHIVE_PATH}"             CODE_SIGN_STYLE=Manual

      - name: Export IPA
        env:
          IOS_EXPORT_OPTIONS_PLIST_BASE64: ${{ secrets.IOS_EXPORT_OPTIONS_PLIST_BASE64 }}
        run: |
          set -euo pipefail
          EXPORT_OPTS="$RUNNER_TEMP/ExportOptions.plist"
          echo "$IOS_EXPORT_OPTIONS_PLIST_BASE64" | base64 --decode > "$EXPORT_OPTS"

          xcodebuild -exportArchive             -archivePath "${ARCHIVE_PATH}"             -exportPath "${EXPORT_PATH}"             -exportOptionsPlist "$EXPORT_OPTS"

      - name: Upload IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: PizzaChicken-ipa
          path: build/export/*.ipa
```

### Notes
- Replace `SCHEME` and `PROJECT` with your real scheme/project names.
- If you use a `.xcworkspace`, swap the `xcodebuild` commands to `-workspace`.
- This workflow exports an `.ipa` and stores it as a GitHub Actions artifact.

---

## Optional: Upload to TestFlight (fastlane)

### 1) Add fastlane to repo
From repo root:

```bash
bundle init
bundle add fastlane
bundle exec fastlane init
```

### 2) Create a Fastfile lane
`fastlane/Fastfile` example:

```ruby
default_platform(:ios)

platform :ios do
  desc "Upload IPA to TestFlight"
  lane :testflight do
    api_key = app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_P8"],
      is_key_content_base64: true
    )

    upload_to_testflight(
      api_key: api_key,
      ipa: ENV["IPA_PATH"],
      skip_waiting_for_build_processing: true
    )
  end
end
```

### 3) Add upload steps to the workflow
After export, add:

```yaml
      - name: Install Ruby gems
        run: |
          bundle install

      - name: Upload to TestFlight (fastlane)
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8: ${{ secrets.ASC_KEY_P8_BASE64 }}
          IPA_PATH: ${{ github.workspace }}/build/export/PizzaChicken.ipa
        run: |
          bundle exec fastlane ios testflight
```

> Make sure the exported IPA filename matches what your export produces.

---

## Game Center Leaderboard (App Store Connect)

Create a leaderboard in App Store Connect:
- Game Center → Leaderboards → Add
Recommended leaderboard ID:
- `pizza_chicken_highscore`

In code, authenticate the player, then submit score at run end.

---

## Troubleshooting (the usual nonsense)

- **Codesigning fails:** certificate/profile mismatch, wrong bundle ID, wrong team, expired profile.
- **No IPA exported:** your `ExportOptions.plist` doesn’t match the signing method.
- **TestFlight upload succeeds but build doesn’t appear:** App Store Connect processing delay, build number collision, or wrong app target.
- **Game Center not showing scores:** device not signed into Game Center or wrong leaderboard ID.

---

## References
- GitHub Actions: Installing Apple cert on macOS runners:
  https://docs.github.com/actions/use-cases-and-examples/deploying/installing-an-apple-certificate-on-macos-runners-for-xcode-development
- fastlane App Store Connect API:
  https://docs.fastlane.tools/app-store-connect-api/
- fastlane upload_to_testflight:
  https://docs.fastlane.tools/actions/upload_to_testflight/
- setup-xcode action:
  https://github.com/marketplace/actions/setup-xcode-version
