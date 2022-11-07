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
    resolvconf.enable = true;
    resolvconf.useLocalResolver = true;
    enableIPv6 = true;
    networkmanager = {
      enable = true;
      dns = "none";
      insertNameservers = [
        # "172.20.0.1"
        "127.0.0.1"
        "::1"
      ];
    };
    useDHCP = false;
    dhcpcd.enable = false;
    firewall.checkReversePath = "loose";
  };
  # services.headscale.enable = true;

  # set up anonymized and encrypted DNS
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" "127.0.0.11:53" ];

      sources = {
        public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            "https://download.dnscrypt.net/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
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
          cache_file = "/var/lib/dnscrypt-proxy2/relays.md";
          minisign_key =
            "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };

      forwarding_rules = pkgs.writeText "forwarding-rules.txt" ''
        ditto.live 100.100.100.100
        local 192.168.0.1:5353
      '';

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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
