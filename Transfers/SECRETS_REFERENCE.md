# Secrets & Environment Variables Reference

Quick reference for all secrets and environment variables used in the CI/CD pipelines.

## GitHub Secrets

**Location**: Repository → Settings → Secrets and variables → Actions

| Secret Name | Description | How to Obtain | Required For |
|------------|-------------|---------------|--------------|
| `APPLE_ID` | Apple Developer account email | Your Apple ID | Fastlane, Match |
| `APPLE_TEAM_ID` | 10-character Team ID | [developer.apple.com](https://developer.apple.com/account) → Membership | Code signing |
| `APP_IDENTIFIER` | App's bundle identifier | Your app's bundle ID | All pipelines |
| `ASC_KEY_ID` | App Store Connect API Key ID | App Store Connect → Users and Access → Keys | API authentication |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID (UUID) | App Store Connect → Users and Access → Keys | API authentication |
| `ASC_KEY` | App Store Connect API private key | Download P8 file from App Store Connect | API authentication |
| `MATCH_GIT_URL` | Git repository URL for certificates | Your private GitHub repository | Code signing |
| `MATCH_GIT_TOKEN` | GitHub Personal Access Token | GitHub → Settings → Developer settings → Tokens | Match authentication |
| `MATCH_PASSWORD` | Encryption password for Match | Create and securely store | Certificate encryption |
| `IOS_SCHEME` | Xcode scheme name | From `project.yml` | Build configuration |

### Secret Value Formats

#### APPLE_ID
```
developer@example.com
```

#### APPLE_TEAM_ID
```
3W77JDM5X2
```
*(10 alphanumeric characters)*

#### APP_IDENTIFIER
```
com.kje7713.WorkoutTrackerApp
```
*(Reverse domain notation)*

#### ASC_KEY_ID
```
ABCD123456
```
*(10 alphanumeric characters)*

#### ASC_ISSUER_ID
```
12345678-1234-1234-1234-123456789012
```
*(UUID format)*

#### ASC_KEY
**Option 1: Raw PEM format**
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
[multiple lines]
...5mQpHKxN2C8=
-----END PRIVATE KEY-----
```

**Option 2: Base64-encoded (entire file)**
```
LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J...
```

**Option 3: Base64-encoded body (no headers)**
```
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
```

*All three formats are handled by the workflow*

#### MATCH_GIT_URL
```
https://github.com/username/ios-certificates
```
*(Must be a private repository)*

#### MATCH_GIT_TOKEN
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
*(GitHub Personal Access Token with `repo` scope)*

#### MATCH_PASSWORD
```
YourSecurePassword123!
```
*(Any secure password - save it safely!)*

#### IOS_SCHEME
```
WorkoutTrackerApp
```
*(Must match scheme name in `project.yml`)*

---

## Optional Environment Variables

These environment variables can be set in workflow files to control pipeline behavior.

| Variable Name | Description | Default Value | When to Use |
|--------------|-------------|---------------|-------------|
| `MATCH_READONLY` | Controls whether Match can create certificates/profiles | `"true"` | Set to `"false"` for initial bootstrap |

### MATCH_READONLY

**Purpose**: Controls whether Fastlane Match operates in readonly mode.

**Default**: `"true"` (readonly mode enabled)

**When to set to `"false"`**:
- First-time setup when no certificates exist
- When you need Match to create new distribution certificates
- When you need Match to create new provisioning profiles

**Usage in GitHub Actions**:
```yaml
env:
  MATCH_READONLY: "false"  # Allows Match to create certificates
```

**After bootstrap**:
Once Match has created the necessary certificates and profiles and committed them to your certificate repository, change back to `"true"` (or remove the env variable to use the default):
```yaml
env:
  MATCH_READONLY: "true"  # Default: readonly mode
```

**Important Notes**:
- Only one team member should run with `MATCH_READONLY=false` at a time
- After running with `false`, verify certificates were committed to your Match repository
- For normal CI builds, always use `true` (readonly mode)
- The value must be a string: `"true"` or `"false"` (in quotes)

---

## How to Create Required Items

### 1. App Store Connect API Key

1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Users and Access** → **Keys** → **App Store Connect API**
3. Click **Generate API Key** or **+**
4. Name: "CI/CD Pipeline" (or similar)
5. Access: **Admin** (or appropriate level)
6. Click **Generate**
7. **Download the `.p8` file immediately** (only available once!)
8. Note the **Key ID** (shows in table)
9. Note the **Issuer ID** (shows at top of Keys page)

**Important**: 
- Store the `.p8` file securely - you cannot download it again
- If lost, you must revoke and create a new key
- Maximum 50 API keys per team

### 2. GitHub Personal Access Token (PAT)

1. Go to [GitHub Settings](https://github.com/settings/tokens)
2. Click **Developer settings** → **Personal access tokens** → **Tokens (classic)**
3. Click **Generate new token** → **Generate new token (classic)**
4. Name: "Match Certificate Access" (or similar)
5. Expiration: **No expiration** (or set appropriate duration)
6. Scopes: Check **`repo`** (Full control of private repositories)
7. Click **Generate token**
8. **Copy the token immediately** (cannot be viewed again)

**Security Notes**:
- Treat PATs like passwords
- Use fine-grained tokens if possible (newer option)
- Consider using dedicated bot account for CI/CD
- Rotate tokens periodically

### 3. Match Git Repository

1. Create a new **private** GitHub repository
   - Name: `ios-certificates` (or similar)
   - Visibility: **Private** (critical!)
   - Initialize: Empty (no README)

2. The repository will store:
   ```
   certs/
     distribution/
       [TEAM_ID].cer
       [TEAM_ID].p12
   profiles/
     appstore/
       AppStore_[BUNDLE_ID].mobileprovision
   match_version.txt
   ```

3. **Never make this repository public** - it contains sensitive signing materials

### 4. Match Encryption Password

Create a strong password for encrypting certificates:

```bash
# Generate a random password (macOS/Linux)
openssl rand -base64 32

# Or use a password manager to generate
```

**Important**:
- Save password in a secure password manager
- Share with team securely (not via email/Slack)
- If lost, you'll need to nuke and recreate certificates
- Consider using the same password across projects

---

## Validation Commands

### Verify GitHub Secrets Are Set

```bash
# Using GitHub CLI
gh secret list

# Should show:
# APPLE_ID
# APPLE_TEAM_ID
# APP_IDENTIFIER
# ASC_ISSUER_ID
# ASC_KEY
# ASC_KEY_ID
# IOS_SCHEME
# MATCH_GIT_TOKEN
# MATCH_GIT_URL
# MATCH_PASSWORD
```

### Verify ASC Key Format

```bash
# Test if key file is valid EC P-256
openssl pkey -in fastlane/AuthKey.p8 -pubout >/dev/null 2>&1 && echo "Valid" || echo "Invalid"

# Check curve type
openssl pkey -in fastlane/AuthKey.p8 -text -noout | grep "ASN1 OID"
# Should show: prime256v1 or secp256r1
```

### Verify Match Repository Access

```bash
# Test authentication with PAT
git ls-remote https://x-access-token:YOUR_TOKEN@github.com/user/ios-certificates.git

# Should list refs if successful
```

### Verify Team ID

```bash
# From certificate
security find-identity -v -p codesigning | grep "Apple Distribution"
# Shows: "Apple Distribution: Company Name (TEAM_ID)"

# Or visit developer.apple.com/account → Membership
```

---

## Common Secret Issues

### Issue: "Invalid Key Format"

**Causes**:
- Key not EC P-256 curve
- Corrupted during copy/paste
- Line breaks or spaces added

**Fixes**:
```bash
# Re-download P8 file from App Store Connect
# Copy entire file content including headers:
cat AuthKey_KEYID.p8

# Or base64 encode:
base64 -i AuthKey_KEYID.p8 | tr -d '\n'
```

### Issue: "Authentication Failed" (Match)

**Causes**:
- Invalid PAT
- PAT lacks `repo` scope
- PAT expired
- Repository doesn't exist

**Fixes**:
- Generate new PAT with `repo` scope
- Verify repository URL is correct
- Test: `git clone https://x-access-token:TOKEN@github.com/user/repo.git`

### Issue: "Match Password Incorrect"

**Causes**:
- Wrong password
- Special characters escaped incorrectly in CI
- Password changed without updating secret

**Fixes**:
- Verify password in password manager
- Update `MATCH_PASSWORD` secret
- Re-run `fastlane match` locally to confirm

### Issue: "Provisioning Profile Not Found"

**Causes**:
- Bundle ID mismatch
- Profile not in Match repository
- Profile expired

**Fixes**:
```bash
# Check bundle ID matches
grep -r "APP_IDENTIFIER" .

# Regenerate profiles
bundle exec fastlane match appstore --force

# Check Match repository
ls -R [path-to-cloned-match-repo]/profiles/
```

---

## Security Best Practices

### 1. Secret Storage
- ✅ Store secrets in GitHub Secrets or environment variables
- ✅ Use password managers for personal copies
- ❌ Never commit secrets to Git
- ❌ Never share secrets via Slack/email/unencrypted channels

### 2. Access Control
- ✅ Limit GitHub repository access to necessary team members
- ✅ Use branch protection rules
- ✅ Require 2FA for all team members
- ❌ Don't share personal Apple IDs

### 3. Rotation
- ✅ Rotate ASC keys annually
- ✅ Rotate PATs every 90 days
- ✅ Update Match password if compromised
- ✅ Revoke old certificates when creating new ones

### 4. Monitoring
- ✅ Enable notifications for failed builds
- ✅ Monitor App Store Connect for unauthorized changes
- ✅ Review Match repository access logs
- ✅ Audit team member access regularly

### 5. Backup
- ✅ Keep copy of P8 file in secure storage
- ✅ Document Match password in password manager
- ✅ Backup Match repository (encrypted)
- ✅ Document recovery procedures

---

## Quick Setup Script

For reference, here's a shell script to verify all required secrets are set:

```bash
#!/bin/bash

# Check GitHub Secrets (requires gh CLI)
echo "Checking GitHub Secrets..."

REQUIRED_SECRETS=(
  "APPLE_ID"
  "APPLE_TEAM_ID"
  "APP_IDENTIFIER"
  "ASC_KEY_ID"
  "ASC_ISSUER_ID"
  "ASC_KEY"
  "MATCH_GIT_URL"
  "MATCH_GIT_TOKEN"
  "MATCH_PASSWORD"
  "IOS_SCHEME"
)

for secret in "${REQUIRED_SECRETS[@]}"; do
  if gh secret list | grep -q "^$secret"; then
    echo "✅ $secret"
  else
    echo "❌ $secret (MISSING)"
  fi
done

echo ""
echo "To set a missing secret:"
echo "  gh secret set SECRET_NAME"
echo "  (then paste the value and press Ctrl-D)"
```

---

## Template for New Projects

When setting up a new project, use this template to track secrets:

```markdown
# Project: [APP_NAME]
# Date: [DATE]

## Apple Developer Info
- Apple ID: [EMAIL]
- Team ID: [TEAM_ID]
- Bundle ID: [BUNDLE_ID]

## App Store Connect API
- Key ID: [KEY_ID]
- Issuer ID: [ISSUER_ID]
- P8 File: ✅ Stored in [LOCATION]

## GitHub Secrets
- Repository: [GITHUB_REPO]
- All secrets configured: ✅ [DATE]
- PAT Expiration: [DATE]

## Match Repository
- URL: [MATCH_REPO_URL]
- Password: ✅ Stored in [PASSWORD_MANAGER]
- Last Updated: [DATE]

## Notes
- [Any special configuration or exceptions]
```

---

## Support

For issues or questions:
1. Check the [Pipeline Setup Guide](PIPELINE_SETUP_GUIDE.md)
2. Review [Troubleshooting](#troubleshooting) section
3. Verify secrets with validation commands above
4. Check workflow run logs in GitHub Actions

---

**Last Updated**: February 2026  
**Maintained By**: Development Team
