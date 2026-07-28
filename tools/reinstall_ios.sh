#!/bin/bash
# Keeps BullDozer alive on Kirill's iPhone. The free signing profile lasts
# 7 days, so the app vanishes without periodic reinstall.
#
# Runs DAILY (launchd: com.shpara.bulldozer.reinstall). Daily rather than
# weekly because any single attempt can miss — phone not connected, or Xcode
# unable to reach the Apple ID from the launchd context. With 7 chances per
# expiry window, one bad day no longer costs the whole week.
#
# Quiet when it works. Notifies only when the app is at real risk of expiring.
# Once the paid Apple Developer Program is active, none of this is needed.
set -o pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
DEVICE="00008110-0004050C3633801E"          # Kirill's iPhone
APP=~/Projects/bulldozer_app
LOG=~/Library/Logs/bulldozer/reinstall_ios.log
STAMP=~/Library/Logs/bulldozer/last_success.txt
DANGER_DAYS=5                                # warn when expiry (7d) is near
ts() { date '+%Y-%m-%d %H:%M:%S'; }

days_since_success() {
  [ -f "$STAMP" ] || { echo 99; return; }
  local last now
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  now=$(date +%s)
  echo $(( (now - last) / 86400 ))
}

# Nag only when the app is actually about to die, so daily runs stay silent.
warn_if_stale() {
  local d; d=$(days_since_success)
  if [ "$d" -ge "$DANGER_DAYS" ]; then
    osascript -e "display notification \"Not refreshed for $d days - connect and unlock the iPhone (or run tools/reinstall_ios.sh by hand).\" with title \"BullDozer: signature expiring soon\"" 2>/dev/null
    echo "$(ts) ⚠️ notified user (stale ${d}d)" >>"$LOG"
  fi
}

echo "===== $(ts) reinstall start =====" >>"$LOG"

# Device enumeration is racy — flutter can return before the iPhone appears —
# so give each probe a real timeout and retry.
connected=""
for attempt in 1 2 3; do
  if flutter devices --machine --device-timeout 20 2>/dev/null | grep -q "$DEVICE"; then
    connected=1; break
  fi
  echo "$(ts) device not seen (attempt $attempt/3), retrying…" >>"$LOG"
  sleep 10
done
if [ -z "$connected" ]; then
  echo "$(ts) iPhone not connected — skipping (stale $(days_since_success)d)" >>"$LOG"
  warn_if_stale
  exit 0
fi

cd "$APP" || { echo "$(ts) no project dir" >>"$LOG"; exit 1; }
echo "$(ts) building release…" >>"$LOG"

# `flutter build ios` targets a generic "Any iOS Device", which signs fine but
# cannot register a device with the team. When the team has no devices on file
# (fresh Apple ID, or the account was removed and re-added) every build fails with
# "no devices from which to generate a provisioning profile" until one build is
# aimed at this exact UDID. Own DerivedData dir — the sibling Flutter apps also
# produce a Runner.app and would otherwise be indistinguishable.
build_out=$(flutter build ios --release 2>&1); rc=$?
echo "$build_out" >>"$LOG"

if [ "$rc" -ne 0 ] && grep -q "no devices from which to generate" <<<"$build_out"; then
  echo "$(ts) team has no registered devices — registering this iPhone, then retrying" >>"$LOG"
  xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
    -destination "id=$DEVICE" -derivedDataPath build/ios-provision \
    -allowProvisioningUpdates build >>"$LOG" 2>&1
  build_out=$(flutter build ios --release 2>&1); rc=$?
  echo "$build_out" >>"$LOG"
fi

if [ "$rc" -eq 0 ]; then
  echo "$(ts) installing to device…" >>"$LOG"
  # devicectl upgrades in place and KEEPS the app container. `flutter install`
  # uninstalls first, which wipes favorites, the theme choice and the offline
  # cache — unacceptable for a script that runs every day. Flutter stays only
  # as a loud fallback.
  if xcrun devicectl device install app --device "$DEVICE" \
       "$APP/build/ios/iphoneos/Runner.app" >>"$LOG" 2>&1; then
    date +%s > "$STAMP"
    echo "$(ts) ✅ reinstall OK (devicectl — app data preserved)" >>"$LOG"
    exit 0
  fi
  # Apple caps free-provisioned apps at 3 per device. When AlfaCat/PapaGaio/
  # PapaShopa already hold the slots, BullDozer simply cannot install — no
  # amount of retrying helps, so say it plainly instead of nagging about staleness.
  if grep -q "MIFreeProfileValidatedAppTracker" "$LOG"; then
    osascript -e 'display notification "Free-provisioning limit: only 3 sideloaded apps fit on the iPhone. Delete one (AlfaCat / PapaGaio / PapaShopa) or go paid Apple Developer." with title "BullDozer: no free app slot"' 2>/dev/null
    echo "$(ts) ❌ blocked by the 3-app free-provisioning limit" >>"$LOG"
    exit 0
  fi
  echo "$(ts) devicectl failed — falling back to flutter install (WIPES app data)" >>"$LOG"
  if flutter install -d "$DEVICE" --release >>"$LOG" 2>&1; then
    date +%s > "$STAMP"
    echo "$(ts) ⚠️ reinstall OK via flutter — favorites/theme/cache were reset" >>"$LOG"
    exit 0
  fi
  echo "$(ts) ❌ install failed" >>"$LOG"
else
  echo "$(ts) ❌ build failed" >>"$LOG"
  # One failure a human must clear: the Apple ID is simply not in Xcode. Say so
  # instead of leaving it to the generic staleness nag days later.
  if grep -q "No Accounts" <<<"$build_out"; then
    osascript -e 'display notification "No Apple ID in Xcode - Settings > Apple Accounts > + (needs your password and 2FA)." with title "BullDozer: signing blocked"' 2>/dev/null
    echo "$(ts) ⚠️ notified user (no Apple ID in Xcode)" >>"$LOG"
  fi
fi
warn_if_stale
