# Classipod for the Walkman

Patches for [Classipod](https://github.com/adeeteya/classipod) on the Sony
NW-WM1AM2 (Android 11). They apply to upstream commit
[`772a6d3`](https://github.com/adeeteya/classipod/commit/772a6d3533677bfa78f9251a40df8fa8ca3e6180)
(pinned in `upstream-commit`).

| Patch | What it does |
| --- | --- |
| `0001` | Turns off Impeller, which crashes in the Walkman's Vivante GPU shader compiler. It's the same fix as the hand-patched APK on the device, applied in source. |
| `0002` | Fixes the charging indicator and adds **Settings > Battery**. |
| `0003` | Adds **Settings > Home Screen**, for using Classipod as the home screen. |

## Charging indicator

Classipod got its lightning bolt from `battery_plus`. That plugin asks the
battery HAL for a status and never checks whether a charger is plugged in.
The patched app reads the same Android broadcast the system status bar uses:

- With nothing plugged in, there is no bolt.
- Plugged in, the bolt goes away when the battery stops gaining charge:
  - the level drops, or doesn't rise for 15 minutes (Battery Care holding
    it, or a USB port that supplies less than the screen uses);
  - with Battery Care on, it reaches 90%.
- The level updates live. Before, it only refreshed when the charging state
  changed.

## Settings > Battery

On Android only:

| Item | Setting |
| --- | --- |
| Status | Charging / Not Charging / Charged / On Battery. Select it to open the system battery usage page. |
| Battery Saver | Android Battery Saver (`global low_power`) |
| Battery Care | Sony's charge limit (about 90%), see below |
| Bluetooth Scanning | `global ble_scan_always_enabled`. This was being changed over adb before. |
| Screen Timeout | 15 s to 10 min (`system screen_off_timeout`) |

Android doesn't let an app change these settings on its own. You run one
command once, and it stays granted until Classipod is uninstalled:

```sh
adb shell pm grant com.adeeteya.classipod android.permission.WRITE_SECURE_SETTINGS
```

Until you run it, the screen shows an **Allow Changes** item with this
command.

**About Battery Care.** Sony doesn't document where it stores Battery Care.
On first open, the app looks through Android's settings tables for it.
- If the app finds an on/off value, the item toggles it and shows On or Off.
- If it doesn't, or Android won't let it change the value, the item opens the
  system Battery page, where Sony's own switch is.

Check once that Sony's Battery page agrees with what Classipod shows.

## Home screen

**Settings > Home Screen** (Android only) is off by default.
- **Turning it on** shows Android's "Set Classipod as your default home app?"
  dialog. Confirm it, and Classipod opens at boot, and pressing Home brings
  you back to its main menu.
- **Turning it off** hands home back to the Walkman's own launcher.

While Classipod is the home screen, Back on the main menu does nothing.
Otherwise Android would close Classipod and then reopen it.

Classipod's home entry is a tiny native screen that hands straight over to
the normal Classipod screen, so only one copy of Classipod runs. If the
dialog doesn't appear, pick Classipod under Android's **Default apps > Home
app**.

## Build and install

### On the Mac (keeps your Classipod library and settings)

The installed copy is signed with the Mac's debug key, so build with that
key and the update installs over it.

```sh
# Needs Flutter 3.47.6 (the pinned commit requires it).
classipod/apply.sh ~/Developer/Classipod   # makes branch walkman-battery
cd ~/Developer/Classipod
cat > android/key.properties <<EOF
storeFile=$HOME/.android/debug.keystore
storePassword=android
keyPassword=android
keyAlias=androiddebugkey
EOF
flutter pub get
flutter build apk --release --flavor production
adb install -r --no-incremental build/app/outputs/flutter-apk/app-production-release.apk
adb shell pm grant com.adeeteya.classipod android.permission.WRITE_SECURE_SETTINGS
adb shell cmd package compile -m speed -f com.adeeteya.classipod
```

`apply.sh` won't run on a checkout with uncommitted changes. The
`walkman-perf` branch is based on an older upstream commit, so these
patches don't apply to it directly. Rebase it onto `walkman-battery` when
you pick that work up again.

### From GitHub Actions

Every push that touches `classipod/` runs the **Classipod for Walkman**
workflow. It runs Classipod's analyzer and tests, then uploads
`classipod-walkman` (the APK) as an artifact.

- Without secrets, it signs with a throwaway key. That APK only installs
  after you uninstall the current copy, which loses Classipod's library and
  settings.
- To get CI builds that install over the Mac build, add the repo secret
  `CLASSIPOD_KEYSTORE_BASE64`, containing `base64 -i ~/.android/debug.keystore`.

## ADB over Wi-Fi

The Walkman runs Android 11, which has **Wireless debugging** (Developer
options).
1. On the Walkman, open Wireless debugging and tap **Pair device with
   pairing code**.
2. On the Mac, run `adb pair <ip>:<pair-port>` and enter the code.
3. On the Mac, run `adb connect <ip>:<port>`.

Every `adb` command above then works without a cable. The Mac and the
Walkman must be on the same network.
