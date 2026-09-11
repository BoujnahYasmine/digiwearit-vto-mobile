#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'The iPhone simulator requires macOS with Xcode.' >&2
  exit 1
fi
for tool in flutter pod xcrun python3; do
  command -v "$tool" >/dev/null || { echo "Missing $tool. See IOS_SETUP.md." >&2; exit 1; }
done
xcrun --find simctl >/dev/null
/usr/libexec/PlistBuddy -c 'Print :GOOGLE_APP_ID' ios/Runner/GoogleService-Info.plist >/dev/null
plutil -lint ios/Runner/Info.plist ios/Runner/GoogleService-Info.plist ios/Runner.xcodeproj/project.pbxproj
# Regenerate local SDK paths after copying the project from Windows.
flutter pub get
(cd ios && pod install --repo-update)
read -r simulator_id simulator_state < <(python3 - <<'PY'
import json, os, subprocess, sys
payload = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json']))
devices = []
for runtime, entries in payload['devices'].items():
    if '.iOS-' not in runtime:
        continue
    version = tuple(map(int, runtime.split('.iOS-')[1].split('-')))
    if version[0] >= 15:
        devices.extend((version, d) for d in entries if d.get('isAvailable') and d['name'].startswith('iPhone'))
requested = os.environ.get('SIMULATOR_UDID')
if requested:
    devices = [(v, d) for v, d in devices if d['udid'] == requested]
if not devices:
    sys.exit('No compatible iPhone simulator found. Install an iOS runtime and create an iPhone in Xcode > Window > Devices and Simulators.')
devices.sort(key=lambda item: (item[1]['state'] == 'Booted', item[0]), reverse=True)
d = devices[0][1]
print(d['udid'], d['state'])
PY
)
if [[ "$simulator_state" != Booted ]]; then
  xcrun simctl boot "$simulator_id"
fi
open -a Simulator
xcrun simctl bootstatus "$simulator_id" -b
# Optional: import a real JPG/PNG into Photos for the Galerie capture path.
if [[ -n "${PHOTO_PATH:-}" ]]; then
  xcrun simctl addmedia "$simulator_id" "$PHOTO_PATH"
fi
flutter run -d "$simulator_id" "$@"
