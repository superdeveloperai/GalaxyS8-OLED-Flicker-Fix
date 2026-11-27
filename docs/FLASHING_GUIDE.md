# Flashing & Installation Guide

> **Compatibility Warning:** The pre-built `boot_patched_g950f_hadesKernel_v1.5_pie.img` in Releases is built specifically for **Galaxy S8 Exynos (`dreamlte`)** running **Android 9 (`hadesRom_OneUI_v12.0` / `hadesKernel-v1.5`) with Magisk**. If you are on a different variant (`dream2lte` / `greatlte`) or different Android version (OneUI 2.5 / AOSP 10–13+), **do not flash this image**—follow [BUILD_FROM_SOURCE.md](BUILD_FROM_SOURCE.md) to patch and build your own kernel.

---

## Step 1: Back Up Your Current Boot Partition (Mandatory)
1. Boot into **TWRP Recovery** (`Vol Up + Bixby + Power`).
2. Tap **Backup** -> select **Boot** -> swipe to back up.
   - Alternatively, via rooted ADB:
     ```sh
     adb shell "su -c 'dd if=/dev/block/by-name/BOOT of=/sdcard/boot_backup.img bs=4096'"
     ```

---

## Step 2: Flash the Patched Kernel (`boot.img`)

Download `boot_patched_g950f_hadesKernel_v1.5_pie.img` from **GitHub Releases** and copy it to `/sdcard/` on your phone:
```sh
adb push boot_patched_g950f_hadesKernel_v1.5_pie.img /sdcard/
```

### Option A: Flash via TWRP (Recommended)
1. Boot into **TWRP**.
2. Tap **Install** -> **Install Image** (bottom-right button).
3. Select `/sdcard/boot_patched_g950f_hadesKernel_v1.5_pie.img`.
4. Select **Boot** partition and swipe to flash.
5. Reboot System.

### Option B: Flash via Rooted ADB
```sh
adb shell "su -c 'dd if=/sdcard/boot_patched_g950f_hadesKernel_v1.5_pie.img of=/dev/block/by-name/BOOT bs=4096 && sync'"
adb reboot
```

### Verify Kernel Clamp After Boot
```sh
adb shell "su -c 'cat /sys/module/panel_bl/parameters/min_hw_brightness'"
# Expected output: 23000
```

---

## Step 3: Install the Magisk Software-Dimming Script
The kernel clamp keeps hardware brightness at `23000+` (~372 nits). Install `scripts/oled_flicker_fix.sh` so your normal brightness slider dims the screen smoothly in software via `SurfaceFlinger`:

```sh
adb push scripts/oled_flicker_fix.sh /data/local/tmp/oled_flicker_fix.sh
adb shell "su -c '
  mv /data/local/tmp/oled_flicker_fix.sh /data/adb/service.d/oled_flicker_fix.sh
  chmod 755 /data/adb/service.d/oled_flicker_fix.sh
  chown root:root /data/adb/service.d/oled_flicker_fix.sh
'"
adb reboot
```

---

## Tuning & Optional Tweaks

### 1. Adjust Hardware Voltage Floor Live
If your panel needs a higher or lower threshold (range `0`–`36600`, stock UI max is `25500`):
```sh
adb shell "su -c 'echo 24500 > /sys/module/panel_bl/parameters/min_hw_brightness'"
```
To make a custom floor persistent across reboots, add that `echo` line to `/data/adb/service.d/oled_flicker_fix.sh`.

### 2. Eliminate Brief AOD Transition Flicker
If your panel flickers briefly when entering Always On Display (`panel_doze` LPM mode), disable AOD in **Settings -> Lock screen -> Always On Display** (or `settings put system aod_mode 0`).

### 3. Adjust Software Dimming Range
In `scripts/oled_flicker_fix.sh`, line:
```sh
pct=$(( 25 + (cur * 75) / 255 ))
```
maps slider `0–255` to `0.25–1.00` (`25%` to `100%`). Change `25` / `75` if you want `0%` slider to go darker (e.g. `15` / `85`).

---

## Rollback / Uninstall
1. **Remove the Magisk script:**
   ```sh
   adb push scripts/revert_oled_fix.sh /data/local/tmp/
   adb shell "su -c 'sh /data/local/tmp/revert_oled_fix.sh && rm -f /data/local/tmp/revert_oled_fix.sh'"
   ```
2. **Restore original kernel:** Boot into TWRP -> **Restore** your Boot backup (or **Install Image** -> `/sdcard/boot_backup.img` -> **Boot**).
