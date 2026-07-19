# shellcheck shell=sh

# Shared logic for custom first-boot UCI defaults.

: "${LOG_TAG:=custom-builds}"

cb_log_error() {
	cb_log_error_message="$*"

	printf '%s: ERROR: %s\n' "$LOG_TAG" "$cb_log_error_message" >&2
	if command -v logger >/dev/null 2>&1; then
		logger -p user.err -t "$LOG_TAG" "$cb_log_error_message" 2>/dev/null || true
	fi
}

cb_fail() {
	cb_log_error "$*"
	exit 1
}

cb_ensure_dhcp_lan_section() {
	if ! uci -q get dhcp.lan >/dev/null 2>&1; then
		uci set dhcp.lan='dhcp'
	fi

	uci set dhcp.lan.interface='lan'
}

cb_configure_stockholm_timezone() {
	uci set 'system.@system[0].zonename=Europe/Stockholm'
	uci set 'system.@system[0].timezone=CET-1CEST,M3.5.0,M10.5.0/3'
	uci commit system
}

cb_load_openwrt_functions() {
	[ -r /lib/functions.sh ] ||
		cb_fail "Required file is unavailable: /lib/functions.sh"
	# shellcheck source=/dev/null
	. /lib/functions.sh
}

cb_configure_wifi_device() {
	cb_configure_wifi_device_section="$1"
	cb_configure_wifi_device_band=""

	WIFI_DEVICE_COUNT=$((WIFI_DEVICE_COUNT + 1))
	config_get cb_configure_wifi_device_band "$cb_configure_wifi_device_section" band

	uci set "wireless.${cb_configure_wifi_device_section}.country=SE"

	case "$cb_configure_wifi_device_band" in
		2g)
			uci set "wireless.${cb_configure_wifi_device_section}.htmode=HE40"
			uci set "wireless.${cb_configure_wifi_device_section}.channel=6"
			;;
		5g)
			uci set "wireless.${cb_configure_wifi_device_section}.htmode=HE80"
			;;
	esac
}

cb_configure_wifi_iface() {
	cb_configure_wifi_iface_section="$1"
	cb_configure_wifi_iface_mode=""

	config_get cb_configure_wifi_iface_mode "$cb_configure_wifi_iface_section" mode
	[ "$cb_configure_wifi_iface_mode" = "ap" ] || return 0

	WIFI_AP_COUNT=$((WIFI_AP_COUNT + 1))
	uci set "wireless.${cb_configure_wifi_iface_section}.encryption=psk2"
	uci set "wireless.${cb_configure_wifi_iface_section}.key=password123"
}

cb_apply_wifi_defaults() {
	/sbin/wifi config ||
		cb_fail "Wireless hardware discovery failed"

	cb_load_openwrt_functions

	WIFI_DEVICE_COUNT=0
	WIFI_AP_COUNT=0

	config_load wireless
	config_foreach cb_configure_wifi_device wifi-device
	[ "$WIFI_DEVICE_COUNT" -gt 0 ] ||
		cb_fail "No wireless device sections were discovered"

	config_foreach cb_configure_wifi_iface wifi-iface
	[ "$WIFI_AP_COUNT" -gt 0 ] ||
		cb_fail "No wireless AP interfaces were discovered"

	uci commit wireless
}
