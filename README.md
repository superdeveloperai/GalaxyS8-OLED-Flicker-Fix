# Samsung AMOLED Low-Brightness OLED Flicker & Touch Glitch Fix

A **kernel + Magisk** fix for aging **Samsung Super AMOLED devices** (tested on Galaxy S8 Exynos `dreamlte`, adaptable to any rooted Samsung Galaxy S/Note/A-series phone) that exhibit **green/white screen flickering** and **touchscreen glitches** at low brightness levels due to low-voltage PWM/AID degradation.

> **Using an AI Assistant for Another Samsung Model?**
> This repository is structured so you (or an AI coding assistant) can adapt the exact same two-layer fix to **any rooted Samsung AMOLED device**:
> 1. Probe `/sys/class/backlight/panel/brightness` to find your panel's flicker-free hardware floor.
> 2. Apply the kernel clamp pattern from [`patches/0001-panel_bl-clamp-min-hw-brightness.patch`](patches/0001-panel_bl-clamp-min-hw-brightness.patch) to your device's kernel source (`panel_bl.c` on Exynos, or `dsi_panel.c` / `mdss_dsi_panel.c` on Snapdragon).
> 3. Use [`scripts/oled_flicker_fix.sh`](scripts/oled_flicker_fix.sh) on Android 8–11 (or native Extra Dim `reduce_bright_colors` on Android 12+).

---

## Why This Happens
On aging Samsung AMOLED panels, dropping hardware backlight below a threshold (e.g. `plat_br < 7000–21500`) starves the panel's shared ELVDD/ELVSS/touch rails, causing:
1. Green/white screen flickering (especially during lock/wake brightness ramps and low-light use).
2. Ghost touches or unresponsive digitizer at low brightness.

Locking `/sys/class/backlight/panel/brightness` from userspace (`chmod 444`) is not enough on its own because the kernel driver (`panel_bl.c`) still ramps brightness down during wake/AOD/boot transitions, and third-party overlay dimming apps trigger Android tapjacking/permission blocks.

---

## How This Fix Works (Two-Layer Architecture)

1. **Kernel-Level Hardware Voltage Floor (`patches/0001-panel_bl-clamp-min-hw-brightness.patch`):**
   - Clamps `PANEL_BL_SUBDEV_TYPE_DISP` brightness inside `panel_bl_set_brightness()` to at least `min_hw_brightness` (default: **`23000`** / ~372 nits, safely within Samsung's stock `0–25500` UI / `36600` HBM range).
   - Exposes `/sys/module/panel_bl/parameters/min_hw_brightness` (`0644`) so you can tune the hardware floor live as root without reflashing.
2. **Magisk `service.d` Software Dimming (`scripts/oled_flicker_fix.sh`):**
   - Polls `screen_brightness` (`0–255`) every `0.25s` and applies **`SurfaceFlinger` color-matrix dimming (`1015`)** from `0.25` (slider at 0%) to `1.0` (slider at 100%).
   - Works with **manual** and **Adaptive Brightness**, with zero overlay apps and zero tapjacking issues.

---

## Downloads (Pre-Built Patched Kernel)

- **Direct Kernel Image (`boot_patched_g950f_hadesKernel_v1.5_pie.img`):**  
  [Download v1.0.0 Boot Image](https://github.com/superdeveloperai/GalaxyS8-OLED-Flicker-Fix/releases/download/v1.0.0/boot_patched_g950f_hadesKernel_v1.5_pie.img)
- **All Releases & Checksums:** [GitHub Releases](https://github.com/superdeveloperai/GalaxyS8-OLED-Flicker-Fix/releases/tag/v1.0.0)

> Only flash this pre-built `.img` on **Galaxy S8 Exynos (`dreamlte`)** running **Android 9 (`hadesRom_OneUI_v12.0` / `hadesKernel-v1.5`)**. For other Samsung models or Android versions, see [docs/BUILD_FROM_SOURCE.md](docs/BUILD_FROM_SOURCE.md).

---

## Repository Structure

```text
.
├── README.md
├── docs/
│   ├── FLASHING_GUIDE.md          # Step-by-step TWRP/ADB flashing & rollback guide
│   └── BUILD_FROM_SOURCE.md       # Reproducible Docker ARM64 kernel build guide
├── patches/
│   └── 0001-panel_bl-clamp-min-hw-brightness.patch
├── scripts/
│   ├── oled_flicker_fix.sh        # Magisk service.d slider -> SurfaceFlinger daemon
│   └── revert_oled_fix.sh         # Remove service.d script & reset SurfaceFlinger
└── docker/
    └── Dockerfile                 # Ubuntu 20.04 ARM64 kernel build environment
```

Pre-built boot image (`boot_patched_g950f_hadesKernel_v1.5_pie.img`) is available on the **GitHub Releases** page.

---

## Tested Device & ROM Profile
- **Hardware:** Samsung Galaxy S8 Exynos (`SM-G950F`, `samsungexynos8895`, `dreamlte`)
- **ROM:** `hadesRom_OneUI_v12.0` (Android 9 Pie / SDK 28)
- **Kernel Base:** `4.4.111-hadesKernel-v1.5-dreamlte` ([corsicanu/android_kernel_samsung_universal8895](https://github.com/corsicanu/android_kernel_samsung_universal8895), branch `9`)
- **Root:** Magisk `29.0` + TWRP Recovery

> **Disclaimer:** Flashing a boot image carries inherent risk. Always back up your current `BOOT` partition in TWRP before flashing. See [docs/FLASHING_GUIDE.md](docs/FLASHING_GUIDE.md).
