The router variant configures first-boot router defaults through:

`overlays/router/files/etc/uci-defaults/99-router-mode`

It sets the LAN address to `10.0.0.1/24`, enables LAN DHCP/RA services, and
uses the same Wi-Fi defaults as the AP variant.
