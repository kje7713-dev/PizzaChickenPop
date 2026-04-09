# IAP Non-Consumable Notes — Remove Ads

## App Store Connect Product Configuration

| Field | Value |
|-------|-------|
| **Product type** | **Non-Consumable** |
| **Product ID** | `com.sbd.pizzachicken.removeads` |
| **Reference name** | Remove Ads |

> ⚠️ The old consumable product (if one exists in App Store Connect) **must not** be referenced by the app.  
> Only `com.sbd.pizzachicken.removeads` (Non-Consumable) is used.

---

## Why Non-Consumable?

A "Remove Ads" purchase should be a **one-time, permanent unlock**. Non-consumable products:
- Can be restored by the user at no charge via **Restore Purchases**.
- Are automatically made available across all devices for the same Apple ID.
- Do not expire.

Consumable products cannot be restored and are inappropriate for permanent content unlocks.

---

## Code Reference

- Product ID is defined in `Sources/Services/IAPManager.swift`:
  ```swift
  private let productID = "com.sbd.pizzachicken.removeads"
  ```
- Purchase status is observed in `Sources/Game/GameScene.swift` via `.iapPurchaseStatusDidChange`.
- UI feedback is rendered by `Sources/UI/GameOverOverlay.swift` via `updatePurchaseStatus(_:)`.

---

## Sandbox Verification Checklist

Before submitting for App Review, verify the following in the iOS Simulator / TestFlight sandbox:

- [ ] **Product loads:** Tap "REMOVE ADS" → button shows "PROCESSING…" and the status label shows "Connecting to App Store…"
- [ ] **Product lookup failure is visible:** Disable network → tap "REMOVE ADS" → status label shows "Purchase unavailable. Please try again."
- [ ] **Successful purchase:** Complete sandbox purchase → status label shows "Ads removed. Thank you!" → overlay hides IAP buttons on next game-over screen
- [ ] **Restore Purchases:** On a second device (same sandbox Apple ID), tap "Restore Purchases" → status label shows "Restoring purchases…" then "Purchases restored." → ads removed
- [ ] **No duplicate taps:** While "PROCESSING…" is shown, tapping REMOVE ADS or Restore Purchases does nothing (guarded in GameScene.swift)
- [ ] **Entitlement survives relaunch:** Force-quit and relaunch the app → ads remain removed (backed by UserDefaults cache + StoreKit entitlement refresh)

---

## Reminder for Release Ops

- Do **not** re-add a consumable product with this ID or a similar name.
- If the product needs a price change, update it in App Store Connect; the product ID must remain `com.sbd.pizzachicken.removeads`.
- App Review testers must have an active sandbox Apple ID to test the purchase flow.
