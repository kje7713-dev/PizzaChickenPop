# App Review Response — Submission ID e447754c-1fe7-4668-b78c-c52ded59d33a

---

## Guideline 2.1 — Third-Party SDKs / Data Handling

Thank you for your review. Please find our responses to the information requested below.

---

### Analytics SDKs

The current build does **not** include any third-party analytics SDK (e.g., Firebase Analytics, Amplitude, Mixpanel, Adjust, AppsFlyer, etc.).

---

### Advertising SDK

The app uses the **Google Mobile Ads SDK (AdMob)** to display interstitial/rewarded ads.

- Google's iOS data disclosure for the Mobile Ads SDK:
  https://developers.google.com/admob/ios/privacy/data-disclosure

- Google's guidance on child-directed content and ad targeting:
  https://support.google.com/admob/answer/6219315
  https://developers.google.com/admob/ios/targeting

---

### App-Level Data Handling

- The app does **not** transmit any custom personal data to our own servers. We do not operate a backend.
- Gameplay scores (current score and best score) are stored **locally on-device** via `UserDefaults` only.
- In-app purchases are handled entirely through **Apple StoreKit / App Store services**. We do not process or store payment information.
- **Game Center** is used solely for leaderboard score submission and display. No additional profile data is read or stored by the app.

---

### Guideline 2.1(b) — "REMOVE ADS" Button Unresponsive on iPad

We have identified and fixed the issue that caused the **REMOVE ADS** button to appear unresponsive.

**Root cause:** The StoreKit 2 purchase flow was fully asynchronous with no in-app visual feedback. When the button was tapped, there was no UI change to indicate that the system was processing the request, making it appear as if nothing had happened.

**Fix applied in this build:**

1. A **purchase status model** (`PurchaseStatus`) now tracks `idle`, `loading`, `success`, and `failure` states.
2. Tapping **REMOVE ADS** immediately changes the button text to `PROCESSING…` and dims it, while a status label shows `"Connecting to App Store…"`.
3. If the StoreKit product lookup returns no product (e.g., when Paid Apps Agreement is inactive), the user sees: `"Purchase unavailable. Please try again."` — no more silent failure.
4. If the purchase succeeds, the status label shows `"Ads removed. Thank you!"` and the IAP buttons are removed from the overlay.
5. If the purchase fails, the status label shows `"Purchase failed. Please try again."` and the button is re-enabled.
6. **Restore Purchases** now shows the same loading/success/failure feedback (`"Restoring purchases…"`, `"Purchases restored."`, or `"No purchases found to restore."`).
7. Rapid repeated taps while a purchase is in progress are now ignored.

These changes ensure that every tap produces immediate, visible feedback and eliminates the perception of the button being dead.

---

*We are happy to provide additional information or a demo video if needed. Thank you for the thorough review.*
