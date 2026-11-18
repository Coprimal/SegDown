# Contributing

Build steps are in [README.md](README.md#build-from-source). Releases are made locally; see `scripts/ship.sh`.

## Update feed

- **Feeds:** since 0.7.6, the app's `SUFeedURL` is `https://segdown.coprimal.dev/appcast.xml` and the Firefox add-on's `update_url` is `https://segdown.coprimal.dev/firefox-updates.json`. `.github/workflows/pages.yml` publishes the root `appcast.xml` and `firefox-updates.json` from `main` to GitHub Pages (Settings > Pages > Source = "GitHub Actions", custom domain `segdown.coprimal.dev` with Enforce HTTPS). Cloudflare DNS has a CNAME `segdown` → `coprimal.github.io` (DNS only); `coprimal.dev` is verified for the Coprimal org.
- **Old addresses:** the repo moved from `dinhanhthi/SegDown` to `Coprimal/SegDown` in 2026-11. GitHub redirects the old repo and release URLs, but not `github.io`. Builds <= 0.7.5 read `https://dinhanhthi.github.io/SegDown/appcast.xml`, and their Firefox add-ons read `https://dinhanhthi.github.io/SegDown/firefox-updates.json`. The user site `dinhanhthi/dinhanhthi.github.io` serves a mirror of both files under `SegDown/`. `scripts/publish-appcast.sh` updates it on every release through `scripts/sync-feed-mirror.sh`, which publishes the files as they are on `origin/main`. If a release warns that the mirror was not synced, run `scripts/sync-feed-mirror.sh`.
- **The mirror is a permanent trust root** for those builds: keep two-factor authentication on the account that owns it. Sparkle's EdDSA signature and Mozilla's add-on signing still protect the downloads themselves.
- **Never:** edit the mirror by hand, delete it or give it a custom domain; create or fork a repo named `dinhanhthi/SegDown` (it would take over the old paths and break GitHub's redirects); move or rename the root `appcast.xml` or `firefox-updates.json`; change the Pages source or remove the custom domain; change the bundle IDs (`com.math2it.segdown*`), the gecko id `me@dinhanhthi.com` (tied to the AMO account) or `SUPublicEDKey`.
- **Feed check:**

  ```sh
  curl -sI https://segdown.coprimal.dev/appcast.xml                 # HTTP 200, no location
  curl -s https://segdown.coprimal.dev/appcast.xml | cmp - appcast.xml
  curl -s https://segdown.coprimal.dev/firefox-updates.json | cmp - firefox-updates.json
  curl -sL https://dinhanhthi.github.io/SegDown/appcast.xml | cmp - appcast.xml
  curl -sL https://dinhanhthi.github.io/SegDown/firefox-updates.json | cmp - firefox-updates.json
  ```

  On a clean checkout of `main` in sync with `origin/main`, each `cmp` prints nothing. Right after a push, the Pages deploy and the mirror can take a few minutes to catch up.
