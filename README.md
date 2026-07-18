# Custom ImmortalWrt Builds for MT798x

Custom firmware based on
[padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6)
(`openwrt-24.10-6.6`), built in both router and preconfigured dumb access
point variants.

## Supported Devices

- Zyxel EX5601-T0 (ubootmod)
- GL.iNet GL-MT3000 / Beryl AX

## Local Features

- Corrected MediaTek country/region mappings.
- 5 GHz DFS, 802.11h, and dedicated zero-wait DFS support.
- English-focused package selection with MediaTek Wi-Fi/LuCI tools and useful
  diagnostics, without the bundled VPN/proxy extras.

## Build Variants

The GitHub Actions workflow builds every supported device for both variants:

- `ap`: applies the AP-mode rootfs overlay.
- `router`: uses router defaults unless files are added under
  `overlays/router/files/`.

Artifacts are named `firmware-<profile>-<variant>-<date>`.

## AP Overlay

[`overlays/ap/files/etc/uci-defaults/99-ap-mode`](overlays/ap/files/etc/uci-defaults/99-ap-mode)
applies these settings on first boot:

- Static LAN address `10.0.0.9/24`, with gateway and DNS server `10.0.0.1`.
- DHCPv4, DHCPv6, router advertisements, NDP, and LAN IPv6 prefix assignment
  disabled.
- Timezone set to `Europe/Stockholm`.
- Wi-Fi country set to Sweden (`SE`).
- 2.4 GHz set to channel 6 with `HE40`; 5 GHz set to `HE80`.
- AP interfaces secured with WPA2-PSK using the initial key `password123`.
- Configuration failures logged and reported with a nonzero exit status.

> **Required:** Reboot the device once after its first boot. This is necessary
> for DNS resolution on the device itself to work correctly.

After rebooting, manage the device at `http://10.0.0.9/`. Change the default
Wi-Fi key immediately.

## AP-to-Router Conversion

On the 24.10 LuCI feed used by this build, the DHCP Server tab exposes the
`dhcp.lan.ignore` checkbox but not the `dhcp.lan.dhcpv4` setting. The AP
overlay sets both `dhcp.lan.ignore='1'` and `dhcp.lan.dhcpv4='disabled'`, so
unchecking "Ignore interface" in LuCI may not be enough to turn DHCPv4 service
back on.

If converting an installed AP image back to router mode, also run this over SSH:

```sh
uci set dhcp.lan.ignore='0'
uci set dhcp.lan.dhcpv4='server'
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='150'
uci set dhcp.lan.leasetime='12h'
uci commit dhcp
service dnsmasq restart
```

Also review the LAN address, gateway, DNS, firewall, and IPv6 settings, since
the AP overlay changes those away from normal router defaults.

## Installation

Download the matching device and variant from the draft GitHub Release, extract
it, and flash the `*squashfs-sysupgrade.itb` image from an existing
OpenWrt/ImmortalWrt ubootmod installation.
