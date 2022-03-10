{ config, lib, pkgs, ... }:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in {
  environment.systemPackages = [ nvidia-offload ];
  boot.kernelParams = [
    "nvidia.NVreg_DynamicPowerManagement=0x02"
    # "nvidia.NVreg_EnableBacklightHandler=0"
  ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaPersistenced = true;

    modesetting.enable = true;
    prime = {
      offload.enable = true;
      # sync.enable = true;

      # Bus ID of the AMD GPU. You can find it using lspci, either under 3D or VGA
      amdgpuBusId = "PCI:5:0:0";

      # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource NVIDIA-G0 "Unknown AMD Radeon GPU @ pci:0000:05:00.0"
  '';
  services.xserver.drivers = [
    {
      name = "amdgpu";
      display = config.hardware.nvidia.prime.offload.enable;
      modules = [ pkgs.xorg.xf86videoamdgpu ];
      deviceSection = ''
        BusID "${config.hardware.nvidia.prime.amdgpuBusId}"
      '';
    }
    {
      name = "nvidia";
      modules = [ config.hardware.nvidia.package.bin ];
      display = !config.hardware.nvidia.prime.offload.enable;
      deviceSection = ''
        BusID "${config.hardware.nvidia.prime.nvidiaBusId}"
        ${lib.optionalString config.hardware.nvidia.powerManagement.finegrained
        ''Option "NVreg_DynamicPowerManagement=0x02"''}
      '';
      screenSection = ''
        Option "RandRRotation" "on"
        ${lib.optionalString config.hardware.nvidia.prime.sync.enable
        ''Option "AllowEmptyInitialConfiguration"''}
      '';
    }
  ];

  specialisation.nvida-sync.configuration = {
    system.nixos.tags = [ "nvidia-sync" ];
    hardware.nvidia = {
      prime.offload.enable = lib.mkForce false;
      prime.sync.enable = lib.mkForce true;
      powerManagement.enable = lib.mkForce false;
      powerManagement.finegrained = lib.mkForce false;
    };
    hardware.opengl = {
      package = lib.mkForce pkgs.mesa.drivers;
      package32 = lib.mkForce pkgs.pkgsi686Linux.mesa.drivers;
      extraPackages = [ (pkgs.hiPrio config.hardware.nvidia.package.out) ];
      extraPackages32 = [ (pkgs.hiPrio config.hardware.nvidia.package.lib32) ];
    };
    services.xserver.displayManager.sessionCommands = lib.mkForce ''
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource "Unknown AMD Radeon GPU @ pci:0000:05:00.0" NVIDIA-0
    '';
  };
}
