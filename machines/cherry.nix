# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ pkgs, config, ... }: {
  imports = [
    ../system/hardware/amd.nix
    ../system/hardware/nvidia.nix
    ../system/hardware/acpid.nix
  ];
  hardware.enableRedistributableFirmware = true;

  boot.loader = {
    # systemd-boot = {
    #   enable = true;
    #   configurationLimit = 5;
    # };
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
    grub = {
      devices = [ "/dev/nvme0n1" ];
      efiSupport = true;
      enable = true;
      version = 2;
      useOSProber = true;
      copyKernels = true;
      configurationLimit = 5;
      zfsSupport = true;
    };
  };

  fileSystems."/" = {
    device = "ZROOT/encrypted/root/nixos";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "ZROOT/encrypted/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4B33-4EFB";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.hostName = "cherry"; # Define your hostname.
  networking.hostId = "c667a86a";
  networking.interfaces.wlp2s0.useDHCP = true;

}
