{ pkgs, ... }:

{
  networking = {
    # nameservers = [ ];
    # resolvconf.enable = true;
    # resolvconf.useLocalResolver = true;
    enableIPv6 = true;
    useNetworkd = true;

    # wireless configuration
    networkmanager = {
      enable = pkgs.lib.mkDefault false;
      # dns = "none";
      connectionConfig = {
        "connection.mdns" = "2";
      };
      unmanaged = [ "en*" "usb*" ];
    };

    # useDHCP = false;
    # dhcpcd.enable = false;
    # resolvconf.dnsSingleRequest = true;
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
      };
      "20-wireless" = {
        matchConfig.Type = [ "wlan" ];
        enable = false;
        linkConfig.Unmanaged = true;
      };
    };
  };

  # services.headscale.enable = true;
  services.resolved = {
    enable = true;
  };

  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
  # set up anonymized and encrypted DNS
  # services.dnscrypt-proxy2 = {
  #   enable = true;
  #   settings = {
  #     ipv4_servers = true;
  #     ipv6_servers = true;
  #     require_dnssec = true;
  #     require_nofilter = true;
  #     require_nolog = true;
  #     dnscrypt_servers = true;
  #     doh_servers = false;
  #     odoh_servers = true;
  #     lb_strategy = "ph";
  #     blocked_names = {
  #       blocked_names_file = (pkgs.fetchFromGitHub {
  #         owner = "StevenBlack";
  #         repo = "hosts";
  #         rev = "master";
  #         sha256 = "sha256-Yzr6PY/zqQE+AHH0J6ioHTsgkikM+dz4aelbGpQJa1s=";
  #       }) + /hosts;
  #     };
  #     # skip_incompatible = true;
  #     listen_addresses = [ "127.0.0.1:1053" "[::1]:1053" "127.0.0.11:53" "192.168.2.1:53" ];
  #     bootstrap_resolvers = [ "[2620:fe::11]:53" "[2620:fe::fe:11]:53" ];

  #     sources = {
  #       public-resolvers = {
  #         urls = [
  #           "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
  #         ];
  #         cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
  #         minisign_key =
  #           "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
  #       };
  #       relays = {
  #         urls = [
  #           "https://ipv6.download.dnscrypt.info/resolvers-list/v3/relays.md"
  #         ];
  #         cache_file = "/var/lib/dnscrypt-proxy/relays.md";
  #         minisign_key =
  #           "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
  #       };
  #       odoh-relays = {
  #         urls = [ "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md" "https://download.dnscrypt.info/resolvers-list/v3/odoh-relays.md" ];
  #         minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
  #         cache_file = "/var/lib/dnscrypt-proxy/odoh-relays.md";
  #       };
  #       odoh-servers = {
  #         urls = [ "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md" "https://download.dnscrypt.info/resolvers-list/v3/odoh-servers.md" ];
  #         minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
  #         cache_file = "/var/lib/dnscrypt-proxy/odoh-servers.md";
  #       };
  #     };

  #     # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
  #     # server_names = [
  #     #   "dct-ru1"
  #     #   "scaleway-ams"
  #     #   "scaleway-ams-ipv6"
  #     #   "ams-dnscrypt-nl-ipv6"
  #     #   "quad9-dnscrypt-ip4-nofilter-pri"
  #     #   "meganerd"
  #     #   "meganerd-ipv6"
  #     #   "dnscrypt.pl"
  #     #   "altername"
  #     #   "altername-ipv6"
  #     #   "ibksturm"
  #     #   "plan9dns-mx"
  #     #   "odoh-ibksturm"
  #     #   "odoh-koki-se"
  #     #   "odoh-meganerd"
  #     # ];

  #     anonymized_dns = {
  #       skip_incompatible = true;
  #       routes = [{
  #         server_name = "*";
  #         via = [
  #           "anon-tiarap"
  #           "anon-sth-se"
  #           "anon-serbica"
  #           "anon-cs-sk"
  #           "anon-cs-serbia"
  #           "anon-dnscrypt.uk-ipv6"
  #           "odohrelay-crypto-sx"
  #           "odohrelay-surf"
  #           "odoh-ams"
  #           "anon-meganerd-ipv6"
  #           "anon-scaleway-ams-ipv6"
  #           "anon-tiarap-ipv6"
  #           "anon-v.dnscrypt.uk-ipv6"
  #         ];
  #       }];
  #     };
  #   };
  # };
  # systemd.services.dnscrypt-proxy2.environment = {
  #   DEBUG = "1";
  # };
  # systemd.services.dnscrypt-proxy2.serviceConfig.ExecStart = lib.mkForce "${pkgs.dnscrypt-proxy2}/bin/dnscrypt-proxy -config ${config.services.dnscrypt-proxy2.configFile} -loglevel 0";

  # services.syncthing = {
  #   enable = true;
  #   user = "cassandra";
  #   dataDir = "/home/cassandra/drive";
  #   configDir = "/home/cassandra/.config/syncthing";
  #   overrideDevices = true;
  #   overrideFolders = true;
  #   guiAddress = "192.168.2.1:8384";
  #   devices = {
  #     "cass-opp-9p" = { id = "SDA26VM-DP2AGO2-HHGIJ6G-UVX25M3-3UBSMFY-M4XZ6DM-42COXSX-K7H7CQK"; };
  #     "cass-pixel-7" = { id = "QZRZMPV-AZD45ZL-VIDEAF7-GWOLSXC-JWCGMXP-346OQCR-YZGEQG3-JZUUVQN"; };
  #     "mel-magus" = { id = "HPRUBKI-XRVSHLO-RQ6G3KS-JKJZAEY-DXMLIJ6-SMLZBSA-32HVGIQ-XW55FAR"; };
  #     "mel-gorre" = { id = "AHCJFCS-JBWYQVV-SQKHNNE-UFWZTEL-FARQS5G-KYRJCXD-RHMJ5K2-H7QDWA2"; };
  #   };
  #   folders = {
  #     "Games" = {
  #       path = "/home/cassandra/Games/small";
  #       devices = [ "cass-opp-9p" "cass-pixel-7" "mel-magus" "mel-gorre" ];
  #     };
  #     "imgs" = {
  #       path = "/home/cassandra/imgs";
  #       devices = [ "cass-opp-9p" "cass-pixel-7" "mel-magus" "mel-gorre" ];
  #     };
  #     "drive" = {
  #       path = "/home/cassandra/drive";
  #       devices = [ "cass-opp-9p" "cass-pixel-7" "mel-magus" "mel-gorre" ];
  #     };
  #     "important" = {
  #       path = "/home/cassandra/important";
  #       devices = [ "mel-gorre" ];
  #     };
  #     ".SeedVaultAndroidBackup" = {
  #       path = "/home/cassandra/.SeedVaultAndroidBackup";
  #       devices = [ "cass-pixel-7" ];
  #     };
  #   };
  # };

  # services.attestation-server = {
  #   enable = true;
  #   domain = "attestation.ndra.io";
  # };

  ## firewall rules
  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    allowedTCPPorts = [ 80 443 8384 22000 5353 ];
    allowedUDPPorts = [ 22000 21027 5353 ];
    logRefusedConnections = true;
    logRefusedPackets = true;
    logRefusedUnicastsOnly = true;
  };

  security = {
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    protectKernelImage = true;
    sudo.keepTerminfo = true;
  };
  services.dbus.apparmor = "enabled";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  security.pki.certificates = [
    ''
      local trust root
      =========
      -----BEGIN CERTIFICATE-----
      MIIB3DCCAYKgAwIBAgIUeLNrkgHyp2GhO6Ee4fyvVbGaUg0wCgYIKoZIzj0EAwIw
      OjEMMAoGA1UEChMDRFJXMRQwEgYDVQQLDAtJU1NAZHJ3LmNvbTEUMBIGA1UEAxML
      SVNTIFJvb3QgQ0EwHhcNMTcwMzAxMjA0MzAwWhcNMjcwMjI3MjA0MzAwWjA6MQww
      CgYDVQQKEwNEUlcxFDASBgNVBAsMC0lTU0BkcncuY29tMRQwEgYDVQQDEwtJU1Mg
      Um9vdCBDQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAjg18NvaBfwKP0BC/9U
      Cppc1W2rfSqzsY4KCRIAubItoMyQ13zp25KjVg9IF7Uru7cWQcUMvwf4+2Gb/4m4
      sFSjZjBkMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEBMB0GA1Ud
      DgQWBBSA3cairIJP/ooZLqrq+L9hSNwxczAfBgNVHSMEGDAWgBSA3cairIJP/ooZ
      Lqrq+L9hSNwxczAKBggqhkjOPQQDAgNIADBFAiAgvGnmTJgMosKFYuRJ7HZMuD/p
      ZTNapVJltFiGzKAtewIhAJMVQ72U+m7kLNRw6ej7icBQ9d+T4MuhGyJEeYeX5wR4
      -----END CERTIFICATE-----
    ''
    ''
      local trust CA
      =========
      -----BEGIN CERTIFICATE-----
      MIICYjCCAgigAwIBAgIUDZxs4OPknZA8SgUkWZ7EncHkYVIwCgYIKoZIzj0EAwIw
      OjEMMAoGA1UEChMDRFJXMRQwEgYDVQQLDAtJU1NAZHJ3LmNvbTEUMBIGA1UEAxML
      SVNTIFJvb3QgQ0EwHhcNMTcwMzAxMjA0NDAwWhcNMjcwMjI3MjA0NDAwWjA3MQww
      CgYDVQQKEwNEUlcxFDASBgNVBAsMC0lTU0BkcncuY29tMREwDwYDVQQDEwhTU0RO
      UyBDQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNsaSU2QU1Z5ktRf19DaXZk6
      TrPko0TPZFTSYFH9bPxVJ4guUfGnN5nZ7vQajX2NJJLZEL9TZGYSsE8RD/ftcsij
      ge4wgeswDgYDVR0PAQH/BAQDAgGmMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEF
      BQcDAjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSMYP14x7P9WQtzmeU2
      SD9Tp0GCZTAfBgNVHSMEGDAWgBSA3cairIJP/ooZLqrq+L9hSNwxczA1BggrBgEF
      BQcBAQQpMCcwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLmlzcy5kcncvc3NkbnMw
      LwYDVR0fBCgwJjAkoCKgIIYeaHR0cDovL2NlcnRzLmlzcy5kcncvc3NkbnMvY3Js
      MAoGCCqGSM49BAMCA0gAMEUCIBU5FNCu7ZmE7H1Oautblig4iA5JIgOO+4D/do2c
      pQ8IAiEAkIdZb5Doptfk1C5uofcvww3E0ZrSG98ZJ2+TW9sz4VA=
      -----END CERTIFICATE-----
    ''
  ];
}
