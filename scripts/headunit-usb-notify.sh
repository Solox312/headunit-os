#!/usr/bin/env bash
# HeadUnit OS — USB hotplug notifier (run as root by udev)
#
# Reads the vendor/product ID of the device that just appeared (sysfs is
# already gone by the time ACTION=="remove" fires, so removals are reported
# without IDs) and forwards a one-line JSON event to every running HeadUnit
# OS instance's notification socket.
#
# Installed by scripts/install_usb_hotplug.sh to /usr/local/bin/.
set -euo pipefail

ACTION="${1:-}"
KERNEL="${2:-}"

if [[ -z "$ACTION" || -z "$KERNEL" ]]; then
  exit 0
fi

VENDOR=""
PRODUCT=""

if [[ "$ACTION" == "add" ]]; then
  SYSFS="/sys/bus/usb/devices/$KERNEL"
  VENDOR=$(cat "$SYSFS/idVendor" 2>/dev/null || echo "")
  PRODUCT=$(cat "$SYSFS/idProduct" 2>/dev/null || echo "")
  # Hubs and root ports have no readable device descriptor — ignore that noise.
  [[ -n "$VENDOR" ]] || exit 0
elif [[ "$ACTION" == "remove" ]]; then
  VENDOR="unknown"
  PRODUCT="unknown"
else
  exit 0
fi

EVENT="{\"action\":\"$ACTION\",\"vendor\":\"$VENDOR\",\"product\":\"$PRODUCT\"}"

# Fan out to every logged-in user's runtime socket (normally just one — the
# kiosk user) plus the /tmp fallback used outside a systemd user session.
# A missing socat binary or no listener yet are both non-fatal — udev must
# never fail a rule over this.
for sock in /run/user/*/headunit-os/usb-hotplug.sock /tmp/headunit-os/usb-hotplug.sock; do
  [[ -S "$sock" ]] || continue
  echo "$EVENT" | timeout 1 socat - "UNIX-CONNECT:$sock" 2>/dev/null || true
done

exit 0
