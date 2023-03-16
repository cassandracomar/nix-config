{ config, lib, pkgs, ... }:
with pkgs; let
  joolBin = "${jool-cli}/bin/jool_siit";
  awk = "${gawk}/bin/gawk";
  ip = "${iproute2}/bin/ip";
  process-address = pkgs.writeScriptBin "process-address.rb" ''
    #!${ruby}/bin/ruby
    require 'ipaddr'
    require 'socket'

    increment = ARGV[0] == true.to_s
    address_parts = ARGV[1].split('/')
    address = IPAddr.new address_parts[0], Socket::AF_INET6
    res = increment ? address.succ : "#{address.mask(address_parts[1].to_i)}/#{address_parts[1]}"
    puts res.to_s
  '';
  jool-start = pkgs.writeShellScriptBin "jool-start" ''
    set -eux

    PRIMARY_INTERFACE=$(${ip} -o -6 addr list | grep -v ::1 | grep -v fe80 | ${awk} '{print $2}' | head -n 1)
    PREFIX=$(${ip} -o -6 addr list | grep ''${PRIMARY_INTERFACE} | ${awk} '{print $4}' | head -n 1)
    ADDRESS=$(PREFIX | cut -d/ -f 1)

    ${ip} netns add nat64
    ${ip} link add name to_nat64 type veth peer name to_world
    ${ip} link set to_nat64 up

    ${ip} link set dev to_world netns nat64
    ${ip} netns exec nat64 ${ip} link set to_world up

    TO_WORLD=$(${ip} netns exec nat64 ${ip} -o -6 addr show scope link dev to_world | ${awk} '{print $4}' | cut -d/ -f 1)
    TO_NAT64=$(${ip} -o -6 addr show scope link dev to_nat64 | ${awk} '{print $4}' | cut -d/ -f 1)
    ${ip} netns exec nat64 ${ip} -6 route add default via ''${TO_NAT64} dev to_world
    ${ip} netns exec nat64 ${ip} -4 addr add 192.168.255.1/24 dev to_world

    NAT64_IADDR=$(${process-address}/bin/process-address.rb true ''${PREFIX})
    ${ip} -6 neigh add proxy ''${NAT64_IADDR} dev $PRIMARY_INTERFACE
    ${ip} -6 route add ''${NAT64_IADDR} via $TO_WORLD dev to_nat64
    ${ip} -4 addr add 192.168.255.2/24 dev to_nat64
    ${ip} -4 route add default via 192.168.255.1 dev to_nat64

    ${ip} netns exec nat64 ${joolBin} instance add default --netfilter --pool6 $(${process-address}/bin/process-address.rb false ''${PREFIX})
    ${ip} netns exec nat64 ${joolBin} global update logging-debug true
  '';
  jool-stop = pkgs.writeShellScriptBin "jool-stop" ''
    PRIMARY_INTERFACE=$(${ip} -o -6 addr list | grep -v ::1 | grep -v fe80 | ${awk} '{print $2}' | head -n 1)
    ${ip} addr del 64:ff9b::2 dev $PRIMARY_INTERFACE || true
    ${ip} netns exec nat64 ${joolBin} instance flush
    ${ip} netns delete nat64
  '';

in
{
  boot.kernelModules = [ "jool_siit" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ jool ];
  environment.systemPackages = with pkgs; [ jool-cli ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    nameservers = [ ];
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
        dhcpV4Config.UseDNS = false;
        dhcpV6Config.UseDNS = false;
      };
      "20-wireless" = {
        matchConfig.Type = [ "wlan" ];
        enable = false;
        linkConfig.Unmanaged = true;
      };
    };
  };

  systemd.services.jool = {
    enable = false;
    wants = [ "network-pre.target" ];
    wantedBy = [ "network-online.target" ];
    before = [ "dnscrypt-proxy2.service" ];
    partOf = [ "systemd-networkd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${jool-start}/bin/jool-start";
      ExecStop = "${jool-stop}/bin/jool-stop";
      RemainAfterExit = "yes";
      User = "root";
    };
  };

  # secerorvices.headscale.enable = true;
  services.resolved = {
    enable = true;
    fallbackDns = [ "[::1]:1053" "127.0.0.1:1053" ];
    dnssec = "true";
    extraConfig = ''
      DNS=[::1]:1053 127.0.0.1:1053
      MulticastDNS=yes
      DNSStubListenerExtra=[::1]:53
    '';
  };

  systemd.services.nscd = {
    wantedBy = lib.mkForce [ ];
    after = lib.mkForce [ ];
    enable = lib.mkForce false;
  };

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
      listen_addresses = [ "127.0.0.1:1053" "[::1]:1053" "127.0.0.11:53" ];
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

      dns64 = {
        prefix = [ "64:ff9b::/96" ];
        resolver = [ "[2606:4700:4700::64]:53" "[2606:4700:4700::6400]:53" ];
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
