{ config, lib, pkgs, pkgs-master, ... }:

{
  boot.kernelModules = [ "jool" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ jool ];
  environment.systemPackages = with pkgs; [ jool-cli ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.accept_ra" = 2;
    "net.ipv6.conf.all.accept_ra" = 2;
    "net.ipv6.conf.all.accept_ra_from_local" = 1;
    "net.ipv4.conf.all.accept_local" = 1;
    "net.ipv6.conf.all.accept_local" = 1;
  };

  networking = {
    nameservers = [ ];
    # resolvconf.enable = true;
    # resolvconf.useLocalResolver = true;
    enableIPv6 = true;
    useNetworkd = true;

    # wireless configuration
    networkmanager = {
      enable = false;
      # dns = "none";
      connectionConfig = {
        "connection.mdns" = "2";
      };
      unmanaged = [ "en*" "usb*" ];
    };

    useDHCP = false;
    dhcpcd.enable = false;
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
        linkConfig = {
          RequiredFamilyForOnline = "ipv6";
        };
        dhcpV6Config.UseDNS = false;
      };
      "20-wireless" = {
        matchConfig.Type = [ "wlan" ];
        enable = false;
        linkConfig.Unmanaged = true;
      };
    };
  };

  # secerorvices.headscale.enable = true;
  services.resolved = {
    enable = true;
    fallbackDns = [ "[::1]:1053" "127.0.0.1:1053" ];
    extraConfig = ''
      DNS=[::1]:1053
      MulticastDNS=yes
      DNSStubListenerExtra=[::1]:53
    '';
  };

  systemd.services.nscd = {
    wantedBy = lib.mkForce [ ];
    after = lib.mkForce [ ];
    enable = lib.mkForce false;
  };

  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
  # set up anonymized and encrypted DNS
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv4_servers = true;
      ipv6_servers = true;
      require_dnssec = true;
      require_nofilter = true;
      dnscrypt_servers = true;
      doh_servers = false;
      odoh_servers = true;
      listen_addresses = [ "127.0.0.1:1053" "[::1]:1053" "127.0.0.11:53" "192.168.2.1:53" ];
      bootstrap_resolvers = [ "[2620:fe::11]:53" "[2620:fe::fe:11]:53" ];

      sources = {
        public-resolvers = {
          urls = [
            "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
          minisign_key =
            "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        relays = {
          urls = [
            "https://ipv6.download.dnscrypt.info/resolvers-list/v3/relays.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy/relays.md";
          minisign_key =
            "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        odoh-relays = {
          urls = [ "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md" "https://download.dnscrypt.info/resolvers-list/v3/odoh-relays.md" ];
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
          cache_file = "/var/lib/dnscrypt-proxy/odoh-relays.md";
        };
        odoh-servers = {
          urls = [ "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md" "https://download.dnscrypt.info/resolvers-list/v3/odoh-servers.md" ];
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
          cache_file = "/var/lib/dnscrypt-proxy/odoh-servers.md";
        };
      };

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
      server_names = [
        "dct-ru1"
        "scaleway-ams"
        "scaleway-ams-ipv6"
        "ams-dnscrypt-nl-ipv6"
        "quad9-dnscrypt-ip4-nofilter-pri"
        "meganerd"
        "meganerd-ipv6"
        "dnscrypt.pl"
        "altername"
        "altername-ipv6"
        "ibksturm"
        "plan9dns-mx"
        "odoh-ibksturm"
        "odoh-koki-se"
        "odoh-meganerd"
      ];

      anonymized_dns = {
        skip_incompatible = true;
        routes = [{
          server_name = "*";
          via = [
            "anon-tiarap"
            "anon-sth-se"
            "anon-serbica"
            "anon-cs-sk"
            "anon-cs-serbia"
            "anon-dnscrypt.uk-ipv6"
            "odohrelay-crypto-sx"
            "odohrelay-surf"
            "odoh-ams"
            "anon-meganerd-ipv6"
            "anon-scaleway-ams-ipv6"
            "anon-tiarap-ipv6"
            "anon-v.dnscrypt.uk-ipv6"
          ];
        }];
      };
    };
  };
  systemd.services.dnscrypt-proxy2.environment = {
    DEBUG = "1";
  };
  systemd.services.dnscrypt-proxy2.serviceConfig.ExecStart = lib.mkForce "${pkgs.dnscrypt-proxy2}/bin/dnscrypt-proxy -config ${config.services.dnscrypt-proxy2.configFile} -loglevel 0";

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

  ## firewall rules
  networking.firewall = {
    checkReversePath = "loose";
    allowedTCPPorts = [ 8384 22000 5353 ];
    allowedUDPPorts = [ 22000 21027 5353 ];
    logRefusedConnections = true;
    logRefusedPackets = true;
    logRefusedUnicastsOnly = true;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
