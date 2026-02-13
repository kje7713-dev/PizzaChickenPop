# Migration Guide: From Manual Signing to XcodeGen + Match

This guide helps you migrate from the old manual signing workflow to the new XcodeGen + Fastlane Match pipeline.

## Why Migrate?

The new pipeline offers significant improvements:

- ✅ **No project files in Git** - `.xcodeproj` is generated from YAML
- ✅ **Automated code signing** - Match manages certificates and profiles
- ✅ **Team collaboration** - Share signing assets via encrypted Git repo
- ✅ **Reproducible builds** - Same configuration everywhere
- ✅ **Less maintenance** - No manual certificate updates

## Quick Migration (15 minutes)

### Step 1: Update GitHub Secrets

**Add new secrets:**
```
APPLE_ID              - Your Apple ID email
APPLE_TEAM_ID         - 10-character Team ID
APP_IDENTIFIER        - com.kje7713.PizzaChicken
MATCH_GIT_URL         - URL of your private certificates repo
MATCH_GIT_TOKEN       - GitHub PAT with 'repo' scope
MATCH_PASSWORD        - Encryption password for Match
IOS_SCHEME            - PizzaChicken
```

**Keep existing secrets:**
```
ASC_KEY_ID            - No change
ASC_ISSUER_ID         - No change
ASC_KEY               - Can be raw PEM or base64 (both work)
```

**Remove old secrets** (no longer needed):
```
IOS_P12_BASE64
IOS_P12_PASSWORD
IOS_MOBILEPROVISION_BASE64
IOS_KEYCHAIN_PASSWORD
IOS_EXPORT_OPTIONS_PLIST_BASE64
ASC_KEY_P8_BASE64      - Now just ASC_KEY
IPA_PATH               - No longer used
```

See [GITHUB_SECRETS_LIST.md](GITHUB_SECRETS_LIST.md) for detailed formats.

### Step 2: Create Match Repository

1. Create a new **private** GitHub repository (e.g., `ios-certificates`)
2. Generate a GitHub Personal Access Token:
   - Go to GitHub Settings → Developer settings → Tokens
   - Create token with `repo` scope
3. Generate a strong encryption password:
   ```bash
   openssl rand -base64 32
   ```
4. Store both securely in password manager

### Step 3: Initialize Match Locally

```bash
# Install dependencies
bundle install

# Set environment variables temporarily
export MATCH_GIT_URL="https://github.com/YOUR_USERNAME/ios-certificates"
export MATCH_GIT_TOKEN="ghp_xxxxx"
export MATCH_PASSWORD="your_secure_password"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APP_IDENTIFIER="com.kje7713.PizzaChicken"

# Initialize Match (creates certificates and profiles)
bundle exec fastlane match appstore

# When prompted:
# - Authenticate with your Apple ID
# - Allow Match to create/fetch certificates
# - Certificates are encrypted and stored in Match repo
```

This only needs to be done once per project. Match will create:
- Distribution certificate
- App Store provisioning profile
- Encrypted storage in the Match repository

### Step 4: Update Workflow

The new workflow is already in place at `.github/workflows/ios-testflight.yml`.

To use it:
1. Go to GitHub → Actions
2. Select **"iOS TestFlight Deployment"** workflow
3. Click **"Run workflow"**

The old `ios-build.yml` workflow is deprecated but kept for reference.

### Step 5: Verify

After triggering the workflow:

1. **Check workflow logs** - Should see:
   - ✅ XcodeGen generating project
   - ✅ Match fetching certificates
   - ✅ Build succeeding
   - ✅ Upload to TestFlight

2. **Download artifacts** - IPA and dSYM files available

3. **Check TestFlight** - Build should appear in 5-10 minutes

## Local Development

### First Time Setup

```bash
# Install XcodeGen
brew install xcodegen

# Install Ruby dependencies
bundle install

# Generate Xcode project
xcodegen generate

# Open in Xcode
open PizzaChicken.xcodeproj
```

### Daily Workflow

```bash
# Pull latest changes
git pull

# Regenerate project if project.yml changed
xcodegen generate

# Open and build in Xcode
open PizzaChicken.xcodeproj
```

### Making Changes

1. Modify Swift code in `Sources/`
2. Update `project.yml` if adding files/targets
3. Run `xcodegen generate` to regenerate project
4. Build and test in Xcode

**Never edit `.xcodeproj` directly** - it's generated from `project.yml`

## Troubleshooting

### "Match authentication failed"

**Cause:** Invalid GitHub token or repository doesn't exist

**Fix:**
```bash
# Test Git access
git ls-remote https://x-access-token:YOUR_TOKEN@github.com/user/ios-certificates.git

# If failed, regenerate token with 'repo' scope
```

### "No code signing identity found"

**Cause:** Match repository is empty or certificates expired

**Fix:**
```bash
# Regenerate certificates
bundle exec fastlane match appstore --force

# This creates new certificates and updates Match repo
```

### "Project file not found"

**Cause:** `.xcodeproj` not generated

**Fix:**
```bash
# Generate project
xcodegen generate

# Verify it was created
ls -la *.xcodeproj
```

### "Bundle ID mismatch"

**Cause:** `APP_IDENTIFIER` secret doesn't match `project.yml`

**Fix:**
- Verify `APP_IDENTIFIER` secret: `com.kje7713.PizzaChicken`
- Check `project.yml` line 5: `bundleIdPrefix: com.kje7713`

### "Build failed in CI"

**Steps to diagnose:**
1. Go to GitHub Actions → Failed workflow
2. Expand failed step
3. Download `ios-build-logs` artifact
4. Check error message
5. See [Transfers/PIPELINE_SETUP_GUIDE.md#troubleshooting](Transfers/PIPELINE_SETUP_GUIDE.md#troubleshooting)

## Rollback (if needed)

If you need to rollback to manual signing:

1. Use the old `ios-build.yml` workflow (still present)
2. Restore old secrets (P12, provisioning profile, etc.)
3. The old workflow is deprecated but functional

However, we recommend fixing issues with the new pipeline instead of rolling back.

## Benefits You'll See

### Immediate
- ✅ Cleaner Git history (no `.xcodeproj` changes)
- ✅ No merge conflicts on project files
- ✅ Faster PR reviews (YAML changes only)

### Long-term
- ✅ Easy certificate renewal (just run Match)
- ✅ Team onboarding (just clone and generate)
- ✅ Consistent builds across team
- ✅ Easier multi-app management

## Complete Documentation

For detailed information, see the **Transfers/** folder:

- **[QUICK_START_PIPELINE.md](Transfers/QUICK_START_PIPELINE.md)** - Fast setup checklist
- **[PIPELINE_SETUP_GUIDE.md](Transfers/PIPELINE_SETUP_GUIDE.md)** - Complete guide
- **[PIPELINE_ARCHITECTURE.md](Transfers/PIPELINE_ARCHITECTURE.md)** - Architecture diagrams
- **[SECRETS_REFERENCE.md](Transfers/SECRETS_REFERENCE.md)** - All secrets explained

## Getting Help

1. Check troubleshooting section above
2. Review [Transfers/](Transfers/) documentation
3. Check workflow logs in GitHub Actions
4. Verify all secrets are set correctly

---

**Migration Time:** ~15 minutes  
**Difficulty:** Easy  
**Reversible:** Yes (old workflow still available)

**Questions?** See the comprehensive documentation in [Transfers/](Transfers/)
