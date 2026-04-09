# App Review QA Checklist

Use this checklist before submitting to App Review to confirm the IAP / Remove Ads flow is working correctly.

---

## Pre-Submission Setup

- [ ] **Paid Apps Agreement is active** in App Store Connect under Agreements, Tax, and Banking.
- [ ] **IAP product ID in App Store Connect matches code exactly:** `com.sbd.pizzachicken.removeads`
- [ ] IAP product status is **Ready to Submit** (not "Missing Metadata" or "Waiting for Review").

---

## Sandbox Purchase Flow (iPad)

- [ ] Signed in with a **Sandbox Apple ID** (Settings → App Store → Sandbox Account).
- [ ] Launch app on iPad and play until Game Over so the overlay appears.
- [ ] Tap **REMOVE ADS - $0.99**:
  - [ ] Button text immediately changes to **PROCESSING…** and dims.
  - [ ] Status label shows **"Connecting to App Store…"**
  - [ ] Sandbox purchase sheet appears within a few seconds.
  - [ ] Confirm purchase in the sandbox sheet.
  - [ ] Status label shows **"Ads removed. Thank you!"**
  - [ ] REMOVE ADS and Restore Purchases buttons disappear from overlay.
  - [ ] Ads no longer shown on subsequent game-over screens.

## Missing Product / Paid Apps Agreement Inactive

- [ ] Temporarily disable the Paid Apps Agreement (or use a product ID that does not exist in a test build).
- [ ] Tap **REMOVE ADS**:
  - [ ] Status label shows **"Purchase unavailable. Please try again."**
  - [ ] Button returns to normal (not stuck in PROCESSING…).

## Loading State / Rapid Tap Guard

- [ ] While **PROCESSING…** is displayed, tap REMOVE ADS or Restore Purchases multiple times.
  - [ ] No duplicate purchase sheets appear.
  - [ ] App does not crash or enter a broken state.

## Restore Purchases Flow

- [ ] After a successful sandbox purchase (above), delete and reinstall the app.
- [ ] Play until Game Over so the overlay appears.
- [ ] Tap **Restore Purchases**:
  - [ ] Button dims and status label shows **"Restoring purchases…"**
  - [ ] On success, status label shows **"Purchases restored."**
  - [ ] REMOVE ADS and Restore Purchases buttons disappear.
- [ ] On a device/account with no prior purchase, tap Restore Purchases:
  - [ ] Status label shows **"No purchases found to restore."**

## Overlay / Game Flow Integrity

- [ ] After a purchase or restore, tapping **Tap to Restart** starts a new game correctly.
- [ ] Level Complete overlay still appears and advances to the next level on tap.
- [ ] No crashes observed while the overlay is open during or after a purchase attempt.
- [ ] Ads button does **not** reappear after entitlement refresh confirms removal.

---

*All items should be checked before each App Store submission.*
