# CI/CD Pipeline Architecture

Visual overview of the WorkoutTrackerApp CI/CD pipeline.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer / GitHub                          │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         │ Push / Manual Trigger
                         │
                         ▼
                ┌────────────────┐
                │ GitHub Actions │
                │   (CI/CD)      │
                └────────┬───────┘
                         │
                         │
    ┌────▼────────────────────────────┬──▼────┐
    │                                 │       │
    ▼                                 ▼       ▼
┌──────────┐                    ┌──────────┐ │
│ XcodeGen │                    │ XcodeGen │ │
│ Generate │                    │ Generate │ │
└────┬─────┘                    └────┬─────┘ │
     │                               │       │
     │ Creates .xcodeproj            │       │
     │                               │       │
     ▼                               ▼       │
┌──────────┐                    ┌──────────┐ │
│ Fastlane │                    │ xcodebuild│ │
│  Match   │                    │   Build  │ │
└────┬─────┘                    └────┬─────┘ │
     │                               │       │
     │ Fetches certificates          │       │
     │ from Match Repo               │       │
     │                               │       │
     ▼                               │       │
┌──────────────┐                     │       │
│ Match Repo   │◄────────────────────┘       │
│ (ios-certs)  │                             │
└────┬─────────┘                             │
     │                                       │
     │ Provides signing materials            │
     │                                       │
     ▼                                       │
┌──────────┐                                 │
│ Fastlane │                                 │
│  Build   │                                 │
│  (Gym)   │◄────────────────────────────────┘
└────┬─────┘
     │
     │ Builds .ipa + .dSYM
     │
     ▼
┌──────────────────┐
│ Upload to        │
│ App Store Connect│
│   (TestFlight)   │
└────┬─────────────┘
     │
     │ Processes build
     │
     ▼
┌──────────────────┐
│   TestFlight     │
│   (Beta Testers) │
└──────────────────┘
```

---

## Detailed GitHub Actions Workflow

```
┌──────────────────────────────────────────────────────────────┐
│ GitHub Actions Workflow: ios-testflight.yml                  │
└──────────────────────────────────────────────────────────────┘

1. Trigger
   └─→ Manual (workflow_dispatch)

2. Runner: macos-26
   ├─→ Checkout repository
   ├─→ Select Xcode version
   ├─→ Setup Ruby 3.2
   └─→ Install gems (bundle install)

3. Install XcodeGen
   └─→ brew install xcodegen

4. Generate Xcode Project
   └─→ xcodegen generate
       └─→ Reads: project.yml
       └─→ Creates: WorkoutTrackerApp.xcodeproj

5. Prepare App Store Connect Key
   ├─→ Read secret: ASC_KEY
   ├─→ Decode (base64/PEM)
   ├─→ Write: fastlane/AuthKey.p8
   └─→ Validate: EC P-256 curve

6. Build & Upload (Fastlane)
   └─→ bundle exec fastlane beta
       │
       ├─→ App Store Connect API Authentication
       │   ├─→ Key ID: ASC_KEY_ID
       │   ├─→ Issuer ID: ASC_ISSUER_ID
       │   └─→ Key File: fastlane/AuthKey.p8
       │
       ├─→ Create CI Keychain
       │   ├─→ security create-keychain
       │   ├─→ security unlock-keychain
       │   └─→ security set-keychain-settings
       │
       ├─→ Fastlane Match (Code Signing)
       │   ├─→ Type: appstore
       │   ├─→ Git URL: MATCH_GIT_URL
       │   ├─→ Auth: MATCH_GIT_TOKEN
       │   ├─→ Password: MATCH_PASSWORD
       │   ├─→ Fetches:
       │   │   ├─→ Distribution Certificate
       │   │   └─→ Provisioning Profile
       │   └─→ Installs to keychain
       │
       ├─→ Set Build Number
       │   └─→ Timestamp: YYYYMMDDHHmmSS
       │
       ├─→ Build App (Gym)
       │   ├─→ Scheme: IOS_SCHEME
       │   ├─→ Export: app-store
       │   ├─→ Clean build
       │   └─→ Outputs:
       │       ├─→ WorkoutTrackerApp.ipa
       │       └─→ WorkoutTrackerApp.app.dSYM.zip
       │
       └─→ Upload to TestFlight
           ├─→ API Key authentication
           ├─→ Handle agreement errors gracefully
           └─→ Submit to TestFlight

7. Upload Artifacts
   ├─→ IPA + dSYM files
   └─→ Build logs (always, even on failure)

8. Cleanup
   └─→ Delete CI keychain
```

---

## Code Signing Flow with Match

```
┌────────────────────────────────────────────────────────────┐
│ Fastlane Match - Certificate Management                    │
└────────────────────────────────────────────────────────────┘

┌─────────────────┐
│ Developer/CI    │
└────────┬────────┘
         │
         │ bundle exec fastlane match appstore
         │
         ▼
┌────────────────────────────┐
│ Fastlane Match            │
├────────────────────────────┤
│ Type: appstore            │
│ Readonly: true (CI)       │
│ Git URL: MATCH_GIT_URL    │
│ Auth: MATCH_GIT_TOKEN     │
│ Password: MATCH_PASSWORD  │
└────────┬───────────────────┘
         │
         │ 1. Authenticate with GitHub
         │
         ▼
┌──────────────────────────────────────┐
│ Match Git Repository                 │
│ (Private, Encrypted)                 │
├──────────────────────────────────────┤
│ certs/                              │
│   distribution/                     │
│     TEAM_ID.cer (Certificate)      │
│     TEAM_ID.p12 (Private Key)      │
│ profiles/                           │
│   appstore/                         │
│     AppStore_BUNDLE_ID.mobileprov  │
│ match_version.txt                   │
└────────┬─────────────────────────────┘
         │
         │ 2. Clone & decrypt with MATCH_PASSWORD
         │
         ▼
┌────────────────────────────┐
│ Local System              │
├────────────────────────────┤
│ ~/.fastlane/match/        │
│   certs/                  │
│   profiles/               │
└────────┬───────────────────┘
         │
         │ 3. Install to keychain
         │
         ▼
┌────────────────────────────┐
│ Keychain                  │
├────────────────────────────┤
│ - Distribution Certificate│
│ - Private Key             │
└────────┬───────────────────┘
         │
         │ 4. Install provisioning profile
         │
         ▼
┌─────────────────────────────────────────────┐
│ ~/Library/MobileDevice/Provisioning Profiles│
├─────────────────────────────────────────────┤
│ - AppStore_BUNDLE_ID.mobileprovision        │
└────────┬────────────────────────────────────┘
         │
         │ 5. Ready for xcodebuild
         │
         ▼
┌────────────────────────────┐
│ Xcode Build System        │
│ (Code Signing Ready)      │
└───────────────────────────┘
```

---

## Secret Flow Diagram

```
┌────────────────────────────────────────────────────────────────┐
│ Secret Management Flow                                         │
└────────────────────────────────────────────────────────────────┘

CONFIGURATION SOURCE
├─→ GitHub Secrets (for GitHub Actions)
│   ├─→ APPLE_ID
│   ├─→ APPLE_TEAM_ID
│   ├─→ APP_IDENTIFIER
│   ├─→ ASC_KEY_ID
│   ├─→ ASC_ISSUER_ID
│   ├─→ ASC_KEY (P8 file content)
│   ├─→ MATCH_GIT_URL
│   ├─→ MATCH_GIT_TOKEN
│   ├─→ MATCH_PASSWORD
│   └─→ IOS_SCHEME

RUNTIME USAGE
├─→ App Store Connect API Authentication
│   ├─→ Uses: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY
│   └─→ Purpose: Build upload, certificate management
│
├─→ Match Repository Access
│   ├─→ Uses: MATCH_GIT_URL, MATCH_GIT_TOKEN
│   └─→ Purpose: Fetch signing materials
│
├─→ Certificate Decryption
│   ├─→ Uses: MATCH_PASSWORD
│   └─→ Purpose: Decrypt certificates from Match repo
│
└─→ Code Signing
    ├─→ Uses: APPLE_TEAM_ID, APP_IDENTIFIER
    └─→ Purpose: Build configuration

EXTERNAL SERVICES
├─→ App Store Connect
│   └─→ Authenticated via ASC API Key
│
├─→ Apple Developer Portal
│   └─→ Authenticated via ASC API Key
│
├─→ Match Git Repository
│   └─→ Authenticated via GitHub PAT
│
└─→ Xcode Build System
    └─→ Uses installed certificates & profiles
```

---

## Build Artifact Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Build Artifacts & Outputs                                   │
└─────────────────────────────────────────────────────────────┘

SOURCE CODE
├─→ *.swift files
├─→ Assets.xcassets
├─→ LaunchScreen.storyboard
├─→ Info.plist
└─→ PrivacyInfo.xcprivacy

   │ Compiled by xcodebuild
   ▼

BUILD OUTPUTS
├─→ WorkoutTrackerApp.app
│   └─→ Executable binary + resources
│
├─→ WorkoutTrackerApp.app.dSYM
│   └─→ Debug symbols for crash reporting
│
└─→ WorkoutTrackerApp.ipa
    └─→ Packaged app (signed for App Store)

   │ Uploaded by Fastlane
   ▼

APP STORE CONNECT
└─→ TestFlight
    ├─→ Build Processing (5-10 minutes)
    │   ├─→ Malware scan
    │   ├─→ API validation
    │   └─→ Binary analysis
    │
    └─→ Available for Testing
        ├─→ Internal Testers (instant)
        └─→ External Testers (after review)

   │ Distributed to testers
   ▼

TESTER DEVICES
└─→ TestFlight App
    └─→ Installed Build
```

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│ Build Dependencies                                          │
└─────────────────────────────────────────────────────────────┘

PROJECT FILES
│
├─→ project.yml ──────────┐
│   (XcodeGen config)     │
│                         │
├─→ Gemfile ──────────────┼──→ TOOL INSTALLATION
│   (Ruby dependencies)   │    │
│                         │    ├─→ Ruby 3.2
│                         │    ├─→ Bundler
├─→ fastlane/Fastfile ────┤    ├─→ Fastlane gem
│   (Build automation)    │    └─→ Dependencies
│                         │
├─→ fastlane/Matchfile ───┤
│   (Code signing config) │
│                         │
└─→ Info.plist ───────────┘

EXTERNAL DEPENDENCIES
│
├─→ XcodeGen
│   └─→ Installed via Homebrew
│
├─→ Xcode + Command Line Tools
│   └─→ Provided by CI runner
│
├─→ Match Git Repository
│   ├─→ Distribution certificate
│   └─→ Provisioning profiles
│
└─→ App Store Connect
    ├─→ API credentials
    └─→ App registration

RUNTIME ENVIRONMENT
│
└─→ GitHub Actions Runner (macos-26)
    ├─→ macOS latest
    ├─→ Xcode latest
    └─→ Build tools
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Build Error Handling                                        │
└─────────────────────────────────────────────────────────────┘

BUILD EXECUTION
│
├─→ SUCCESS
│   ├─→ Generate IPA + dSYM
│   ├─→ Upload to TestFlight
│   ├─→ Upload artifacts to GitHub
│   └─→ Workflow completes ✅
│
└─→ FAILURE
    │
    ├─→ XcodeGen Error
    │   ├─→ Log: stdout
    │   └─→ Check: project.yml syntax
    │
    ├─→ Code Signing Error
    │   ├─→ Log: fastlane output
    │   ├─→ Check: Match repository
    │   └─→ Check: Certificate validity
    │
    ├─→ Build Error
    │   ├─→ Log: ~/Library/Logs/gym/
    │   ├─→ Log: ci_logs/errors_only.log
    │   └─→ Upload: Build logs as artifact
    │
    ├─→ TestFlight Upload Error
    │   │
    │   ├─→ Agreement Error
    │   │   ├─→ Detected by error patterns
    │   │   ├─→ Workflow continues (non-fatal)
    │   │   ├─→ IPA uploaded as artifact
    │   │   └─→ User notified to accept agreements
    │   │
    │   └─→ Other Upload Error
    │       ├─→ Log error message
    │       ├─→ Fail workflow ❌
    │       └─→ Upload logs as artifact
    │
    └─→ All Failures
        ├─→ Run: "Failure summary" step
        ├─→ Tail logs (last 200 lines)
        ├─→ Upload: Build logs artifact
        └─→ GitHub Actions failure notification
```

---

## Quick Reference: Pipeline Commands

```bash
# Local Development
xcodegen generate              # Generate Xcode project
bundle install                 # Install Fastlane dependencies
bundle exec fastlane beta      # Build & upload (requires secrets)

# Code Signing
bundle exec fastlane match appstore           # Setup Match (first time)
bundle exec fastlane match appstore --readonly # Fetch certificates (CI)

# GitHub Actions
gh workflow run ios-testflight.yml           # Trigger workflow
gh run list --workflow=ios-testflight.yml    # List runs
gh run view <run-id> --log                   # View logs

# Debugging
security find-identity -v -p codesigning     # List signing identities
ls ~/Library/MobileDevice/Provisioning\ Profiles/  # List profiles
openssl pkey -in fastlane/AuthKey.p8 -text   # Validate ASC key
```

---

## Related Documentation

- **[Pipeline Setup Guide](PIPELINE_SETUP_GUIDE.md)** - Complete setup instructions
- **[Secrets Reference](SECRETS_REFERENCE.md)** - All secrets and environment variables
- **[Troubleshooting](PIPELINE_SETUP_GUIDE.md#troubleshooting)** - Common issues and fixes

---

**Last Updated**: February 2026  
**Maintained By**: Development Team
