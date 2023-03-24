# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ../system/hardware/amd.nix
    ../system/hardware/acpid.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "nct6775" "it87" ];
  boot.kernelParams = [ "nr_hugepages=4096" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.it87 ];
  boot.extraModprobeConfig = ''
    options zfs l2arc_headroom=0
  '';
  boot.zfs.extraPools = [ "data" ];
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
  };

  fileSystems."/" = {
    device = "root/nixos/root";
    fsType = "zfs";
  };
  fileSystems."/home" = {
    device = "root/nixos/home";
    fsType = "zfs";
  };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/D2EC-879D";
      fsType = "vfat";
    };

  fileSystems."/nix" = {
    device = "root/nixos/nix";
    fsType = "zfs";
  };
  hardware.enableRedistributableFirmware = true;

  swapDevices = [ ];

  networking.hostName = "yew"; # Define your hostname.
  networking.hostId = "c667b97b";
  systemd.network = {
    links."enp211s0f0" = {
      matchConfig.PermanentMacAddress = "a8:a1:59:e3:66:6d";
      linkConfig = {
        AutoNegotiation = false;
        BitsPerSecond = "10G";
        Duplex = "full";
      };
    };
    networks = {
      "10-wired" = {
        matchConfig.Name = [ "enp211s0f0" ];
        DHCP = "yes";
        dns = [ "[::1]:1053" "127.0.0.1:1053" "192.168.2.1:53" ];
        domains = [ "~." ];
        linkConfig = {
          RequiredForOnline = true;
          Multicast = true;
          AllMulticast = true;
          Promiscuous = true;
        };
        networkConfig = {
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = true;
          IPv6SendRA = false;
        };
        dhcpPrefixDelegationConfig = {
          Assign = false;
        };
        dhcpV4Config = {
          UseDNS = false;
          ClientIdentifier = "mac";
        };
        dhcpV6Config = {
          UseDNS = false;
          PrefixDelegationHint = "::/63";
        };
        ipv6AcceptRAConfig = {
          DHCPv6Client = "always";
        };
      };
      "10-wired-bridge" = {
        matchConfig.Name = [ "enp211s0f1" ];
        DHCP = "no";
        linkConfig = {
          RequiredForOnline = true;
        };
        networkConfig = {
          LLMNR = false;
          MulticastDNS = true;
          DHCPServer = true;
          # IPForward = true;
          IPMasquerade = "ipv4";
          Address = [ "192.168.2.1/24" ];
          DHCPPrefixDelegation = true;
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
        };
        dhcpServerConfig = {
          DNS = [ "192.168.2.1" ];
          EmitNTP = false;
          EmitSIP = false;
          EmitDNS = true;
          BindToInterface = false;
          PoolOffset = 100;
          PoolSize = 20;
        };
        routes = [{
          routeConfig = { Destination = "192.168.2.0/24"; };
        }];
      };
    };
  };
  networking.firewall.interfaces."enp211s0f0".allowedUDPPorts = [ 546 547 ];
  networking.firewall.interfaces."enp211s0f1".allowedUDPPorts = [ 67 546 547 53 ];

  powerManagement.cpuFreqGovernor = pkgs.lib.mkForce
    "ondemand";
  environment.systemPackages = with pkgs; [
    freeipmi
    dmidecode
    cpuid
    cpu-x
    lm_sensors
  ];

  services.openssh.enable = true;

}
