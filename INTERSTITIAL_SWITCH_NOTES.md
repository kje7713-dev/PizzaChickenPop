# Interstitial Ad Switch Notes

## Current build configuration

The current build uses **Google's iOS interstitial test ad unit** for verification:

```
ca-app-pub-3940256099942544/4411468910
```

This is set in `project.yml` under `GAD_INTERSTITIAL_AD_UNIT_ID`.

## Before release: swap to production ID

Replace the test ad unit ID with the real production interstitial ID:

**Production interstitial ad unit ID:**
```
ca-app-pub-9428188855756038/1848936777
```

**Exact change to make in `project.yml`:**

```yaml
# Change this line:
    GAD_INTERSTITIAL_AD_UNIT_ID: ca-app-pub-3940256099942544/4411468910

# To this:
    GAD_INTERSTITIAL_AD_UNIT_ID: ca-app-pub-9428188855756038/1848936777
```

The App ID (`GAD_APPLICATION_IDENTIFIER: ca-app-pub-9428188855756038~5488090074`) does not need to change.
