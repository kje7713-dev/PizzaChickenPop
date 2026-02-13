# Quick Start: Porting Pipeline to New App

This is a condensed checklist for porting the CI/CD pipeline to a new iOS app. For detailed explanations, see [PIPELINE_SETUP_GUIDE.md](PIPELINE_SETUP_GUIDE.md).

## Prerequisites Checklist

- [ ] Apple Developer account (admin access)
- [ ] App registered in App Store Connect
- [ ] GitHub repository for new app
- [ ] Private GitHub repository for certificates (can reuse existing)
- [ ] Password manager for storing secrets

## Step 1: Gather Apple Information (10 minutes)

### App Store Connect API Key
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Users and Access** → **Keys** → **App Store Connect API**
3. Click **Generate API Key** (Admin access)
4. Download the `.p8` file immediately ⚠️ (only available once!)
5. Note: **Key ID** and **Issuer ID**

### Apple Developer Info
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Note your **Team ID** (Membership section, 10 characters)
3. Confirm bundle ID is registered

**Save these values:**
- ✅ Apple ID (email): `_______________`
- ✅ Team ID: `_______________`
- ✅ Bundle ID: `_______________`
- ✅ ASC Key ID: `_______________`
- ✅ ASC Issuer ID: `_______________`
- ✅ ASC Key file path: `_______________`

## Step 2: Setup Certificate Repository (5 minutes)

1. Create new **private** GitHub repository:
   ```bash
   # Example: ios-certificates
   # Visibility: PRIVATE
   ```

2. Generate GitHub Personal Access Token:
   - Go to [GitHub Settings → Tokens](https://github.com/settings/tokens)
   - Click **Generate new token (classic)**
   - Name: "Match Certificate Access"
   - Scope: Check **`repo`**
   - Copy token immediately

3. Choose Match encryption password:
   ```bash
   # Generate strong password
   openssl rand -base64 32
   ```

**Save these values:**
- ✅ Match Git URL: `_______________`
- ✅ Match Git Token: `_______________`
- ✅ Match Password: `_______________`

## Step 3: Copy Pipeline Files (2 minutes)

```bash
# Copy from WorkoutTrackerApp to your new app repository
cp -r .github/workflows/ios-testflight.yml <new-app>/.github/workflows/
cp -r fastlane/ <new-app>/
cp Gemfile <new-app>/
cp project.yml <new-app>/
cp .gitignore <new-app>/
```

## Step 4: Update Configuration Files (10 minutes)

### Update `project.yml`

Find and replace these values:

```yaml
name: YourAppName                           # Line 1
bundleIdPrefix: com.yourcompany             # Line 4
CFBundleDisplayName: "Your App"             # Line 37
```

### Update `fastlane/Matchfile`

```ruby
app_identifier(["com.yourcompany.YourApp"]) # Line 5
```

**3. `.github/workflows/ios-testflight.yml`**

Usually no changes needed, but verify:
- Runner version (line 8): `macos-26` ✅
- Ruby version (line 35): `3.2` ✅

## Step 5: Configure GitHub Secrets (5 minutes)

Go to your GitHub repo: **Settings** → **Secrets and variables** → **Actions**

Click **New repository secret** for each:

| Secret Name | Your Value |
|------------|-----------|
| `APPLE_ID` | (from Step 1) |
| `APPLE_TEAM_ID` | (from Step 1) |
| `APP_IDENTIFIER` | (from Step 1) |
| `ASC_KEY_ID` | (from Step 1) |
| `ASC_ISSUER_ID` | (from Step 1) |
| `ASC_KEY` | (contents of .p8 file) |
| `MATCH_GIT_URL` | (from Step 2) |
| `MATCH_GIT_TOKEN` | (from Step 2) |
| `MATCH_PASSWORD` | (from Step 2) |
| `IOS_SCHEME` | (scheme name from project.yml) |

**For ASC_KEY**: Paste entire `.p8` file content:
```
-----BEGIN PRIVATE KEY-----
[key content]
-----END PRIVATE KEY-----
```

## Step 6: Initialize Code Signing (5 minutes)

On your local machine:

```bash
cd <new-app-directory>

# Install dependencies
bundle install

# Initialize Match (creates certificates)
bundle exec fastlane match appstore

# When prompted:
# - Git URL: <your Match repo URL>
# - Password: <your Match password>
# - Authenticate with Apple ID when asked
```

This creates:
- ✅ Distribution certificate
- ✅ App Store provisioning profile
- ✅ Encrypted storage in Match repository

## Step 7: Test Locally (10 minutes)

```bash
# Generate Xcode project
xcodegen generate

# Verify project opens
open YourApp.xcodeproj

# Set environment variables (temporary test)
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="ABC123XYZ"
export APP_IDENTIFIER="com.company.app"
export ASC_KEY_ID="ABCD123456"
export ASC_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export MATCH_GIT_URL="https://github.com/user/ios-certs"
export MATCH_GIT_TOKEN="ghp_xxxxx"
export MATCH_PASSWORD="your_password"
export IOS_SCHEME="YourAppScheme"

# Copy P8 key to fastlane directory
cp ~/Downloads/AuthKey_YOURKEY.p8 fastlane/AuthKey.p8

# Test build (optional, takes ~10 minutes)
bundle exec fastlane beta
```

## Step 8: Test in CI (15 minutes)

```bash
# Push changes to GitHub
git add .
git commit -m "Setup CI/CD pipeline"
git push
```

Trigger workflow:
1. Go to GitHub repo → **Actions** tab
2. Select **iOS TestFlight** workflow
3. Click **Run workflow** → **Run workflow**
4. Monitor build (takes 10-15 minutes first time)

## Step 9: Verify TestFlight (5 minutes)

1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your app → **TestFlight** tab
3. Wait 5-10 minutes for build processing
4. Build should appear in "iOS Builds" section

---

## Verification Checklist

After completing all steps:

- [ ] All 10 GitHub Secrets are configured
- [ ] Match repository contains certificates
- [ ] `xcodegen generate` runs without errors
- [ ] GitHub Actions workflow runs successfully
- [ ] Build appears in TestFlight
- [ ] Documentation saved in password manager
- [ ] Team members have access to necessary secrets

---

## Time Estimate

- **First time (including reading docs)**: 2-3 hours
- **Subsequent apps**: 30-45 minutes
- **Troubleshooting**: Add 30-60 minutes buffer

---

## Common First-Time Issues

### "Provisioning profile not found"
```bash
# Regenerate profiles
bundle exec fastlane match appstore --force
```

### "Invalid Key Format"
```bash
# Verify key format
openssl pkey -in fastlane/AuthKey.p8 -pubout >/dev/null 2>&1 && echo "Valid" || echo "Invalid"
```

### "Match authentication failed"
```bash
# Test Git access
git ls-remote https://x-access-token:YOUR_TOKEN@github.com/user/ios-certs.git
```

### "Build failed in CI"
1. Check Actions → Workflow run → Logs
2. Look for error in "Build & Upload to TestFlight" step
3. Download "ios-build-logs" artifact
4. Check `errors_only.log`

---

## Next Steps After Success

1. **Add team members**: Share secrets securely via password manager
2. **Setup notifications**: Configure GitHub Actions notifications
3. **Configure TestFlight**: Add beta testers
4. **Document custom changes**: Note any modifications specific to your app

---

## Reference Documentation

For detailed information:

- **[PIPELINE_SETUP_GUIDE.md](PIPELINE_SETUP_GUIDE.md)** - Complete setup guide with explanations
- **[SECRETS_REFERENCE.md](SECRETS_REFERENCE.md)** - All secrets with format examples
- **[PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)** - Visual flow diagrams
- **[Troubleshooting](PIPELINE_SETUP_GUIDE.md#troubleshooting)** - Common issues and solutions

---

## Support

If stuck:
1. Review detailed guides above
2. Check workflow logs in GitHub Actions
3. Verify all secrets are set correctly
4. Review Match repository contents
5. Test commands locally before running in CI

---

**Estimated Total Time**: 1-2 hours for first setup  
**Last Updated**: February 2026
