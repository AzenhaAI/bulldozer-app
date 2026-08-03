# iOS signing & installing on a device (BullDozer)

Companion to `APPSTORE-STEPS.md`: that one covers submitting to the App Store,
this one covers getting a build onto a physical iPhone.

## Status — 31 Jul 2026: paid account is live

| | |
|---|---|
| Team | **K Shpara / ARY46X758B** (Admin) |
| Certificates | Apple Development ×2 + **Apple Distribution: K Shpara** |
| On device | BullDozer **1.28.0 (44)** |
| Signature valid until | **2027-07-30** — a year, not 7 days |
| 3-app free-provisioning cap | **gone** — BullDozer, AlfaCat, Madeira Ativa, PapaGaio and PapaShopa coexist |
| Daily reinstall agent | **disabled** (see below) |

The daily launchd agent that used to re-sign the app every night is parked at
`~/Library/LaunchAgents/com.shpara.bulldozer.reinstall.plist.disabled`.
It only existed to beat the 7-day free-provisioning expiry, so a paid account
makes it pointless. To bring it back: drop the `.disabled` suffix and
`launchctl load` it.

## The trap that cost an hour — read this first

Xcode can **show** the account under Settings → Apple Accounts while having no
live session behind it (nothing under `idmsa.apple.com` in the keychain, and
`DVTDeveloperAccountManagerAppleIDLists` empty in the prefs). When that happens
both the GUI build and the command line fail with the same pair:

```
error: No Accounts: Add a new account in Accounts settings.
error: No profiles for 'com.shpara.bulldozerApp' were found
```

Restarting Xcode does not help. Neither does `-allowProvisioningUpdates`.

**Fix:** Xcode → Settings → Apple Accounts → **Download Manual Profiles**.
That pulls the **wildcard profile `ARY46X758B.*`**, which covers *any* bundle id
in the team — after which `flutter build ios --release` signs and builds with no
automatic provisioning at all. This is exactly how it was resolved on 31 Jul 2026.

## Rebuild and install

```bash
cd ~/Projects/bulldozer_app
flutter build ios --release
xcrun devicectl device install app --device 00008110-0004050C3633801E \
  build/ios/iphoneos/Runner.app
```

Use `devicectl`, not `flutter install`. `devicectl` upgrades in place and keeps
the app container — favourites, the theme choice and the offline cache survive.
`flutter install` uninstalls first, wiping all of it on every run.

Note: `devicectl` accepts the plain UDID (`00008110-…`); the CoreDevice UUID
printed by `devicectl list devices` is not required.

## Where the pieces live

- App source: `~/Projects/bulldozer_app`
- Android upload keystore: `android/upload-keystore.jks` + `key.properties`
  (both gitignored — never commit them), backed up outside iCloud in
  `~/Documents/BullDozer_signing_keys/`
- Store listing copy, icon, feature graphic, screenshots: `store/`
- Releases with APK assets: github.com/kirshp/bulldozer-app/releases

_Updated: 31 Jul 2026._
