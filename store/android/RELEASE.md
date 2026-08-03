# BullDozer — Android release (Google Play)

Package: `com.shpara.bulldozer_app` · signed with `android/upload-keystore.jks`
(backup at `~/Documents/BullDozer_signing_keys/upload-keystore.jks`)
Upload file: **`bulldozer-vX.Y.Z.aab`** (this folder)

## What is already done
- Release AAB built and signed with the permanent upload key (verified: the
  AAB signer SHA-256 matches the keystore cert, not the debug key).
- App icon 512 (`store/icon-512.png`), feature graphic 1024×500.
- Store texts in `store/listing.md`.
- Privacy policy page prepared in the SITE repo (`~/Projects/bulldozer`),
  route `https://shpara.com/bulldozer/privacy`.

## Privacy page — DONE (live)
`https://shpara.com/bulldozer/privacy` returns 200.
Note: the site deploys via the **shpara1 monorepo**, not the (currently dead)
`deploy.yml` GitHub Action — its `SHPARA1_DEPLOY_KEY` secret is unset, so that
Action goes green but silently skips deploy. To publish a site change:
```sh
cd ~/Projects/bulldozer && npm run build
cp -R dist/<page> ~/Projects/shpara1/bulldozer/<page>        # or rsync the whole dist
cd ~/Projects/shpara1 && git add bulldozer && git commit -m "..." && git push   # CF Pages serves
```

## Sequence — first publish
1. **Create app:** Play Console → Create app → "BullDozer", English, App, Free.
2. **Store listing:** paste from `listing.md`; upload icon (512), feature
   graphic (1024×500), min 2 phone screenshots.
3. **Privacy:** URL = `https://shpara.com/bulldozer/privacy` (deploy first).
   Data safety → no data collected / shared.
4. **Content rating** → Everyone.
5. **Closed testing (required, new personal accounts):** Testing → Closed
   testing → create track → add **≥12 testers** → upload the `.aab` → roll out.
   Testers opt in and keep it installed **14 days**.
6. After 14 days Google unlocks **Production**: promote the same build → submit.

## Sequence — every update afterwards
1. Bump `version:` in `pubspec.yaml` (e.g. 1.27.0+43 → 1.28.0+44).
2. `flutter build appbundle --release` → new `.aab`.
3. Play Console → create release → upload `.aab` → review → roll out.

> Keep `upload-keystore.jks` + its password (`android/key.properties`) forever.
> Both are gitignored and must NEVER be committed (the repo is public).
> Lose the key and you can no longer update the app.
