{ config, lib, pkgs, nixpkgs-optimized, ... }:
let
  pkgs-local = import nixpkgs-optimized {
    config.allowUnfree = true;
    system = "x86_64-linux";
  };
  # we really only want to use this for the kernel itself to minimize which packages that have to be built locally
  pkgs-optimized = import nixpkgs-optimized {
    config.allowUnfree = true;
    localSystem = {
      gcc.arch = "znver3";
      gcc.tune = "znver3";
      system = "x86_64-linux";
    };
  };
in
{
  # ensure gccarch-znver3 is in the system features so we can use it to build the kernel
  nix.extraOptions = ''
    system-features = gccarch-znver3 kvm nixos-test big-parallel benchmark
  '';
  boot.initrd.availableKernelModules =
    [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "amd_pstate" "kvm_amd" "cpuid" "i2c-dev" ];
  boot.kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate.shared_mem=1" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
  boot.kernelPackages = pkgs-local.linuxKernel.packagesFor
    (pkgs-optimized.linuxKernel.kernels.linux_xanmod_tt.override {
      stdenv = pkgs-local.gcc12Stdenv;
      ignoreConfigErrors = true;
    });
  boot.kernelPatches = [
    {
      name = "add-cpu-config";
      patch = null;
      extraConfig = ''
        CONFIG_GENERIC_CPU n
        CONFIG_LOCALVERSION -znver3
        CONFIG_MZEN3 y
      '';
    }
  ];

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "ondemand";

  services.acpid.handlers = {
    brightness-down = {
      event = "video/brightnessdown";
      action = ''
        #!${pkgs.bash}/bin/bash
        bl=$(brightnessctl -l | grep amd | cut -d' ' -f 3)
        ${pkgs.brightnessctl}/bin/brightnessctl -d $bl s 5%-
        raw=$(${pkgs.brightnessctl}/bin/brightnessctl -d $bl g)
        perc=$(${pkgs.bc}/bin/bc <<< "scale=4; 100*$raw/255")
        /run/wrappers/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i display-brightness-symbolic.symbolic -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
    brightness-up = {
      event = "video/brightnessup";
      action = ''
        #!${pkgs.bash}/bin/bash
        bl=$(brightnessctl -l | grep amd | cut -d' ' -f 3)
        ${pkgs.brightnessctl}/bin/brightnessctl -d $bl s 5%+
        raw=$(${pkgs.brightnessctl}/bin/brightnessctl -d $bl g)
        perc=$(${pkgs.bc}/bin/bc <<< "scale=4; 100*$raw/255")
        /run/wrappers/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i display-brightness-symbolic.symbolic -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
  };
}
