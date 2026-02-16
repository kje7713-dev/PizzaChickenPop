# Scripts Directory

This directory contains utility scripts for validating and maintaining the PizzaChicken iOS project.

## Available Scripts

### validate_assets.py

**Purpose**: Validates the integrity of the Assets.xcassets directory and ensures all icon files are properly configured.

**Usage**:
```bash
python3 .github/scripts/validate_assets.py
```

**What it checks**:
- All icon files referenced in Contents.json exist
- No extraneous files in .appiconset directories
- All referenced files are in PNG format (Apple's recommended format)
- Contents.json files are valid JSON

**Exit codes**:
- `0`: Validation passed (with or without warnings)
- `1`: Validation failed with errors

**Example output** (success):
```
Validating assets at: /path/to/Assets.xcassets
------------------------------------------------------------
✅ All asset validations passed!
```

**Example output** (with errors):
```
Validating assets at: /path/to/Assets.xcassets
------------------------------------------------------------
❌ ERRORS:
  - Extraneous file H in AppIcon.appiconset (not an icon or Contents.json)
  - Missing file icon_120x120.png referenced in AppIcon.appiconset/Contents.json
============================================================
Asset validation FAILED
```

## Maintenance

### Adding New Validation Scripts

When adding new scripts to this directory:
1. Make the script executable: `chmod +x .github/scripts/your_script.py`
2. Add proper documentation to this README
3. Include clear error messages and exit codes
4. Consider integrating into CI/CD workflows if appropriate
