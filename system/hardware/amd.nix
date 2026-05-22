{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  autofdo-kernel = (pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.override
    (old: {
      autofdo = ../../kernel.afdo;
      modDirVersion = "7.0.1-cachyos-lto";
      version = "7.0.1";
    })).overrideAttrs (old: {
    version = "7.0.1";
    src = pkgs.fetchurl {
      url = "https://github.com/CachyOS/linux/releases/download/cachyos-7.0.1-2/cachyos-7.0.1-2.tar.gz";
      sha256 = "sha256-+wR9fJQy0/iO8GcYOpw3UcZSPK3QKb4Rqtq1akSAGfg=";
    };
  });

  perf = pkgs.perf.overrideAttrs (old: {
    version = config.boot.kernelPackages.kernel.version;
    src = config.boot.kernelPackages.kernel.src;
  });

  autofdo-profile = pkgs.writeScriptBin "autofdo-profile" ''
    #!${pkgs.runtimeShell}
    WORKING_DIR=$(mktemp -d)
    sudo sh -c "echo 0 > /proc/sys/kernel/kptr_restrict"
    sudo sh -c "echo 0 > /proc/sys/kernel/perf_event_paranoid"

    perf record -e cpu/event=0xc4,umask=0x0,name=br_inst_retired.taken/ -a -N -b -c 500009 -o $WORKING_DIR/kernel.data -- time sh -c "nix build nixpkgs#linux_xanmod_latest --rebuild --log-format internal-json -v |& nom --json"

    ${pkgs.llvm}/bin/llvm-profgen --kernel --binary=${config.boot.kernelPackages.kernel.dev}/vmlinux --perfdata=$WORKING_DIR/kernel.data -o /home/cassandra/src/github.com/cassandracomar/nix-config/kernel.afdo
  '';

  kernelModuleLLVMOverride = kernelPackages_:
    kernelPackages_.extend (
      _final: prev:
        lib.mapAttrs (
          n: v:
            if
              builtins.elem "LLVM=1" kernelPackages_.kernel.commonMakeFlags
              && !(builtins.elem n ["kernel"])
              && lib.isDerivation v
              && ((v.overrideAttrs or null) != null)
            then
              v.overrideAttrs (old: {
                makeFlags = (old.makeFlags or []) ++ kernelPackages_.kernel.commonMakeFlags;
                postPatch =
                  (
                    if (old.postPatch or null) == null
                    then ""
                    else old.postPatch
                  )
                  + ''
                    if [ -f Makefile ]; then
                      substituteInPlace Makefile --replace "gcc" "cc"
                    fi
                  '';
              })
            else v
        )
        prev
    );
in {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amd_pstate" "kvm_amd" "cpuid" "i2c-dev" "zenpower" "corefreqk"];
  boot.kernelParams = ["amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=active" "usbcore.autosuspend=-1"];
  boot.kernelPackages = lib.mkForce (kernelModuleLLVMOverride (pkgs.mkCachyPackageSet autofdo-kernel));
  boot.extraModulePackages = with config.boot.kernelPackages; [zenpower];

  boot.kernelPatches = [
    # {
    #   name = "lact-max-clocks";
    #   patch = pkgs.fetchpatch {
    #     url = "https://gitlab.com/fpsflow/power_limit_removal/-/raw/main/highest_clocks.patch";
    #     sha256 = "sha256-vUW9N6urYbDOSpcHqkmAb2UY18FphkUl/oO8lIxvVxs=";
    #   };
    # }
  ];

  environment.systemPackages = [pkgs.lact perf autofdo-profile];
  programs.corefreq = {
    enable = true;
    package = config.boot.kernelPackages.corefreq;
  };
  services.xserver.deviceSection = ''Option "TearFree" "true"'';
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    package = pkgs.scx.rustscheds;
  };

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "powersave";
  services.auto-epp = {
    enable = true;
    settings.Settings.epp_state_for_AC = "balance_performance";
  };

  services.lact = {
    enable = true;
  };
  hardware.amdgpu = {
    opencl.enable = true;
    overdrive.enable = true;
    initrd.enable = false;
  };
}
