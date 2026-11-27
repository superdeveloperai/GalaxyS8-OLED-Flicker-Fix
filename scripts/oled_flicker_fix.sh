#!/system/bin/sh
# Magisk service.d script: Galaxy S8 Exynos (hadesRom + patched hadesKernel)
# Kernel clamps hardware brightness >= 23000 via panel_bl.c (min_hw_brightness).
# This daemon maps the Android brightness slider (screen_brightness 0..255)
# to SurfaceFlinger color-matrix dimming (0.25..1.00) with 250ms responsiveness.

BL_PATH="/sys/class/backlight/panel/brightness"
BL_POWER="/sys/class/backlight/panel/bl_power"
PIDFILE="/data/local/tmp/oled_flicker_fix.pid"

# Stop any older running instance so updates take effect cleanly
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
        sleep 0.3
    fi
fi

apply_sf_dim() {
    cur="$1"
    [ "$cur" -lt 0 ] 2>/dev/null && cur=0
    [ "$cur" -gt 255 ] 2>/dev/null && cur=255
    pct=$(( 25 + (cur * 75) / 255 ))
    if [ "$pct" -ge 99 ]; then
        service call SurfaceFlinger 1015 i32 0 >/dev/null 2>&1
    else
        s="0.$pct"
        service call SurfaceFlinger 1015 i32 1 \
            f "$s" f 0 f 0 f 0 \
            f 0 f "$s" f 0 f 0 \
            f 0 f 0 f "$s" f 0 \
            f 0 f 0 f 0 f 1 >/dev/null 2>&1
    fi
}

{
    trap '' HUP
    echo $$ > "$PIDFILE"

    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 2
    done

    chmod 644 "$BL_PATH" 2>/dev/null
    settings put system dim_screen 0

    last_cur=-1
    last_power=1

    while true; do
        pwr=$(cat "$BL_POWER" 2>/dev/null)
        if [ "$pwr" = "0" ] && [ "$last_power" != "0" ]; then
            last_cur=-1
        fi
        last_power="$pwr"

        if [ "$pwr" = "0" ]; then
            cur=$(settings get system screen_brightness 2>/dev/null)
            case "$cur" in
                ''|*[!0-9]*) ;;
                *)
                    if [ "$cur" != "$last_cur" ]; then
                        apply_sf_dim "$cur"
                        last_cur="$cur"
                    fi
                    ;;
            esac
        fi

        sleep 0.25
    done
} </dev/null >/dev/null 2>&1 &
