# Parental Gate – Implementation Notes

## What was added

A non-bypassable parental gate (`ParentalGateOverlay`) is now required before
any commerce-related action in the app.

### Gated actions

| Action | Before | After |
|---|---|---|
| Remove Ads ($0.99 IAP) | Tapped directly | Parental gate must be passed first |
| Restore Purchases | Tapped directly | Parental gate must be passed first |

## Gate design

- Displayed as a full-screen SpriteKit overlay (zPosition 300+, above all game UI)
- Title: **"Parents Only"**
- Randomised arithmetic challenge: `"What is A + B?"` where A, B ∈ [2, 12]
- Three answer buttons with shuffled order: one correct, two plausible wrong answers
- **Cancel** button – dismisses the gate without triggering any commerce
- Wrong answer – dismisses the gate without triggering any commerce
- Correct answer – dismisses the gate and proceeds to the commerce action

## Cannot be disabled

- `ParentalGateOverlay` has no `isEnabled` flag or bypass path
- The gate is constructed fresh each time with a new random question
- `GameScene.showParentalGate()` guards against stacking (duplicate taps ignored)
- All touches are absorbed by the overlay while it is visible

## Third-party ad click-out limitation

AdMob banner and rewarded ad click-outs are handled entirely by the Google
Mobile Ads SDK and are not triggered by app code.  Apple's Kids Category
guidelines require the parental gate for **app-controlled** commerce/external
links.  SDK-controlled ad click-outs are outside the app's direct control;
however, the rewarded-ad flow is gated behind the 30-second gameplay session
and is not a user-initiated commerce action.  If App Review requires
additional controls over SDK-level click-outs, the AdMob ad unit(s) would
need to be configured with a child-directed treatment flag (already handled by
the AdMob dashboard / Info.plist `GADIsAdManagerApp` settings if applicable).
