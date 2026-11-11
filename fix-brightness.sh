#!/usr/bin/env bash
# Enable eDP DPCD/AUX backlight on the Intel xe driver (Yoga 7i Pro / Panther Lake).
# Idempotent: safe to re-run. Pass a different interface value to retry if needed.
#   1 = enable DPCD, auto-pick (default, works on the tested machine)
#   2 = force VESA DPCD interface
#   3 = force Intel DPCD interface
# Usage: sudo bash fix-brightness.sh [1|2|3], then reboot.
set -euo pipefail

VALUE="${1:-1}"
CONF=/etc/default/limine
PARAM="xe.enable_dpcd_backlight"

[[ "$VALUE" =~ ^[123]$ ]] || { echo "Value must be 1, 2 or 3 (got '$VALUE')." >&2; exit 1; }
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
[[ -f "$CONF" ]] || { echo "$CONF not found. This script needs limine; see README 'Manual fix'." >&2; exit 1; }
command -v limine-update >/dev/null || { echo "limine-update not found." >&2; exit 1; }

cp "$CONF" "$CONF.bak"
# Drop any previous setting of this param, then append the chosen one on its own line.
sed -i "/${PARAM}=/d" "$CONF"
printf 'KERNEL_CMDLINE[default]+=" %s=%s"\n' "$PARAM" "$VALUE" >> "$CONF"

echo "=== $CONF now (backup: $CONF.bak) ==="
cat "$CONF"

echo "=== regenerating limine boot config ==="
limine-update

echo
echo "Done. Reboot, then press the brightness keys."
