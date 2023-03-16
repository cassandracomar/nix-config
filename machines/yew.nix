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

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/56bf7cf3-5c55-47bf-8aed-47be50a1f0b1";
      fsType = "f2fs";
      options = [
        "compress_algorithm=zstd"
        "compress_chksum"
        "atgc"
        "gc_merge"
        "lazytime"
        "inline_xattr"
      ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/D2EC-879D";
      fsType = "vfat";
    };

  fileSystems."/nix" = {
    device = "data/nix";
    fsType = "zfs";
  };
  hardware.enableRedistributableFirmware = true;

  boot.kernel.sysctl = {
    "net.ipv6.conf.enp211s0f0.proxy_ndp" = 1;
  };

  swapDevices = [ ];

  networking.hostName = "yew"; # Define your hostname.
  networking.hostId = "c667b97b";
  systemd.network = {
    networks = {
      "10-wired" = {
        matchConfig.Name = [ "enp211s0f0" ];
        networkConfig = {
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = true;
          IPv6SendRA = true;
        };
        linkConfig = {
          RequiredForOnline = true;
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/62";
        };
        ipv6AcceptRAConfig = {
          Token = "prefixstable";
        };
      };
      "10-wired-bridge" = {
        matchConfig.Name = [ "enp211s0f1" ];
        linkConfig = {
          RequiredForOnline = true;
        };
        DHCP = "yes";
        networkConfig = {
          DHCPPrefixDelegation = true;
          DHCPServer = true;
          IPv6AcceptRA = true;
          IPv6SendRA = true;
          IPForward = true;
          MulticastDNS = true;
          Address = [ "192.168.2.1/24" ];
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/63";
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
    };
  };


  powerManagement.cpuFreqGovernor = pkgs.lib.mkForce "ondemand";
  environment.systemPackages = with pkgs; [
    freeipmi
    dmidecode
    cpuid
    cpu-x
    lm_sensors
  ];

  services.openssh.enable = true;

}
