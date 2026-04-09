# AdMob Release Switch

## Summary

This change replaces the Google demo interstitial test ad unit with the
production AdMob interstitial ad unit in preparation for App Store submission.

## Production values (active in `project.yml`)

| Setting | Value |
|---|---|
| App ID (`GAD_APPLICATION_IDENTIFIER`) | `ca-app-pub-9428188855756038~5488090074` |
| Interstitial Ad Unit ID (`GAD_INTERSTITIAL_AD_UNIT_ID`) | `ca-app-pub-9428188855756038/1848936777` |

## Removed

- Google demo interstitial test unit `ca-app-pub-3940256099942544/4411468910`
  has been removed from the active build configuration.

## Reminder

**Do not use Google demo ad units (`ca-app-pub-3940256099942544/...`) in
submitted builds.** Demo units are for local development and simulator testing
only. Submitted builds must reference a real AdMob unit registered in the
[AdMob console](https://admob.google.com/).
