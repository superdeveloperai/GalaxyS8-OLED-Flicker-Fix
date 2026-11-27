#!/system/bin/sh
# Reverts the OLED flicker fix and removes the Magisk service.d script.

PIDFILE="/data/local/tmp/oled_flicker_fix.pid"
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$OLD_PID" ] && kill "$OLD_PID" 2>/dev/null
    rm -f "$PIDFILE"
fi

rm -f /data/adb/service.d/oled_flicker_fix.sh
chmod 644 /sys/class/backlight/panel/brightness 2>/dev/null
service call SurfaceFlinger 1015 i32 0 >/dev/null 2>&1
settings put system dim_screen 1
echo "Reverted OLED flicker fix."
