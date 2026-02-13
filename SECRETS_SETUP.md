# Secrets Setup Guide (DEPRECATED - Legacy Manual Signing)

> ⚠️ **DEPRECATED:** This guide documents the legacy manual signing approach and is kept for reference only.
> 
> **For new setups, use the modern XcodeGen + Fastlane Match pipeline instead:**
> - See [Transfers/QUICK_START_PIPELINE.md](Transfers/QUICK_START_PIPELINE.md) for quick setup
> - See [Transfers/PIPELINE_SETUP_GUIDE.md](Transfers/PIPELINE_SETUP_GUIDE.md) for complete guide
> - See [GITHUB_SECRETS_LIST.md](GITHUB_SECRETS_LIST.md) for required secrets
> 
> The new approach provides:
> - ✅ Automated code signing with Fastlane Match
> - ✅ Project generation with XcodeGen
> - ✅ Team-wide certificate sharing
> - ✅ No manual certificate/profile management

---

# Secrets Setup Guide for Pipeline Integration

This document provides detailed, step-by-step instructions for manually setting up all the secrets required for the GitHub Actions CI/CD pipeline in the PizzaChickenPop repository.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Overview of Required Secrets](#overview-of-required-secrets)
3. [Step-by-Step Setup Instructions](#step-by-step-setup-instructions)
   - [Part 1: Certificate and Provisioning Profile](#part-1-certificate-and-provisioning-profile)
   - [Part 2: Export Options](#part-2-export-options)
   - [Part 3: App Store Connect API Key (Optional)](#part-3-app-store-connect-api-key-optional)
   - [Part 4: Configure Secrets in GitHub](#part-4-configure-secrets-in-github)
4. [Validation](#validation)
5. [Troubleshooting](#troubleshooting)
6. [References](#references)

---

## Prerequisites

Before you begin, ensure you have:

- **Apple Developer Program Membership** ($99/year)
  - Required for creating distribution certificates and provisioning profiles
  - Sign up at: https://developer.apple.com/programs/

- **App Store Connect Access**
  - Required if you plan to upload to TestFlight
  - Access at: https://appstoreconnect.apple.com/

- **macOS Computer** (for initial setup)
  - Required to generate certificates and obtain provisioning profiles
  - Can use Xcode or terminal commands

- **GitHub Repository Admin Access**
  - Required to add secrets to the repository
  - You must have write access to the repository settings

- **Bundle ID Registered**
  - Your app's bundle identifier must be registered in Apple Developer Portal
  - Example: `com.yourcompany.PizzaChicken`

---

## Overview of Required Secrets

The pipeline requires the following GitHub Actions secrets:

### Required Secrets (for building and exporting IPA)

| Secret Name | Purpose | Format |
|------------|---------|--------|
| `IOS_P12_BASE64` | Distribution certificate with private key | Base64-encoded .p12 file |
| `IOS_P12_PASSWORD` | Password for the .p12 certificate | Plain text string |
| `IOS_MOBILEPROVISION_BASE64` | Provisioning profile for code signing | Base64-encoded .mobileprovision file |
| `IOS_KEYCHAIN_PASSWORD` | Password for temporary keychain on runner | Any secure random string |
| `IOS_EXPORT_OPTIONS_PLIST_BASE64` | Export configuration for IPA | Base64-encoded .plist file |

### Optional Secrets (for TestFlight upload)

| Secret Name | Purpose | Format |
|------------|---------|--------|
| `ASC_KEY_ID` | App Store Connect API Key ID | Plain text (e.g., `ABC123DEFG`) |
| `ASC_ISSUER_ID` | App Store Connect API Issuer ID | Plain text UUID |
| `ASC_KEY_P8_BASE64` | App Store Connect API private key | Base64-encoded .p8 file |

---

## Step-by-Step Setup Instructions

### Part 1: Certificate and Provisioning Profile

#### Step 1.1: Generate Distribution Certificate

**Option A: Using Xcode (Recommended for beginners)**

1. Open **Xcode**
2. Go to **Xcode** → **Preferences** (or **Settings** on newer Xcode versions)
3. Select the **Accounts** tab
4. Click the **+** button to add your Apple ID (if not already added)
5. Select your Apple ID and click **Manage Certificates...**
6. Click the **+** button and select **Apple Distribution**
7. Xcode will generate and install the certificate in your Keychain

**Option B: Using Apple Developer Portal**

1. Go to https://developer.apple.com/account/resources/certificates
2. Click the **+** button to create a new certificate
3. Select **Apple Distribution** under "Software"
4. Click **Continue**
5. Follow instructions to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** on your Mac
   - Go to **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
   - Enter your email address
   - Select **Saved to disk**
   - Click **Continue** and save the CSR file
6. Upload the CSR file to Apple Developer Portal
7. Download the certificate (.cer file)
8. Double-click the .cer file to install it in Keychain Access

#### Step 1.2: Export Certificate as .p12

1. Open **Keychain Access**
2. In the left sidebar, select **My Certificates**
3. Find your **Apple Distribution** certificate
   - It should show both the certificate and the private key (indicated by a triangle/disclosure icon)
   - **Important:** If you don't see the private key, the certificate was not created on this Mac, and you'll need to use the Mac where it was created
4. Right-click on the certificate and select **Export "Apple Distribution: [Your Name]"**
5. Choose a location to save it
6. Select file format: **Personal Information Exchange (.p12)**
7. Click **Save**
8. Enter a password when prompted (you'll need this later as `IOS_P12_PASSWORD`)
   - Use a strong password and save it securely
   - **IMPORTANT:** Remember this password - you'll need it as the `IOS_P12_PASSWORD` secret
9. You may need to enter your Mac login password to allow the export
10. Save the .p12 file securely (e.g., `distribution_cert.p12`)

#### Step 1.3: Create Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles
2. Click the **+** button to create a new profile
3. Select profile type based on your distribution method:
   - **App Store** - For TestFlight and App Store distribution (most common)
   - **Ad Hoc** - For installing on specific devices for testing
4. Click **Continue**
5. Select your **App ID** (bundle identifier) from the dropdown
6. Click **Continue**
7. Select the **Distribution Certificate** you created in Step 1.1
8. Click **Continue**
9. Enter a **Profile Name** (e.g., "PizzaChicken Distribution Profile")
10. Click **Generate**
11. Click **Download** to download the .mobileprovision file
12. Save it securely (e.g., `PizzaChicken.mobileprovision`)

#### Step 1.4: Generate Base64 Encoding for Certificate and Profile

On your Mac, open **Terminal** and run these commands:

```bash
# Convert .p12 certificate to base64
base64 -i /path/to/distribution_cert.p12 | pbcopy
```

This copies the base64 string to your clipboard. Save it somewhere temporarily - this will be your `IOS_P12_BASE64` secret.

```bash
# Convert .mobileprovision to base64
base64 -i /path/to/PizzaChicken.mobileprovision | pbcopy
```

This copies the base64 string to your clipboard. Save it somewhere temporarily - this will be your `IOS_MOBILEPROVISION_BASE64` secret.

#### Step 1.5: Generate Keychain Password

Create a strong random password for the keychain. You can generate one using:

```bash
# Generate a random password
openssl rand -base64 32
```

Save this password - this will be your `IOS_KEYCHAIN_PASSWORD` secret.

---

### Part 2: Export Options

The `ExportOptions.plist` file controls how Xcode exports your IPA.

#### Step 2.1: Create ExportOptions.plist

**Option A: Generate from a successful Xcode export (Recommended)**

1. Open your project in **Xcode**
2. Select **Product** → **Archive**
3. Once the archive completes, the **Organizer** window opens
4. Click **Distribute App**
5. Select your distribution method:
   - **App Store Connect** (for TestFlight/App Store)
   - **Ad Hoc** (for device testing)
6. Follow the prompts and complete the export
7. After export completes, navigate to the export folder
8. Find and copy the **ExportOptions.plist** file

**Option B: Create manually**

Create a file named `ExportOptions.plist` with the following content:

For **App Store** distribution:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.yourcompany.PizzaChicken</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

For **Ad Hoc** distribution:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.yourcompany.PizzaChicken</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

**Find your Team ID:**
- Go to https://developer.apple.com/account
- Click on **Membership** in the sidebar
- Your **Team ID** is displayed

**Find your Provisioning Profile Name:**
- This is the name you gave it in Step 1.3
- Or check in Apple Developer Portal: https://developer.apple.com/account/resources/profiles

**Replace:**
- `YOUR_TEAM_ID` with your actual Team ID
- `com.yourcompany.PizzaChicken` with your actual bundle identifier
- `YOUR_PROVISIONING_PROFILE_NAME` with the exact name of your provisioning profile

#### Step 2.2: Generate Base64 Encoding for ExportOptions.plist

```bash
# Convert ExportOptions.plist to base64
base64 -i /path/to/ExportOptions.plist | pbcopy
```

This copies the base64 string to your clipboard. Save it somewhere temporarily - this will be your `IOS_EXPORT_OPTIONS_PLIST_BASE64` secret.

---

### Part 3: App Store Connect API Key (Optional)

**Only required if you want to upload to TestFlight automatically.**

#### Step 3.1: Create App Store Connect API Key

1. Go to https://appstoreconnect.apple.com/access/api
2. Click the **+** button (or **Generate API Key** if it's your first)
3. Enter a **Name** (e.g., "GitHub Actions CI")
4. Select **Access**: Choose **App Manager** or **Developer**
   - **App Manager** - Can upload builds and manage TestFlight
   - **Developer** - Limited access
5. Click **Generate**
6. **IMPORTANT:** Download the API key file (.p8) immediately
   - **Apple only allows you to download this once**
   - If you lose it, you'll need to revoke and create a new key
   - Save it securely (e.g., `AuthKey_ABC123DEFG.p8`)

#### Step 3.2: Record the Key ID and Issuer ID

On the App Store Connect API Keys page, you'll see:
- **Key ID** (e.g., `ABC123DEFG`) - Copy this, it will be your `ASC_KEY_ID` secret
- **Issuer ID** (at the top of the page, a UUID) - Copy this, it will be your `ASC_ISSUER_ID` secret

#### Step 3.3: Generate Base64 Encoding for API Key

```bash
# Convert .p8 file to base64
base64 -i /path/to/AuthKey_ABC123DEFG.p8 | pbcopy
```

This copies the base64 string to your clipboard. Save it somewhere temporarily - this will be your `ASC_KEY_P8_BASE64` secret.

---

### Part 4: Configure Secrets in GitHub

Now that you have all the required values, add them to your GitHub repository.

#### Step 4.1: Navigate to Repository Secrets

1. Go to your GitHub repository: https://github.com/YOUR_USERNAME/PizzaChickenPop
2. Click on **Settings** (top menu)
3. In the left sidebar, expand **Secrets and variables**
4. Click **Actions**

#### Step 4.2: Add Required Secrets

Click **New repository secret** for each of the following:

**1. IOS_P12_BASE64**
- Name: `IOS_P12_BASE64`
- Value: Paste the base64-encoded string from Step 1.4 (certificate)
- Click **Add secret**

**2. IOS_P12_PASSWORD**
- Name: `IOS_P12_PASSWORD`
- Value: Paste the password you used when exporting the .p12 file in Step 1.2
- Click **Add secret**

**3. IOS_MOBILEPROVISION_BASE64**
- Name: `IOS_MOBILEPROVISION_BASE64`
- Value: Paste the base64-encoded string from Step 1.4 (provisioning profile)
- Click **Add secret**

**4. IOS_KEYCHAIN_PASSWORD**
- Name: `IOS_KEYCHAIN_PASSWORD`
- Value: Paste the random password from Step 1.5
- Click **Add secret**

**5. IOS_EXPORT_OPTIONS_PLIST_BASE64**
- Name: `IOS_EXPORT_OPTIONS_PLIST_BASE64`
- Value: Paste the base64-encoded string from Step 2.2
- Click **Add secret**

#### Step 4.3: Add Optional TestFlight Secrets (if applicable)

If you want to automatically upload to TestFlight, add these three secrets:

**6. ASC_KEY_ID**
- Name: `ASC_KEY_ID`
- Value: Paste the Key ID from Step 3.2
- Click **Add secret**

**7. ASC_ISSUER_ID**
- Name: `ASC_ISSUER_ID`
- Value: Paste the Issuer ID (UUID) from Step 3.2
- Click **Add secret**

**8. ASC_KEY_P8_BASE64**
- Name: `ASC_KEY_P8_BASE64`
- Value: Paste the base64-encoded string from Step 3.3
- Click **Add secret**

#### Step 4.4: Verify Secrets

After adding all secrets, you should see them listed on the Secrets page. You won't be able to view the values again, but you can update them if needed.

**Required secrets checklist:**
- ✅ IOS_P12_BASE64
- ✅ IOS_P12_PASSWORD
- ✅ IOS_MOBILEPROVISION_BASE64
- ✅ IOS_KEYCHAIN_PASSWORD
- ✅ IOS_EXPORT_OPTIONS_PLIST_BASE64

**Optional secrets checklist (for TestFlight):**
- ✅ ASC_KEY_ID
- ✅ ASC_ISSUER_ID
- ✅ ASC_KEY_P8_BASE64

---

## Validation

After adding all secrets, test your pipeline:

### Test the Build Pipeline

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select the **iOS Build (IPA)** workflow
4. Click **Run workflow** (on the right side)
5. Select the `main` branch
6. Click **Run workflow**

The workflow should:
1. ✅ Checkout code
2. ✅ Install certificate and provisioning profile
3. ✅ Build and archive the app
4. ✅ Export the IPA
5. ✅ Upload IPA as an artifact
6. ✅ (Optional) Upload to TestFlight

### Check for Errors

If the workflow fails:
1. Click on the failed workflow run
2. Click on the failed job
3. Expand the failed step to see the error message
4. See the [Troubleshooting](#troubleshooting) section below

### Download and Test the IPA

1. After a successful run, scroll down to **Artifacts**
2. Download `PizzaChicken-ipa`
3. Extract the .ipa file
4. Install it on a test device or upload to TestFlight manually to verify

---

## Troubleshooting

### Common Issues and Solutions

#### ❌ "Code signing failed" or "No matching provisioning profile found"

**Causes:**
- Bundle ID mismatch between Xcode project and provisioning profile
- Certificate doesn't match the provisioning profile
- Provisioning profile expired

**Solutions:**
1. Verify the bundle ID in your Xcode project matches the one in the provisioning profile
2. Ensure the certificate used to create the provisioning profile is the same one in the .p12 file
3. Check the provisioning profile expiration date in Apple Developer Portal
4. Regenerate the provisioning profile if needed and update the `IOS_MOBILEPROVISION_BASE64` secret

#### ❌ "Unable to decode base64"

**Causes:**
- Base64 string has extra characters (spaces, newlines)
- Base64 string is incomplete or corrupted

**Solutions:**
1. Regenerate the base64 string using the commands in this guide
2. Ensure you copy the entire string without truncation
3. Don't add quotes or extra whitespace when pasting into GitHub secrets

#### ❌ "Incorrect password for .p12 file"

**Causes:**
- Wrong password in `IOS_P12_PASSWORD` secret

**Solutions:**
1. Verify you're using the correct password from Step 1.2
2. Re-export the .p12 with a new password if you've forgotten it
3. Update both `IOS_P12_BASE64` and `IOS_P12_PASSWORD` secrets

#### ❌ "No identity found in keychain"

**Causes:**
- .p12 file doesn't contain both certificate and private key
- Certificate import failed

**Solutions:**
1. When exporting from Keychain Access, ensure you select the certificate (not just the key)
2. Verify the .p12 file contains both by importing it locally into a test keychain
3. Re-export following Step 1.2 carefully

#### ❌ "Export failed" or "IPA not created"

**Causes:**
- `ExportOptions.plist` doesn't match the provisioning profile method
- Wrong team ID or provisioning profile name in ExportOptions.plist

**Solutions:**
1. Verify the `method` in ExportOptions.plist matches your profile type:
   - Use `app-store` for App Store Distribution profiles
   - Use `ad-hoc` for Ad Hoc profiles
2. Verify team ID and provisioning profile name are correct
3. Try generating ExportOptions.plist from a successful Xcode export (Option A in Step 2.1)

#### ❌ "TestFlight upload failed" with API key errors

**Causes:**
- Wrong Key ID, Issuer ID, or API key
- Insufficient API key permissions
- API key has been revoked

**Solutions:**
1. Verify `ASC_KEY_ID` and `ASC_ISSUER_ID` match what's shown in App Store Connect
2. Ensure the API key has **App Manager** or **Developer** access
3. Check if the API key is still active in App Store Connect
4. If the key was revoked, generate a new one and update all three secrets

#### ❌ "Provisioning profile expired"

**Causes:**
- Provisioning profile has exceeded its expiration date

**Solutions:**
1. Go to https://developer.apple.com/account/resources/profiles
2. Find your profile and check the expiration date
3. Click **Edit** and regenerate the profile
4. Download the new profile and update `IOS_MOBILEPROVISION_BASE64` secret

### Still Having Issues?

1. **Check the workflow logs carefully** - The error messages usually indicate what's wrong
2. **Verify all secrets are set** - Missing secrets will cause failures
3. **Test locally first** - Try building and exporting from Xcode on your Mac to ensure certificates and profiles work
4. **Check Apple Developer Portal** - Ensure certificates and profiles are valid and not expired
5. **Review GitHub Actions documentation** - https://docs.github.com/actions

---

## Security Best Practices

- **Never commit** certificates, private keys, or passwords to your repository
- **Rotate secrets regularly** - Update certificates and API keys periodically
- **Use strong passwords** - For .p12 export and keychain passwords
- **Limit API key access** - Give the minimum required permissions
- **Revoke old keys** - If you create new API keys, revoke the old ones
- **Back up your .p12 and .p8 files** - Store them securely offline
- **Don't share secrets** - Each team member should use their own certificates/keys when possible

---

## References

### Apple Documentation
- [Apple Developer Account](https://developer.apple.com/account)
- [Creating Distribution Certificates](https://developer.apple.com/help/account/create-certificates/create-distribution-certificates)
- [Creating Provisioning Profiles](https://developer.apple.com/help/account/manage-profiles/create-a-development-provisioning-profile)
- [App Store Connect API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)
- [Export Options Plist](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)

### GitHub Documentation
- [Installing Apple Certificate on macOS Runners](https://docs.github.com/actions/use-cases-and-examples/deploying/installing-an-apple-certificate-on-macos-runners-for-xcode-development)
- [Encrypted Secrets](https://docs.github.com/actions/security-guides/encrypted-secrets)
- [GitHub Actions for Xcode](https://github.com/features/actions)

### Fastlane Documentation
- [App Store Connect API](https://docs.fastlane.tools/app-store-connect-api/)
- [upload_to_testflight](https://docs.fastlane.tools/actions/upload_to_testflight/)
- [Fastlane Codesigning Guide](https://docs.fastlane.tools/codesigning/getting-started/)

### Tools
- [setup-xcode GitHub Action](https://github.com/marketplace/actions/setup-xcode-version)
- [Base64 Online Encoder/Decoder](https://www.base64encode.org/) (use local commands instead for security)

---

## Appendix: Quick Reference Commands

```bash
# Export certificate to .p12 (do this in Keychain Access GUI)

# Generate base64 for secrets
base64 -i path/to/file.p12 | pbcopy
base64 -i path/to/file.mobileprovision | pbcopy
base64 -i path/to/ExportOptions.plist | pbcopy
base64 -i path/to/AuthKey_XXXXX.p8 | pbcopy

# Generate random password
openssl rand -base64 32

# Verify a .p12 file (optional)
openssl pkcs12 -in path/to/file.p12 -nodes -passin pass:YOUR_PASSWORD | openssl x509 -noout -subject

# Check provisioning profile details (optional)
security cms -D -i path/to/file.mobileprovision
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-12  
**Maintained By:** Repository maintainers

For questions or issues with this setup guide, please open an issue in the GitHub repository.
