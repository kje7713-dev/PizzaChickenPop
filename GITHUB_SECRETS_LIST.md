# GitHub Secrets Required

This document lists all GitHub Actions secrets required for the CI/CD pipeline using XcodeGen and Fastlane Match.

## Required Secrets (Match-based Pipeline)

| Secret Name | Purpose | Format | Where to Get It |
|------------|---------|--------|-----------------|
| `APPLE_ID` | Apple Developer account email | Plain text email | Your Apple ID |
| `APPLE_TEAM_ID` | Apple Developer Team ID | 10-character alphanumeric | [developer.apple.com/account](https://developer.apple.com/account) → Membership |
| `APP_IDENTIFIER` | App bundle identifier | Reverse domain notation | `com.kje7713.PizzaChicken` |
| `ASC_KEY_ID` | App Store Connect API Key ID | 10-character alphanumeric | App Store Connect → Users and Access → Keys |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID | UUID format | App Store Connect → Users and Access → Keys |
| `ASC_KEY` | App Store Connect API private key | Raw PEM or base64 | Download .p8 file from App Store Connect |
| `MATCH_GIT_URL` | Git repository URL for certificates | HTTPS URL | Your private certificates repo URL |
| `MATCH_GIT_TOKEN` | GitHub Personal Access Token | `ghp_` prefixed token | GitHub Settings → Developer settings → Tokens |
| `MATCH_PASSWORD` | Encryption password for Match | Any secure password | Create and store securely |
| `IOS_SCHEME` | Xcode scheme name | Plain text | `PizzaChicken` |

## Secret Value Examples

### APPLE_ID
```
developer@example.com
```

### APPLE_TEAM_ID
```
3W77JDM5X2
```
*(10 alphanumeric characters)*

### APP_IDENTIFIER
```
com.kje7713.PizzaChicken
```

### ASC_KEY_ID
```
ABCD123456
```

### ASC_ISSUER_ID
```
12345678-1234-1234-1234-123456789012
```

### ASC_KEY
**Option 1: Raw PEM format (recommended)**
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----
```

**Option 2: Base64-encoded**
```
LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J5cUdTTTQ5QWdFR0ND...
```

### MATCH_GIT_URL
```
https://github.com/username/ios-certificates
```
*(Must be a private repository)*

### MATCH_GIT_TOKEN
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
*(Generate with `repo` scope)*

### MATCH_PASSWORD
```
YourSecurePassword123!
```
*(Any strong password - store in password manager)*

### IOS_SCHEME
```
PizzaChicken
```

---

## Migration from Manual Signing

If you're migrating from the old manual signing approach, these secrets are **no longer needed**:
- ❌ `IOS_P12_BASE64` - Replaced by Match
- ❌ `IOS_P12_PASSWORD` - Replaced by Match
- ❌ `IOS_MOBILEPROVISION_BASE64` - Replaced by Match
- ❌ `IOS_KEYCHAIN_PASSWORD` - Replaced by `MATCH_PASSWORD`
- ❌ `IOS_EXPORT_OPTIONS_PLIST_BASE64` - Generated automatically
- ❌ `ASC_KEY_P8_BASE64` - Replaced by `ASC_KEY`
- ❌ `IPA_PATH` - No longer needed

---

## Setup Instructions

For detailed setup instructions, see:
- **[Transfers/QUICK_START_PIPELINE.md](Transfers/QUICK_START_PIPELINE.md)** - Fast setup guide
- **[Transfers/PIPELINE_SETUP_GUIDE.md](Transfers/PIPELINE_SETUP_GUIDE.md)** - Complete setup guide
- **[Transfers/SECRETS_REFERENCE.md](Transfers/SECRETS_REFERENCE.md)** - Comprehensive secrets reference

---

## How to Set Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter the secret name and value
5. Click **Add secret**

Repeat for all required secrets above.

---

## Verification

To verify all secrets are set, you can use the GitHub CLI:

```bash
gh secret list
```

You should see all 10 required secrets listed.

---

**Note:** For detailed setup instructions and troubleshooting, see the comprehensive documentation in the [Transfers](Transfers/) folder.

