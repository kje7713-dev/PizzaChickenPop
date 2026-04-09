# App Review Response — Remove Ads IAP

## Summary

Thank you for reviewing Pizza Chicken Pop. We have addressed the reported issue with the **Remove Ads** in-app purchase and resubmitted the app.

---

## What Was Fixed

### 1. Product type corrected to Non-Consumable

The Remove Ads purchase has been configured in App Store Connect as a **Non-Consumable** product with product ID:

```
com.sbd.pizzachicken.removeads
```

This ensures the purchase is a permanent, one-time unlock that can be freely restored across devices.

### 2. Purchase flow now provides visible feedback

Previously, tapping **REMOVE ADS** would initiate a purchase silently, making the button appear unresponsive during the App Store connection phase. This has been fixed:

- **While connecting:** The button immediately changes to "PROCESSING…" (dimmed) and a status label reads "Connecting to App Store…"
- **On success:** The status label shows "Ads removed. Thank you!" and the IAP controls are hidden on the next game-over screen.
- **On failure / product not found:** The status label shows "Purchase unavailable. Please try again." in red.
- **On user cancellation:** The UI returns to idle immediately.

### 3. Restore Purchases also shows visible feedback

- **While restoring:** Status label shows "Restoring purchases…"
- **On success:** Status label shows "Purchases restored."
- **On failure / nothing to restore:** Status label shows the appropriate error message.

### 4. Duplicate-tap guard

While a purchase or restore is in progress, additional taps on the **REMOVE ADS** and **Restore Purchases** buttons are ignored, preventing duplicate transactions.

---

## Testing Instructions for App Review

1. Launch the app and play until Game Over.
2. Tap **REMOVE ADS** — the button should immediately change to "PROCESSING…" with a status message visible below.
3. Complete the sandbox purchase — status label updates to "Ads removed. Thank you!"
4. Force-quit and relaunch — ads remain removed (entitlement is persisted via StoreKit and UserDefaults).
5. On a fresh install or second device (same Apple ID), tap **Restore Purchases** — status updates to "Restoring purchases…" then "Purchases restored."

The app is ready for re-review. Please let us know if you have any further questions.
