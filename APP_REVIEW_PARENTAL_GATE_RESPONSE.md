# App Review Response – Parental Gate (Kids Category)

## Subject

Response to rejection of PizzaChicken Pop v1.1 – Guideline 4.3 (Kids Category
– Commerce / In-App Purchases)

---

## Response text (paste-ready)

Thank you for reviewing PizzaChicken Pop.  We have addressed the Kids Category
rejection by implementing a non-bypassable parental gate before all in-app
commerce actions.

**Changes made in the updated build:**

1. **Parental gate added before Remove Ads.**  When a user taps "REMOVE ADS –
   $0.99", an overlay titled "Parents Only" is displayed immediately.  The
   overlay presents a randomised arithmetic challenge (e.g. "What is 7 + 5?")
   with three answer buttons in shuffled order.  The in-app purchase flow does
   not begin until the correct answer is selected.  Tapping the wrong answer or
   the Cancel button dismisses the overlay with no purchase initiated.

2. **Parental gate added before Restore Purchases.**  The same "Parents Only"
   overlay (with a freshly randomised question) is shown when the user taps
   "Restore Purchases".  The restore flow does not begin until the correct
   answer is selected.

3. **The gate cannot be disabled.**  There is no setting, flag, or code path
   that bypasses or disables the parental gate.  Every tap on a commerce button
   unconditionally presents the gate.

4. **Underlying controls are fully blocked.**  While the gate overlay is
   visible, all scene touches are routed exclusively to the gate.  It is not
   possible to interact with any underlying game UI while the gate is displayed.

5. **Works on iPhone and iPad.**  The overlay scales to the full scene size on
   all device classes.

We believe the updated build fully addresses the stated rejection reason and
complies with the Kids Category parental gate requirement.  We have submitted
the updated build for re-review and look forward to hearing from you.

---

## Files changed

| File | Description |
|---|---|
| `Sources/UI/ParentalGateOverlay.swift` | New – parental gate overlay component |
| `Sources/Game/GameScene.swift` | Modified – gate hooked into Remove Ads and Restore Purchases touch handlers |
| `PARENTAL_GATE_NOTES.md` | New – implementation notes |
| `APP_REVIEW_PARENTAL_GATE_RESPONSE.md` | This file |
