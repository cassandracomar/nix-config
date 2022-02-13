# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ pkgs, config, ... }: {
  imports = [
    ../system/hardware/amd.nix
    ../system/hardware/nvidia.nix
    ../system/hardware/acpid.nix
  ];

  fileSystems."/" = {
    device = "ZROOT/root/nixos";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "ZROOT/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4B33-4EFB";
    fsType = "vfat";
  };

  fileSystems."/var/lib/docker" = {
    device = "/dev/disk/by-uuid/d5776456-15a8-4338-b98a-cb5d7e435551";
    fsType = "ext4";
  };
  swapDevices = [ ];

  networking.hostName = "cherry"; # Define your hostname.
  networking.hostId = "c667a86a";
  networking.interfaces.wlp2s0.useDHCP = true;

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource NVIDIA-G0 "Unknown AMD Radeon GPU @ pci:0000:05:00.0"
  '';

}
