{
  lanCidr = "192.168.100.0/24";
  mainGateway = "192.168.100.1";
  nameservers = [ "192.168.100.1" ];

  # LAN leases observed on 2026-11-18. The router's DHCP pool is unknown.
  hostsAddr = {
    oregairu-yukino = {
      dhcpIPv4 = "192.168.100.61";
      tailscaleIPv4 = "100.113.79.112";
    };
    oregairu-iroha = {
      dhcpIPv4 = "192.168.100.67";
      tailscaleIPv4 = "100.70.243.82";
    };
    oregairu-yui = {
      dhcpIPv4 = "192.168.100.69";
      tailscaleIPv4 = "100.125.172.47";
    };
  };
}
