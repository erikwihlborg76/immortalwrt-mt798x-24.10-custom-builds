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
- English-focused package selection with MediaTek Wi-Fi/LuCI tools, without the bundled VPN/proxy extras.

## Build Output

The GitHub Actions workflow builds every supported device for both variants:

- `ap`
- `router`

Artifacts are named `firmware-<profile>-<variant>-<date>`.

Shared shell helpers live in
[`files/lib/custom-builds/uci-defaults-common.sh`](files/lib/custom-builds/uci-defaults-common.sh)
and are copied into every image before the variant-specific overlay.

## Common Defaults

Both variants apply these first-boot defaults:

- Timezone set to `Europe/Stockholm`.
- Wi-Fi country set to Sweden (`SE`).
- 2.4 GHz set to channel 6 with `HE40`; 5 GHz set to `HE80`.
- AP interfaces secured with WPA2-PSK using the initial key `password123`.

Change the default Wi-Fi key immediately.

## Variant Defaults

The AP variant, configured by
[`overlays/ap/files/etc/uci-defaults/99-ap-mode`](overlays/ap/files/etc/uci-defaults/99-ap-mode),
is for use behind an existing router:

- Static LAN address `10.0.0.9/24`.
- Gateway and DNS server set to `10.0.0.1`.
- LAN IPv6 prefix assignment disabled.
- DHCPv4, DHCPv6, router advertisements, and NDP disabled.
- Manage after reboot at `http://10.0.0.9/`.

> **Required for AP mode:** Reboot the device once after first boot. This is
> necessary for DNS resolution on the device itself to work correctly.

The router variant, configured by
[`overlays/router/files/etc/uci-defaults/99-router-mode`](overlays/router/files/etc/uci-defaults/99-router-mode),
is for use as the LAN router:

- Static LAN address `10.0.0.1/24`.
- LAN gateway and DNS overrides removed from the router itself.
- LAN IPv6 prefix assignment set to `60`.
- DHCPv4 server enabled with leases from `10.0.0.100` through `10.0.0.249`.
- DHCPv6 and router advertisements enabled.
- Manage after boot at `http://10.0.0.1/`.

## AP-to-Router Conversion

On the 24.10 LuCI feed used by this build, the DHCP Server tab exposes the
`dhcp.lan.ignore` checkbox but not the `dhcp.lan.dhcpv4` setting. The AP
overlay sets both `dhcp.lan.ignore='1'` and `dhcp.lan.dhcpv4='disabled'`, so
unchecking "Ignore interface" in LuCI may not be enough to turn DHCPv4 service
back on.

If converting an installed AP image manually instead of flashing the router
variant, also run this over SSH:

```sh
uci set network.lan.proto='static'
uci -q delete network.lan.ipaddr
uci add_list network.lan.ipaddr='10.0.0.1/24'
uci -q delete network.lan.gateway
uci -q delete network.lan.dns
uci set network.lan.ip6assign='60'
uci commit network

uci set dhcp.lan.ignore='0'
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='150'
uci set dhcp.lan.leasetime='12h'
uci set dhcp.lan.dhcpv4='server'
uci set dhcp.lan.dhcpv6='server'
uci set dhcp.lan.ra='server'
uci -q delete dhcp.lan.ndp
uci -q delete dhcp.lan.ra_flags
uci add_list dhcp.lan.ra_flags='managed-config'
uci add_list dhcp.lan.ra_flags='other-config'
uci commit dhcp
service dnsmasq restart
```

Also review firewall and WAN settings, since those determine whether the device
actually behaves as your edge router.

## Installation

Download the matching device and variant from the draft GitHub Release, extract
it, and flash the `*squashfs-sysupgrade.itb` image from an existing
OpenWrt/ImmortalWrt ubootmod installation.
