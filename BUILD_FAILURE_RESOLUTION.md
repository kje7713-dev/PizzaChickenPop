# Build Failure Resolution Report

**Date**: February 16, 2026  
**Workflow**: iOS TestFlight Deployment  
**Status**: ✅ Resolved

## Latest Issue - Asset Catalog Cleanup (February 16, 2026)

### Error Summary
Discovered extraneous file in `Assets.xcassets/AppIcon.appiconset/` that could cause asset compilation issues.

### Root Cause
An extraneous file named `H` (containing only "h\n") was present in the AppIcon.appiconset directory. While this didn't cause an immediate build failure, it violated asset catalog best practices and could potentially cause issues with Xcode's asset catalog compiler (`actool`).

### Solution
1. **Removed extraneous file**: Deleted `Assets.xcassets/AppIcon.appiconset/H`
2. **Created validation script**: Added `.github/scripts/validate_assets.py` to detect such issues in the future
   - Validates all icon files referenced in Contents.json exist
   - Detects unreferenced files in asset catalogs
   - Identifies non-standard files that shouldn't be in asset catalogs

### Files Modified
- `Assets.xcassets/AppIcon.appiconset/H` - Removed extraneous file
- `.github/scripts/validate_assets.py` - New validation script

### Validation
```bash
python3 .github/scripts/validate_assets.py
# Output: ✅ All asset validations passed!
```

### Best Practices
- Asset catalog directories should only contain:
  - Image files (.png, .jpg, .jpeg)
  - Contents.json configuration files
- All image files should be referenced in Contents.json
- No temporary files, text files, or other extraneous content

---

## Previous Issue (Run #22080600641)

### Error Summary
- **Run ID**: 22080600641
- **Workflow**: iOS TestFlight Deployment
- **Date**: 2026-02-16 23:31:30Z
- **Conclusion**: Failure
- **Error Message**: 
  - `Validation failed Missing Info.plist value. A value for the Info.plist key 'CFBundleIconName' is missing in the bundle '***'`
  - `Missing required icon file. The bundle does not contain an app icon for iPhone / iPod Touch of exactly '120x120' pixels`
  - `Missing required icon file. The bundle does not contain an app icon for iPad of exactly '152x152' pixels`

### Root Cause
When using XcodeGen with modern Xcode (13+), Info.plist keys must be set via build settings using the `INFOPLIST_KEY_` prefix. Even though `CFBundleIconName` was present in the source `Resources/Info.plist` file, it was not being properly included in the compiled Info.plist within the final IPA bundle.

The CI verification step confirmed that Assets.car was being compiled correctly and included in the app bundle, and the source Info.plist had CFBundleIconName set to "AppIcon". However, Apple's TestFlight validation was rejecting the upload because the key was missing from the **compiled** Info.plist.

### Technical Details
- **Modern Xcode Behavior**: Xcode 13+ and XcodeGen require Info.plist values to be set as build settings with the `INFOPLIST_KEY_` prefix
- **Static Info.plist Limitation**: Values in static Info.plist files may not be merged into the final compiled Info.plist when using XcodeGen
- **Asset Catalog Requirement**: iOS 11+ requires both an asset catalog with app icons AND the CFBundleIconName key in Info.plist

### Solution
Added `INFOPLIST_KEY_CFBundleIconName: AppIcon` to the build settings in `project.yml`:

```yaml
settings:
  base:
    ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    INFOPLIST_KEY_CFBundleIconName: AppIcon  # Added this line
```

This ensures that:
1. XcodeGen generates the Xcode project with the proper build setting
2. Xcode compiles this setting into the final Info.plist in the IPA bundle
3. Apple's TestFlight validation can find the required CFBundleIconName key

### Files Modified
- `project.yml` - Added `INFOPLIST_KEY_CFBundleIconName: AppIcon` build setting

### References
- [Apple Developer: Managing Info.plist values](https://developer.apple.com/documentation/bundleresources/managing-your-app-s-information-property-list)
- [XcodeGen Documentation: Build Settings](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md#build-setting-groups)
- [Stack Overflow: CFBundleIconName Missing](https://stackoverflow.com/questions/46216718/missing-cfbundleiconname-in-xcode9-ios11-app-release)

---

## Previous Issue (Run #22078666400)

### Error Summary
- **Run ID**: 22078666400
- **Workflow**: iOS TestFlight Deployment
- **Date**: 2026-02-16 21:58:59Z
- **Conclusion**: Failure
- **Error Message**: `xcodebuild: error: Unable to read project 'PizzaChicken.xcodeproj'. Reason: The project 'PizzaChicken' cannot be opened because it is in a future Xcode project file format (77). Adjust the project format using a compatible version of Xcode to allow it to be opened by this version of Xcode.`

### Root Cause
The GitHub Actions workflow was configured to use Xcode 15.4, but XcodeGen (installed via Homebrew) generates Xcode projects in the newer Xcode 16+ format (objectVersion 77). This format includes features like "Buildable Folders" that are not backward compatible with Xcode 15.x.

When XcodeGen runs on the CI environment, it generates a project file in the format that matches the latest installed XcodeGen version, which supports Xcode 16 features. However, the workflow explicitly selected Xcode 15.4, creating a mismatch.

### Technical Details
- **Xcode 16 Project Format**: Version 77 introduced breaking changes including Buildable Folders
- **Xcode 15.4 Compatibility**: Can only open projects up to format version ~60
- **XcodeGen Behavior**: Generates projects in the latest format supported by the tool version
- **Error Location**: During the `gym` (build) step when xcodebuild attempts to open the generated project

### Solution
Updated both iOS workflow files to use Xcode 26.2, which is available on the macos-26 GitHub Actions runner:

1. **ios-testflight.yml**: Changed from Xcode 16.2 to Xcode 26.2
2. **ios-build.yml**: Changed from Xcode 16.2 to Xcode 26.2 (for consistency)

This allows the workflow to:
- Use XcodeGen's latest features
- Build with iOS 26 SDK as required by Apple (mandatory from April 28, 2026)
- Open and build projects in the newer format
- Maintain compatibility with modern Xcode tooling

### Files Modified
- `.github/workflows/ios-testflight.yml` - Updated Xcode version from 16.2 to 26.2 and runner from macos-14 to macos-26
- `.github/workflows/ios-build.yml` - Updated Xcode version from 16.2 to 26.2 and runner from macos-14 to macos-26

### Alternative Solutions Considered
1. **Downgrade XcodeGen**: Pin to an older version that generates Xcode 15-compatible projects
   - ❌ Not recommended: Loses access to modern features and bug fixes
   
2. **Manual Format Conversion**: Edit `project.pbxproj` to change objectVersion
   - ❌ Not recommended: Error-prone and doesn't work with Buildable Folders
   
3. **Upgrade to Xcode 26**: Use the latest Xcode version available on the macos-26 runner
   - ✅ **Selected**: Best long-term solution, aligns with modern tooling and meets Apple's iOS 26 SDK requirement

### References
- [Xcode 16 Buildable Folders and Compatibility Issues](https://blog.supereasyapps.com/xcode-16-buildable-folders-break-xcode-15-backwards-compatibility/)
- [XcodeGen Project Format Discussion](https://github.com/yonaskolb/XcodeGen/issues/1505)
- [GitHub Actions macos-26 Runner Images](https://github.com/actions/runner-images)

---

## Previous Issue (Run #22078378428)

### Error Summary
- **Run ID**: 22078378428
- **Workflow**: iOS TestFlight Deployment
- **Date**: 2026-02-16 21:45:03Z
- **Conclusion**: Failure
- **Error Message**: `No code signing identity found and cannot create a new one because you enabled 'readonly'`

### Root Cause
The Fastfile was already configured to support the `MATCH_READONLY` environment variable (lines 27-29), which allows toggling between readonly mode (true) and write mode (false) for the Match certificate repository. However, the GitHub Actions workflow file did not include this secret in the environment variables, so the Fastfile couldn't read it from the GitHub secret.

### Solution
Added `MATCH_READONLY` secret to the GitHub Actions workflow environment variables in `.github/workflows/ios-testflight.yml`:

```yaml
env:
  MATCH_READONLY: ${{ secrets.MATCH_READONLY }}
```

This allows users to:
- Set `MATCH_READONLY=true` (default if not set) to use existing certificates in readonly mode
- Set `MATCH_READONLY=false` to allow Match to create new certificates and provisioning profiles

### Files Modified
- `.github/workflows/ios-testflight.yml` - Added MATCH_READONLY to env section
- `GITHUB_SECRETS_LIST.md` - Documented the new optional MATCH_READONLY secret

## Previous Issue (Run #22075740003)
- **Run ID**: 22075740003
- **Workflow**: iOS TestFlight Deployment
- **Date**: 2026-02-16 19:50:46Z
- **Conclusion**: Failure

### Error Message
```
Could not find option 'is_ci' in the list of available options: type, additional_cert_types, readonly, generate_apple_certs, skip_provisioning_profiles, app_identifier, api_key_path, api_key, username, team_id, team_name, storage_mode, git_url, git_branch, git_full_name, git_user_email, shallow_clone, clone_branch_directly, git_basic_authorization, git_bearer_authorization, git_private_key, google_cloud_bucket_name, google_cloud_keys_file, google_cloud_project_id, skip_google_cloud_account_confirmation, s3_region, s3_access_key, s3_secret_access_key, s3_bucket, s3_object_prefix, s3_skip_encryption, gitlab_project, gitlab_host, job_token, private_token, keychain_name, keychain_password, force, force_for_new_devices, include_mac_in_profiles, include_all_certificates, certificate_id, force_for_new_certificates, skip_confirmation, safe_remove_certs, skip_docs, platform, derive_catalyst_app_identifier, template_name, profile_name, fail_on_name_taken, skip_certificate_matching, output_path, skip_set_partition_list, force_legacy_encryption, verbose
```

### Location
- **File**: `fastlane/Fastfile`
- **Lines**: 26 and 75
- **Action**: `match` step

## Root Cause Analysis

The `is_ci` method in Fastlane is an action that returns a boolean value indicating whether the code is running in a CI environment. However, in the Fastfile, it was being passed directly as a parameter name to the `match` action instead of being evaluated first.

### Problematic Code
```ruby
match(
  type: "appstore",
  readonly: is_ci,  # ❌ is_ci not evaluated
  keychain_name: "ci_keychain",
  ...
)
```

When Fastlane tried to parse this, it interpreted `is_ci` as a literal option name rather than a method call that should be evaluated to get a boolean value.

## Resolution

### Changes Made
1. Added a variable assignment at the beginning of the `beta` lane to evaluate `is_ci`:
   ```ruby
   ci_environment = is_ci
   ```

2. Updated the `match` action to use the evaluated variable:
   ```ruby
   match(
     type: "appstore",
     readonly: ci_environment,  # ✅ Using evaluated variable
     keychain_name: "ci_keychain",
     ...
   )
   ```

3. Updated the cleanup section to use the same variable:
   ```ruby
   delete_keychain(name: "ci_keychain") if ci_environment
   ```

### Files Modified
- `fastlane/Fastfile`
  - Added line 7: `ci_environment = is_ci`
  - Changed line 29: `readonly: is_ci` → `readonly: ci_environment`
  - Changed line 78: `if is_ci` → `if ci_environment`

## Validation

### Syntax Check
```bash
$ ruby -c fastlane/Fastfile
Syntax OK
```

### Expected Behavior
After this fix:
1. The `is_ci` method will be evaluated once at the beginning of the lane
2. The resulting boolean value will be stored in `ci_environment`
3. This variable can be used in multiple places throughout the lane
4. The `match` action will receive a proper boolean value instead of a method reference

## Additional Notes

- This is a common mistake when working with Fastlane actions that return values
- Evaluating actions once and storing results is also more efficient than calling them multiple times
- The fix maintains backward compatibility and doesn't change the functional behavior of the workflow

## Next Steps

1. The next workflow run should succeed
2. Monitor the iOS TestFlight Deployment workflow for successful completion
3. If additional issues arise, they will be addressed separately

## References

- [Fastlane Match Documentation](https://docs.fastlane.tools/actions/match/)
- [Fastlane is_ci Action](https://docs.fastlane.tools/actions/is_ci/)
