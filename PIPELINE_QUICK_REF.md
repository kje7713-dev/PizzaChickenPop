# Pipeline Quick Reference

Quick commands and references for the XcodeGen + Fastlane Match pipeline.

## Daily Commands

```bash
# Generate Xcode project
xcodegen generate

# Open project
open PizzaChicken.xcodeproj

# Install/update dependencies
bundle install

# Fetch certificates from Match
bundle exec fastlane match appstore --readonly
```

## CI/CD

### Trigger Build
1. Go to GitHub → Actions
2. Select "iOS TestFlight Deployment"
3. Click "Run workflow"

### Check Status
- View logs in GitHub Actions
- Download artifacts after build
- Check TestFlight in 5-10 minutes

## Required Secrets

| Secret | Example | Where to Get |
|--------|---------|--------------|
| `APPLE_ID` | `dev@example.com` | Your Apple ID |
| `APPLE_TEAM_ID` | `ABC123XYZ` | developer.apple.com → Membership |
| `APP_IDENTIFIER` | `com.kje7713.PizzaChicken` | Bundle ID |
| `ASC_KEY_ID` | `ABCD123456` | App Store Connect → Keys |
| `ASC_ISSUER_ID` | `12345678-1234-...` | App Store Connect → Keys |
| `ASC_KEY` | `-----BEGIN...` | Download .p8 file |
| `MATCH_GIT_URL` | `https://github.com/...` | Your certs repo |
| `MATCH_GIT_TOKEN` | `ghp_xxxxx` | GitHub → Settings → Tokens |
| `MATCH_PASSWORD` | `SecurePass123!` | You create this |
| `IOS_SCHEME` | `PizzaChicken` | From project.yml |

## File Structure

```
PizzaChickenPop/
├── project.yml          # XcodeGen config (edit this)
├── Sources/             # Swift code
├── Resources/           # Assets, Info.plist
├── fastlane/
│   ├── Fastfile        # Build automation
│   └── Matchfile       # Signing config
├── .github/workflows/
│   └── ios-testflight.yml  # CI/CD pipeline
└── Transfers/          # Complete documentation
```

## Workflows

**New (Match-based):** `.github/workflows/ios-testflight.yml`
- Uses XcodeGen + Fastlane Match
- Automated code signing
- **Use this for all new builds**

**Old (Deprecated):** `.github/workflows/ios-build.yml`
- Manual signing approach
- Kept for reference only

## Pipeline Flow

```
1. Checkout code
2. Install XcodeGen + dependencies
3. Generate project (xcodegen generate)
4. Fetch certificates (Match)
5. Build IPA
6. Upload to TestFlight
7. Upload artifacts
```

## Common Tasks

### Add New File
1. Add file to `Sources/`
2. Run `xcodegen generate`
3. File automatically included

### Update Build Settings
1. Edit `project.yml`
2. Run `xcodegen generate`
3. Settings applied

### Renew Certificates
```bash
bundle exec fastlane match appstore --force
```

### Test Build Locally
```bash
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="ABC123XYZ"
export APP_IDENTIFIER="com.kje7713.PizzaChicken"
export ASC_KEY_ID="ABCD123456"
export ASC_ISSUER_ID="12345678-..."
export MATCH_GIT_URL="https://github.com/user/certs"
export MATCH_GIT_TOKEN="ghp_xxxxx"
export MATCH_PASSWORD="password"
export IOS_SCHEME="PizzaChicken"

# Copy API key
cp ~/Downloads/AuthKey_KEYID.p8 fastlane/AuthKey.p8

# Run build
bundle exec fastlane beta
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| "XcodeGen not found" | `brew install xcodegen` |
| "No project found" | `xcodegen generate` |
| "Match auth failed" | Check `MATCH_GIT_TOKEN` |
| "No signing identity" | Run `fastlane match appstore` |
| "Build failed" | Check Actions logs, download artifacts |

## Documentation

- **[README.md](README.md)** - Main documentation
- **[GITHUB_SECRETS_LIST.md](GITHUB_SECRETS_LIST.md)** - All required secrets
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Migration from manual signing
- **[Transfers/](Transfers/)** - Complete pipeline documentation

## Help

Full documentation in [Transfers/](Transfers/) folder:
- QUICK_START_PIPELINE.md
- PIPELINE_SETUP_GUIDE.md
- PIPELINE_ARCHITECTURE.md
- SECRETS_REFERENCE.md
