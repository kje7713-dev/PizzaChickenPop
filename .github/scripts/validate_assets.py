#!/usr/bin/env python3
"""
Asset Catalog Validation Script
Validates that the Assets.xcassets directory contains only valid files
and that all icon references in Contents.json are correct.
"""

import json
import os
import sys
from pathlib import Path

def validate_appiconset(appiconset_path):
    """Validate AppIcon.appiconset directory"""
    errors = []
    warnings = []
    
    # Check if Contents.json exists
    contents_json_path = appiconset_path / 'Contents.json'
    if not contents_json_path.exists():
        errors.append(f"Missing Contents.json in {appiconset_path}")
        return errors, warnings
    
    # Read Contents.json
    try:
        with open(contents_json_path, 'r') as f:
            contents = json.load(f)
    except json.JSONDecodeError as e:
        errors.append(f"Invalid JSON in {contents_json_path}: {e}")
        return errors, warnings
    
    # Get all referenced filenames
    referenced_files = set()
    for image in contents.get('images', []):
        if 'filename' in image:
            referenced_files.add(image['filename'])
    
    # Get all actual files in directory
    actual_files = set()
    for item in appiconset_path.iterdir():
        if item.is_file() and item.name != 'Contents.json':
            actual_files.add(item.name)
    
    # Check for unreferenced files
    unreferenced = actual_files - referenced_files
    if unreferenced:
        for f in unreferenced:
            # Check if it's an image file
            if f.lower().endswith(('.png', '.jpg', '.jpeg')):
                warnings.append(f"Image file {f} in {appiconset_path.name} is not referenced in Contents.json")
            else:
                errors.append(f"Extraneous file {f} in {appiconset_path.name} (not an icon or Contents.json)")
    
    # Check for missing files
    missing = referenced_files - actual_files
    if missing:
        for f in missing:
            errors.append(f"Missing file {f} referenced in {appiconset_path.name}/Contents.json")
    
    # Validate that all referenced files are PNGs
    for f in referenced_files:
        if not f.lower().endswith('.png'):
            warnings.append(f"Non-PNG icon file {f} in {appiconset_path.name} (Apple recommends PNG)")
    
    return errors, warnings

def validate_assets_xcassets(assets_path):
    """Validate the entire Assets.xcassets directory"""
    all_errors = []
    all_warnings = []
    
    if not assets_path.exists():
        all_errors.append(f"Assets.xcassets directory not found at {assets_path}")
        return all_errors, all_warnings
    
    # Find all .appiconset directories
    appiconset_dirs = list(assets_path.glob('**/*.appiconset'))
    
    if not appiconset_dirs:
        all_warnings.append("No .appiconset directories found in Assets.xcassets")
    
    for appiconset_dir in appiconset_dirs:
        errors, warnings = validate_appiconset(appiconset_dir)
        all_errors.extend(errors)
        all_warnings.extend(warnings)
    
    return all_errors, all_warnings

def main():
    # Determine project root (script is in .github/scripts/)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent
    assets_path = project_root / 'Assets.xcassets'
    
    print(f"Validating assets at: {assets_path}")
    print("-" * 60)
    
    errors, warnings = validate_assets_xcassets(assets_path)
    
    # Print warnings
    if warnings:
        print("\n⚠️  WARNINGS:")
        for warning in warnings:
            print(f"  - {warning}")
    
    # Print errors
    if errors:
        print("\n❌ ERRORS:")
        for error in errors:
            print(f"  - {error}")
        print("\n" + "=" * 60)
        print("Asset validation FAILED")
        sys.exit(1)
    
    if not warnings and not errors:
        print("✅ All asset validations passed!")
    else:
        print("\n" + "=" * 60)
        print("✅ Asset validation passed (with warnings)")
    
    sys.exit(0)

if __name__ == '__main__':
    main()
