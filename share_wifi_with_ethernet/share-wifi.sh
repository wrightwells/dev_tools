#!/usr/bin/env bash
set -euo pipefail

PROFILE_NAME="wifi-share-ethernet"
WIFI_IF="wlp2s0"
ETH_IF="enp0s31f6"
WIFI_CONN="Private"

usage() {
  echo "Usage:"
  echo "  sudo $0 on"
  echo "  sudo $0 off"
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root: sudo $0 ..."
    exit 1
  fi
}

require_nmcli() {
  if ! command -v nmcli >/dev/null 2>&1; then
    echo "nmcli not found. Install NetworkManager first."
    exit 1
  fi
}

check_interfaces() {
  if ! nmcli -t -f DEVICE device status | grep -qx "$WIFI_IF"; then
    echo "Wi-Fi interface '$WIFI_IF' not found."
    exit 1
  fi

  if ! nmcli -t -f DEVICE device status | grep -qx "$ETH_IF"; then
    echo "Ethernet interface '$ETH_IF' not found."
    exit 1
  fi
}

check_wifi_connected() {
  local state
  state="$(nmcli -t -f DEVICE,STATE device status | awk -F: -v dev="$WIFI_IF" '$1==dev{print $2}')"

  if [[ "$state" != "connected" ]]; then
    echo "Wi-Fi interface '$WIFI_IF' is not connected."
    echo "Expected active Wi-Fi connection: $WIFI_CONN"
    exit 1
  fi
}

enable_share() {
  check_interfaces
  check_wifi_connected

  echo "Turning on Ethernet sharing from $WIFI_IF to $ETH_IF..."

  if nmcli -t -f NAME connection show | grep -qx "$PROFILE_NAME"; then
    nmcli connection delete "$PROFILE_NAME" >/dev/null 2>&1 || true
  fi

  nmcli connection add \
    type ethernet \
    ifname "$ETH_IF" \
    con-name "$PROFILE_NAME" \
    ipv4.method shared \
    ipv6.method disabled \
    autoconnect no

  nmcli connection up "$PROFILE_NAME"

  echo
  echo "Sharing is ON."
  echo "Wi-Fi source:     $WIFI_IF ($WIFI_CONN)"
  echo "Ethernet output:  $ETH_IF"
  echo "Profile:          $PROFILE_NAME"
  echo
  echo "Plug the other machine into $ETH_IF and set it to DHCP/automatic IP."
}

disable_share() {
  check_interfaces

  echo "Turning off Ethernet sharing on $ETH_IF..."

  if nmcli -t -f NAME connection show | grep -qx "$PROFILE_NAME"; then
    nmcli connection down "$PROFILE_NAME" >/dev/null 2>&1 || true
    nmcli connection delete "$PROFILE_NAME"
    echo "Sharing is OFF."
  else
    echo "Sharing profile '$PROFILE_NAME' was not present."
  fi
}

status_show() {
  echo
  nmcli device status
  echo
  ip addr show "$ETH_IF" || true
  echo
  nmcli connection show --active
}

main() {
  require_root
  require_nmcli

  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    on)
      enable_share
      status_show
      ;;
    off)
      disable_share
      status_show
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
