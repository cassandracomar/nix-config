{
  config,
  pkgs,
  # lib,
  nixpkgs,
  ...
}: let
  # we really only want to use this for the kernel itself to minimize which packages that have to be built locally
  pkgs-optimized = import nixpkgs {
    config.allowUnfree = true;
    localSystem = {
      gcc.arch = "znver4";
      gcc.tune = "znver4";
      system = "x86_64-linux";
    };
    overlays = [
      (final: prev: rec {
        python3 = prev.python3.override {
          packageOverrides = pyfinal: pyprev: {
            pycparser = pyprev.pycparser.overrideAttrs (old: {
              unittestCheckPhase = "true";
            });
            sphinx = pyprev.sphinx.overrideAttrs (old: {
              pytestCheckPhase = "true";
              unittestCheckPhase = "true";
              pythonImportsCheckPhase = "true";
            });
          };
        };
        python3Packages = python3.pkgs;
        sphinx = python3Packages.sphinx;
        jq = pkgs.jq;
      })
    ];
  };

  CoreFreq = pkgs.callPackage ../../packages/corefreq.nix {kernelPackage = config.boot.kernelPackages.kernel;};
in {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amd_pstate" "kvm_amd" "cpuid" "i2c-dev" "zenpower" "corefreqk"];
  boot.kernelParams = ["amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=active"];
  boot.extraModulePackages = with config.boot.kernelPackages; [zenpower CoreFreq];
  boot.kernelPackages = pkgs-optimized.linuxKernel.packagesFor pkgs-optimized.linuxKernel.kernels.linux_xanmod_latest;

  environment.systemPackages = [CoreFreq pkgs.lact];
  services.dbus.packages = [CoreFreq];
  systemd.services.corefreqd = {
    description = "CoreFreq Daemon";
    wantedBy = ["multi-user.target"];
    restartIfChanged = true;

    serviceConfig = {
      ExecStart = "${CoreFreq}/bin/corefreqd -q";
      ExecStop = "${pkgs.coreutils}/bin/kill -QUIT $MAINPID";
      SuccessExitStatus = "SIGQUIT SIGUSR1 SIGTERM";
      RemainAfterExit = "no";
      Restart = "always";
      Slice = "-.slice";
    };
  };
  services.xserver.deviceSection = ''Option "TearFree" "true"'';
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "powersave";
  services.auto-epp = {
    enable = true;
    settings.Settings.epp_state_for_AC = "balance_power";
  };

  services.lact = {
    enable = true;
  };
  hardware.graphics = {
    amdgpu.amdvlk = {
        enable = true;
        support32Bit.enable = true;
    };
  };
}
