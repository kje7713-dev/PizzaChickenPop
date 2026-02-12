# GitHub Secrets Required

## Required Secrets (for building and exporting IPA)

| Secret Name | Purpose | Format |
|------------|---------|--------|
| `IOS_P12_BASE64` | Distribution certificate with private key | Base64-encoded .p12 file |
| `IOS_P12_PASSWORD` | Password for the .p12 certificate | Plain text string |
| `IOS_MOBILEPROVISION_BASE64` | Provisioning profile for code signing | Base64-encoded .mobileprovision file |
| `IOS_KEYCHAIN_PASSWORD` | Password for temporary keychain on runner | Any secure random string |
| `IOS_EXPORT_OPTIONS_PLIST_BASE64` | Export configuration for IPA | Base64-encoded .plist file |

## Optional Secrets (for TestFlight upload)

| Secret Name | Purpose | Format |
|------------|---------|--------|
| `ASC_KEY_ID` | App Store Connect API Key ID | Plain text (e.g., `ABC123DEFG`) |
| `ASC_ISSUER_ID` | App Store Connect API Issuer ID | Plain text UUID |
| `ASC_KEY_P8_BASE64` | App Store Connect API private key | Base64-encoded .p8 file |

---

**Note:** For detailed setup instructions, see [SECRETS_SETUP.md](SECRETS_SETUP.md)
