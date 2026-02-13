# Pipeline Setup Guide

This guide documents the complete CI/CD pipeline setup for WorkoutTrackerApp, including all secrets, configurations, and steps required to port this setup to a new iOS app.

## Table of Contents

1. [Overview](#overview)
2. [CI/CD Platforms](#cicd-platforms)
3. [Required Secrets & Environment Variables](#required-secrets--environment-variables)
4. [GitHub Actions Setup](#github-actions-setup)
5. [Fastlane Configuration](#fastlane-configuration)
6. [Code Signing with Match](#code-signing-with-match)
7. [Project Generation with XcodeGen](#project-generation-with-xcodegen)
8. [Porting to a New App](#porting-to-a-new-app)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The WorkoutTrackerApp uses a multi-layered build and deployment system:

- **XcodeGen**: Generates Xcode project from YAML configuration
- **Fastlane**: Automates build, code signing, and TestFlight upload
- **Fastlane Match**: Manages iOS certificates and provisioning profiles via Git
- **GitHub Actions**: CI/CD pipeline (manual trigger)
- **TestFlight**: Beta distribution via App Store Connect

### Build Flow

```
XcodeGen → Xcode Project → Fastlane Match → Code Signing → Build → Upload to TestFlight
```

---

## CI/CD Platforms

### GitHub Actions
- **File**: `.github/workflows/ios-testflight.yml`
- **Trigger**: Manual (`workflow_dispatch`)
- **Runner**: `macos-26` (latest macOS with Xcode)
- **Purpose**: Automated TestFlight deployment

---

## Required Secrets & Environment Variables

### GitHub Secrets

Configure these in: **GitHub Repo → Settings → Secrets and variables → Actions**

| Secret Name | Description | Where to Get It | Example Format |
|-------------|-------------|-----------------|----------------|
| `APPLE_ID` | Apple ID email used for App Store Connect | Your Apple Developer account | `developer@example.com` |
| `APPLE_TEAM_ID` | Apple Developer Team ID (10 characters) | [developer.apple.com/account](https://developer.apple.com/account) → Membership | `3W77JDM5X2` |
| `APP_IDENTIFIER` | Bundle ID for your app | App's bundle identifier | `com.kje7713.WorkoutTrackerApp` |
| `ASC_KEY_ID` | App Store Connect API Key ID | App Store Connect → Users and Access → Keys | `ABCDEF1234` |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID (UUID) | App Store Connect → Users and Access → Keys | `12345678-1234-1234-1234-123456789012` |
| `ASC_KEY` | App Store Connect API Key (P8 file content) | Download from App Store Connect (one-time) | `-----BEGIN PRIVATE KEY-----\nMIGT...` or base64-encoded |
| `MATCH_GIT_URL` | Git repository URL for storing certificates | Your private certificates repo | `https://github.com/user/ios-certificates` |
| `MATCH_GIT_TOKEN` | GitHub Personal Access Token (PAT) for certificates repo | GitHub → Settings → Developer settings → Personal access tokens | `ghp_xxxxxxxxxxxxxxxxxxxx` |
| `MATCH_PASSWORD` | Encryption password for Match certificates | Create a strong password and save securely | Any secure password |
| `IOS_SCHEME` | Xcode scheme name | From `project.yml` schemes section | `WorkoutTrackerApp` |

---

## GitHub Actions Setup

### File: `.github/workflows/ios-testflight.yml`

#### Key Steps

1. **Checkout Repository**
   - Uses `actions/checkout@v4`

2. **Setup Xcode**
   - Runner: `macos-26` (includes latest Xcode)
   - Lists and selects appropriate Xcode version

3. **Setup Ruby Environment**
   - Ruby version: `3.2`
   - Installs bundler and caches gems

4. **Install Dependencies**
   - Installs XcodeGen via Homebrew
   - Installs Ruby gems (Fastlane) via Bundler

5. **Generate Xcode Project**
   - Runs `xcodegen generate` from `project.yml`

6. **Prepare App Store Connect API Key**
   - Decodes `ASC_KEY` secret (handles base64 or raw PEM)
   - Writes to `fastlane/AuthKey.p8`
   - Validates key is EC P-256 curve

7. **Build & Upload**
   - Calls `bundle exec fastlane beta`
   - Uploads IPA to TestFlight

8. **Artifact Upload**
   - On success: Uploads IPA and dSYM files
   - On failure: Uploads build logs

### Trigger Workflow

```bash
# Via GitHub UI: Actions tab → iOS TestFlight → Run workflow

# Via GitHub CLI
gh workflow run ios-testflight.yml
```

---

## Fastlane Configuration

### File: `fastlane/Fastfile`

#### Lane: `beta`

**Purpose**: Build app and upload to TestFlight

**Key Features**:

1. **App Store Connect API Authentication**
   ```ruby
   api_key = app_store_connect_api_key(
     key_id: ENV["ASC_KEY_ID"],
     issuer_id: ENV["ASC_ISSUER_ID"],
     key_filepath: "fastlane/AuthKey.p8",
     duration: 1200,
     in_house: false
   )
   ```

2. **CI Keychain Management**
   - Creates temporary keychain for CI builds
   - Sets as default and unlocks
   - Configures timeout (6 hours)

3. **Code Signing with Match**
   ```ruby
   match(
     type: "appstore",
     readonly: true,
     git_url: ENV["MATCH_GIT_URL"],
     git_basic_authorization: Base64.strict_encode64("x-access-token:#{ENV['MATCH_GIT_TOKEN']}"),
     keychain_name: keychain_name,
     keychain_password: keychain_password,
     app_identifier: ENV["APP_IDENTIFIER"],
     team_id: ENV["APPLE_TEAM_ID"]
   )
   ```

4. **Build Number Management**
   - Uses timestamp-based build numbers: `YYYYMMDDHHmmSS`
   - Ensures uniqueness and avoids duplicate upload errors
   - Sets via `set_info_plist_value` for XcodeGen projects

5. **Build Configuration**
   ```ruby
   build_app(
     scheme: scheme,
     export_method: "app-store",
     clean: true,
     silent: false,
     export_options: {
       provisioningProfiles: {
         ENV["APP_IDENTIFIER"] => "match AppStore #{ENV['APP_IDENTIFIER']}"
       }
     },
     xcargs: "DEVELOPMENT_TEAM=... CODE_SIGN_STYLE=Manual ..."
   )
   ```

6. **TestFlight Upload**
   - Graceful handling of agreement errors
   - Provides actionable error messages
   - Continues on agreement issues (IPA still available)

7. **Error Logging**
   - Captures errors to `ci_logs/errors_only.log`
   - Includes gym log tails and extracted errors

### File: `fastlane/Matchfile`

Configures Fastlane Match for certificate management:

```ruby
git_url(ENV["MATCH_GIT_URL"])
storage_mode("git")
type("appstore")
app_identifier(["com.kje7713.WorkoutTrackerApp"])
username(ENV["APPLE_ID"])
team_id(ENV["APPLE_TEAM_ID"])
readonly(true)
git_basic_authorization(Base64.strict_encode64("#{ENV['MATCH_GIT_TOKEN']}:x-oauth-basic"))
```

---

## Code Signing with Match

### What is Fastlane Match?

Match stores iOS certificates and provisioning profiles in a Git repository, encrypted with a password. This allows teams to share code signing identities across CI/CD systems.

### Repository Structure

Your `MATCH_GIT_URL` repository will contain:

```
certs/
  distribution/
    <team_id>.cer
    <team_id>.p12
profiles/
  appstore/
    AppStore_<bundle_id>.mobileprovision
match_version.txt
```

### Initial Setup (One-Time)

1. **Create a Private GitHub Repository**
   ```bash
   # Example: ios-certificates
   ```

2. **Generate Match Certificates**
   ```bash
   # Run locally (not in CI)
   bundle exec fastlane match appstore
   ```
   - This creates certificates and pushes to your Match repo
   - You'll be prompted for the encryption password (`MATCH_PASSWORD`)

3. **Create GitHub Personal Access Token**
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Create token with `repo` scope (full repository access)
   - Save as `MATCH_GIT_TOKEN`

### Certificate Rotation

Certificates expire after 1 year. To renew:

```bash
bundle exec fastlane match nuke distribution
bundle exec fastlane match appstore
```

---

## Project Generation with XcodeGen

### File: `project.yml`

XcodeGen generates the `.xcodeproj` from a YAML specification.

#### Key Configuration

```yaml
name: WorkoutTrackerApp

options:
  bundleIdPrefix: com.kje7713
  deploymentTarget:
    iOS: "16.0"

settings:
  base:
    DEVELOPMENT_TEAM: ${APPLE_TEAM_ID}
    CODE_SIGN_STYLE: Manual
    CURRENT_PROJECT_VERSION: "1"
    MARKETING_VERSION: "1.2"

targets:
  WorkoutTrackerApp:
    type: application
    platform: iOS
    info:
      path: Info.plist
      properties:
        CFBundleIdentifier: ${APP_IDENTIFIER}
        CFBundleDisplayName: "SBD"
    sources:
      - path: .
        includes:
          - "*.swift"
          - "Assets.xcassets"
          - "LaunchScreen.storyboard"
          - "PrivacyInfo.xcprivacy"
    settings:
      base:
        CODE_SIGN_IDENTITY: "Apple Distribution"
```

#### Environment Variables Used

- `APPLE_TEAM_ID`: Set in CI environment
- `APP_IDENTIFIER`: Set in CI environment

### Generate Project

```bash
# Install XcodeGen
brew install xcodegen

# Generate .xcodeproj
xcodegen generate
```

**Note**: The `.xcodeproj` is gitignored and generated in CI.

---

## Porting to a New App

Follow these steps to port this pipeline setup to a new iOS app:

### 1. Prerequisites

- Apple Developer account with admin access
- Access to App Store Connect
- GitHub repository for your new app
- Private GitHub repository for certificates (can reuse existing)

### 2. App Store Connect Setup

#### Create App Store Connect API Key

1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Users and Access** → **Keys** → **App Store Connect API**
3. Click **Generate API Key**
4. Select **Admin** role (or appropriate access level)
5. Download the `.p8` file (only available once!)
6. Note the **Key ID** and **Issuer ID**

#### Register App

1. In App Store Connect, go to **My Apps**
2. Click **+** → **New App**
3. Fill in app details (name, bundle ID, SKU)
4. Create the app

### 3. Apple Developer Setup

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Note your **Team ID** (10 characters, in Membership section)
3. Ensure your bundle ID is registered (Identifiers section)

### 4. Configure Your Repository

#### Copy Files to Your New Repository

```bash
# Copy pipeline files
cp -r .github/workflows/ios-testflight.yml <new-repo>/.github/workflows/
cp -r fastlane/ <new-repo>/
cp Gemfile <new-repo>/
cp project.yml <new-repo>/
cp .gitignore <new-repo>/
```

#### Update Configuration Files

**1. `project.yml`**

Update these fields:
- `name`: Your app name
- `bundleIdPrefix`: Your bundle ID prefix (e.g., `com.yourcompany`)
- `deploymentTarget`: iOS version target
- `MARKETING_VERSION`: Your app version
- `CFBundleIdentifier`: Update to `${APP_IDENTIFIER}` (will use secret)
- `CFBundleDisplayName`: Your app's display name
- `sources`: Update include/exclude paths as needed

**2. `fastlane/Matchfile`**

Update:
- `app_identifier`: Your bundle ID (e.g., `["com.yourcompany.NewApp"]`)
- Keep other settings (will use environment variables)

**3. `.github/workflows/ios-testflight.yml`**

Update (if needed):
- Runner version (`macos-26` is recommended for latest)
- Xcode version selection (default is usually fine)
- Ruby version (3.2 recommended)

### 5. Setup GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets (click **New repository secret** for each):

| Secret | Value | Notes |
|--------|-------|-------|
| `APPLE_ID` | Your Apple ID email | |
| `APPLE_TEAM_ID` | Your 10-char team ID | From developer.apple.com |
| `APP_IDENTIFIER` | Your bundle ID | e.g., `com.company.AppName` |
| `ASC_KEY_ID` | API Key ID | From App Store Connect |
| `ASC_ISSUER_ID` | Issuer UUID | From App Store Connect |
| `ASC_KEY` | Content of `.p8` file | Entire file or base64-encoded |
| `MATCH_GIT_URL` | Git URL for certificates | e.g., `https://github.com/user/ios-certs` |
| `MATCH_GIT_TOKEN` | GitHub PAT | With `repo` scope |
| `MATCH_PASSWORD` | Encryption password | Create a strong password |
| `IOS_SCHEME` | Xcode scheme name | Must match `project.yml` |

### 6. Setup Code Signing with Match

#### First-Time Match Setup

```bash
# In your project directory
bundle install

# Initialize Match (creates certificates)
bundle exec fastlane match appstore

# When prompted:
# - Enter your MATCH_GIT_URL
# - Enter your MATCH_PASSWORD (save this!)
# - Authenticate with Apple ID
```

This will:
- Create a distribution certificate
- Create an App Store provisioning profile
- Encrypt and store them in your Match repository

#### Verify Match Repository

Check your `MATCH_GIT_URL` repository - you should see:
```
certs/distribution/
profiles/appstore/
match_version.txt
```

### 7. Test the Pipeline

#### Local Test

```bash
# Generate project
xcodegen generate

# Set environment variables
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="ABC123XYZ"
export APP_IDENTIFIER="com.company.app"
export ASC_KEY_ID="ABCD123456"
export ASC_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export MATCH_GIT_URL="https://github.com/user/ios-certs"
export MATCH_GIT_TOKEN="ghp_xxxxx"
export MATCH_PASSWORD="your_password"
export IOS_SCHEME="YourAppScheme"

# Download the AuthKey.p8 to fastlane/
cp ~/Downloads/AuthKey_ABCD123456.p8 fastlane/AuthKey.p8

# Test build (without upload)
bundle exec fastlane ios beta
```

#### CI Test

1. Push your changes to GitHub
2. Go to **Actions** tab
3. Select **iOS TestFlight** workflow
4. Click **Run workflow**
5. Monitor the run - first run may take 10-15 minutes

### 8. Verify TestFlight Upload

1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your app → **TestFlight** tab
3. Check for the build (may take 5-10 minutes to process)
4. Add testers and distribute

---

## Troubleshooting

### Common Issues

#### 1. "No Provisioning Profiles Found"

**Cause**: Match hasn't created profiles or can't access them.

**Fix**:
```bash
# Verify Match repository access
git clone $MATCH_GIT_URL /tmp/match-test

# Re-run Match to create profiles
bundle exec fastlane match appstore --force_for_new_devices
```

#### 2. "Certificate Has Expired"

**Cause**: Distribution certificate expired (valid for 1 year).

**Fix**:
```bash
# Revoke old certificate and create new
bundle exec fastlane match nuke distribution
bundle exec fastlane match appstore
```

Update the certificate in your Match repository.

#### 3. "Could Not Find Xcode Project"

**Cause**: XcodeGen didn't run or failed.

**Fix**:
```bash
# Run manually to see errors
xcodegen generate

# Check project.yml syntax
```

#### 4. "Code Signing Error: No Profile"

**Cause**: Profile not installed or doesn't match bundle ID.

**Fix**:
- Verify `APP_IDENTIFIER` matches `project.yml`
- Verify profile exists in Match repo
- Check provisioning profile specifier in build settings

#### 5. "AuthKey.p8 Invalid Format"

**Cause**: API key not properly formatted or encoded.

**Fix**:
```bash
# Verify key format
cat fastlane/AuthKey.p8
# Should start with: -----BEGIN PRIVATE KEY-----

# Or base64 encode properly
base64 -i AuthKey_KEYID.p8 | tr -d '\n' > encoded_key.txt
# Use content of encoded_key.txt as secret
```

#### 6. "Duplicate Upload" Error

**Cause**: Build number hasn't changed.

**Fix**: This should not occur with timestamp-based builds, but if it does:
```bash
# Check Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist

# Manually increment if needed
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%Y%m%d%H%M%S)" Info.plist
```

#### 7. "App Store Connect Agreement" Error

**Cause**: New agreements need acceptance in App Store Connect.

**Fix**:
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Accept any pending agreements on the home page
3. Re-run the workflow

The workflow handles this gracefully and provides clear instructions.

#### 8. "Match Git Authentication Failed"

**Cause**: `MATCH_GIT_TOKEN` expired or lacks permissions.

**Fix**:
1. Generate new GitHub PAT with `repo` scope
2. Update `MATCH_GIT_TOKEN` secret
3. Test access:
```bash
git ls-remote https://x-access-token:$MATCH_GIT_TOKEN@github.com/user/ios-certs.git
```

### Debug Commands

```bash
# Check keychain contents (local)
security find-identity -p codesigning

# List installed provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Validate certificate
openssl x509 -in certificate.cer -text -noout

# Check Match repository
bundle exec fastlane match development --readonly

# Verbose Fastlane output
bundle exec fastlane beta --verbose

# Check XcodeGen output
xcodegen generate --verbose
```

### Logs to Check

- **GitHub Actions**: Check the "Build & Upload to TestFlight" step output
- **Fastlane logs**: `~/Library/Logs/fastlane/`
- **Gym logs**: `~/Library/Logs/gym/`
- **Error summary**: `ci_logs/errors_only.log` (in artifacts)
- **Xcode build logs**: DerivedData folders

---

## Additional Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane Match Guide](https://docs.fastlane.tools/actions/match/)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## Summary Checklist

Use this checklist when porting to a new app:

- [ ] Create App Store Connect API key (download P8 file)
- [ ] Register app in App Store Connect
- [ ] Note Apple Team ID from developer.apple.com
- [ ] Create private GitHub repository for certificates
- [ ] Generate GitHub Personal Access Token (PAT)
- [ ] Choose encryption password for Match
- [ ] Copy pipeline files to new repository
- [ ] Update `project.yml` with new app details
- [ ] Update `fastlane/Matchfile` with new bundle ID
- [ ] Configure all GitHub Secrets (10 secrets)
- [ ] Run `bundle install` locally
- [ ] Initialize Match: `bundle exec fastlane match appstore`
- [ ] Generate Xcode project: `xcodegen generate`
- [ ] Test build locally (optional): `bundle exec fastlane beta`
- [ ] Trigger GitHub Actions workflow
- [ ] Verify build in App Store Connect → TestFlight
- [ ] Document any custom modifications

---

**Last Updated**: February 2026  
**Maintained By**: Development Team
