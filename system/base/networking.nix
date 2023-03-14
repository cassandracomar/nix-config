{ config, lib, pkgs, ... }:

{
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = false;
  # networking.interfaces.enp0s13f0u1u3.useDHCP = false;
  # networking.interfaces.enp0s13f0u1u3.ipv4.addresses = [{
  #   address = "192.168.1.10";
  #   prefixLength = 24;
  # }];
  #networking.interfaces.vethc1c7b69.useDHCP = true;

  networking = {
    nameservers = [
      # "172.20.0.1"
      "127.0.0.1"
      "::1"
    ];
    # resolvconf.enable = true;
    # resolvconf.useLocalResolver = true;
    enableIPv6 = true;
    useNetworkd = true;

    # wireless configuration
    networkmanager = {
      enable = true;
      # dns = "none";
      connectionConfig = {
        "connection.mdns" = "2";
      };
      unmanaged = [ "en*" "usb*" ];
    };

    useDHCP = false;
    dhcpcd.enable = false;
    firewall.checkReversePath = "loose";
    resolvconf.dnsSingleRequest = true;
  };

  systemd.network = {
    wait-online.enable = false;
    networks = {
      "10-wired" = {
        matchConfig.Type = [ "ether" ];
        DHCP = "yes";
        networkConfig = {
          MulticastDNS = "yes";
        };
        dhcpConfig = {
          UseHostname = false;
          UseDNS = false;
          ClientIdentifier = "mac";
          RouteMetric = 10;
        };
      };
    };
  };

  # secerorvices.headscale.enable = true;
  services.resolved = {
    enable = true;
    extraConfig = ''
      DNS=127.0.0.1:1053 [::1]:1053
      MulticastDNS=yes
    '';
  };

  # set up anonymized and encrypted DNS
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      listen_addresses = [ "127.0.0.55:53" "[::1]:1053" "127.0.0.11:53" ];

      sources = {
        public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            "https://download.dnscrypt.net/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
          minisign_key =
            "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        relays = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
            "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
            "https://ipv6.download.dnscrypt.info/resolvers-list/v3/relays.md"
            "https://download.dnscrypt.net/resolvers-list/v3/relays.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy/relays.md";
          minisign_key =
            "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
      server_names = [
        "bcn-dnscrypt"
        "ams-dnscrypt-nl"
        "ams-dnscrypt-nl-ipv6"
        "dct-del"
        "dct-ru1"
        "dct-ru2"
        "dns.watch"
        "dns.watch-ipv6"
        "dnscrypt-ch-blahdns-ipv4"
        "dnscrypt-ch-blahdns-ipv6"
        "dnscrypt.pl"
        "bcn-doh"
        "dns.digitale-gesellschaft.ch"
      ];

      anonymized_dns = {
        skip_incompatible = true;
        routes = [{
          server_name = "*";
          via = [
            "anon-bcn"
            "anon-acsacsar-ams-ipv4"
            "anon-acsacsar-ams-ipv6"
            "anon-cs-md"
            "anon-cs-la"
            "anon-pf"
            "anon-opennic-R4SAS"
            "anon-opennic-R4SAS-ipv6"
          ];
        }];
      };
    };
  };

  services.syncthing = {
    enable = true;
    user = "cassandra";
    dataDir = "/home/cassandra/drive";
    configDir = "/home/cassandra/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    guiAddress = "0.0.0.0:8384";
    devices = {
      "cass-android" = { id = "SDA26VM-DP2AGO2-HHGIJ6G-UVX25M3-3UBSMFY-M4XZ6DM-42COXSX-K7H7CQK"; };
    };
    folders = {
      "Games" = {
        path = "/home/cassandra/Games/small";
        devices = [ "cass-android" ];
      };
      "imgs" = {
        path = "/home/cassandra/imgs";
        devices = [ "cass-android" ];
      };
      "drive" = {
        path = "/home/cassandra/drive";
        devices = [ "cass-android" ];
      };
    };
  };
  # Syncthing ports
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 5353 ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
