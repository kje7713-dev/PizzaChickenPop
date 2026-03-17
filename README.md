# Pizza Chicken (SpriteKit) – XcodeGen + Fastlane Match Pipeline

This repo uses a **modern CI/CD pipeline** with XcodeGen and Fastlane Match for automated builds and TestFlight distribution on **GitHub Actions**.

Tech Stack:
- Swift + SpriteKit
- **XcodeGen** - Generates Xcode project from YAML configuration
- **Fastlane Match** - Manages code signing via Git repository
- **GitHub Actions** - Automated CI/CD on macOS runners
- **TestFlight** - Beta distribution via App Store Connect

> 📖 **Complete pipeline documentation available in [Transfers/](Transfers/) folder**

---

## Game Concept

- Tap/double-tap pizza → chicken "eats" → score increments
- At threshold → chicken explodes (cartoony particles) → run ends
- Submit score to Game Center leaderboard
- Reset and replay

> **Game Center Leaderboard ID:** `pizza_chicken_highscore`
> This identifier must match exactly in App Store Connect under your app's leaderboard configuration.

---

## Pipeline Overview

The build pipeline follows this flow:

```
XcodeGen → Xcode Project → Fastlane Match → Code Signing → Build → TestFlight
```

**GitHub Actions workflow:**
1. Generate Xcode project from `project.yml` (XcodeGen)
2. Install certificates from Match repository
3. Build and archive the app
4. Export signed IPA
5. Upload to TestFlight

**Key benefits:**
- ✅ No `.xcodeproj` files in Git (generated from YAML)
- ✅ Automated code signing with Match
- ✅ Team-wide certificate sharing via encrypted Git repo
- ✅ Reproducible builds on any machine

---

## Quick Start

### Prerequisites
- Apple Developer Program membership
- App registered in App Store Connect
- Private GitHub repository for certificates (Match)

### Setup

1. **Configure GitHub Secrets** - See [GITHUB_SECRETS_LIST.md](GITHUB_SECRETS_LIST.md)
   
   Required secrets:
   - `APPLE_ID`, `APPLE_TEAM_ID`, `APP_IDENTIFIER`
   - `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY`
   - `MATCH_GIT_URL`, `MATCH_GIT_TOKEN`, `MATCH_PASSWORD`
   - `IOS_SCHEME`

2. **Initialize Match** (first time only):
   ```bash
   bundle install
   bundle exec fastlane match appstore
   ```
   
   **Or** run the GitHub Actions workflow with `MATCH_READONLY=false` to bootstrap:
   - Manually trigger the workflow
   - Set environment variable: `MATCH_READONLY: "false"` in the workflow
   - After successful run, remove or set back to `"true"`
   - See [SECRETS_REFERENCE.md](Transfers/SECRETS_REFERENCE.md) for details

3. **Generate Xcode Project**:
   ```bash
   brew install xcodegen
   xcodegen generate
   ```

4. **Deploy to TestFlight**:
   - Go to GitHub → Actions → "iOS TestFlight Deployment"
   - Click "Run workflow"

---

## Documentation

### Complete Pipeline Documentation (Transfers Folder)

The [Transfers/](Transfers/) folder contains comprehensive, transferable documentation:

- **[QUICK_START_PIPELINE.md](Transfers/QUICK_START_PIPELINE.md)** - ⚡ Fast setup checklist
- **[PIPELINE_SETUP_GUIDE.md](Transfers/PIPELINE_SETUP_GUIDE.md)** - 🚀 Complete setup guide
- **[PIPELINE_ARCHITECTURE.md](Transfers/PIPELINE_ARCHITECTURE.md)** - 📊 Architecture diagrams
- **[SECRETS_REFERENCE.md](Transfers/SECRETS_REFERENCE.md)** - 🔐 All secrets explained

These documents are designed to be reusable for any iOS project.

### Repository Documentation

- **[GITHUB_SECRETS_LIST.md](GITHUB_SECRETS_LIST.md)** - Required GitHub secrets
- **[SECRETS_SETUP.md](SECRETS_SETUP.md)** - Legacy manual setup guide (for reference)

---

## Local Development

### First Time Setup

```bash
# Install dependencies
brew install xcodegen
bundle install

# Initialize Match
bundle exec fastlane match appstore

# Generate Xcode project
xcodegen generate

# Open project
open PizzaChicken.xcodeproj
```

### Regenerate Project

If you modify `project.yml`:

```bash
xcodegen generate
```

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ios-testflight.yml`) runs on:
- Manual trigger (workflow_dispatch)
- Push to `main` branch

### Build Process

1. **Checkout & Setup** - Clones repo, installs tools
2. **Project Generation** - Runs XcodeGen
3. **Code Signing** - Fetches certificates via Match
4. **Build** - Creates signed IPA
5. **Upload** - Sends to TestFlight
6. **Artifacts** - Uploads IPA and logs

---

## Troubleshooting

**"Code signing failed"**
- Verify all GitHub secrets are set
- Check Match repository has certificates
- See [Transfers/SECRETS_REFERENCE.md](Transfers/SECRETS_REFERENCE.md)

**"Build failed in CI"**
- Download `ios-build-logs` artifact
- See [Transfers/PIPELINE_SETUP_GUIDE.md#troubleshooting](Transfers/PIPELINE_SETUP_GUIDE.md#troubleshooting)

---

## Migration from Manual Signing

If using the old `ios-build.yml` workflow:

1. Use the new `ios-testflight.yml` workflow instead
2. Update GitHub secrets - see [GITHUB_SECRETS_LIST.md](GITHUB_SECRETS_LIST.md)
3. Initialize Match: `bundle exec fastlane match appstore`

**Old secrets no longer needed:**
- `IOS_P12_BASE64`, `IOS_P12_PASSWORD`, `IOS_MOBILEPROVISION_BASE64` → Replaced by Match
- `IOS_KEYCHAIN_PASSWORD` → Now `MATCH_PASSWORD`
- `IOS_EXPORT_OPTIONS_PLIST_BASE64` → Generated automatically

---

**Pipeline Architecture:** See [Transfers/PIPELINE_ARCHITECTURE.md](Transfers/PIPELINE_ARCHITECTURE.md) for visual diagrams

**Need Help?** Check the comprehensive documentation in the [Transfers/](Transfers/) folder.
