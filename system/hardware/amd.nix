{
  config,
  pkgs,
  nixpkgs,
  lib,
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
        # tests are broken when running on zfs
        gitMinimal = prev.gitMinimal.override {
          doInstallCheck = false;
        };
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
            pyrate-limiter = pyprev.pyrate-limiter.overrideAttrs (old: {
              pytestCheckPhase = "true";
            });
          };
        };
        python3Packages = python3.pkgs;
        sphinx = python3Packages.sphinx;
        jq = pkgs.jq;
        lzip = prev.lzip.overrideAttrs (old: {
          doCheck = false;
        });
        coreutils = prev.coreutils.overrideAttrs (old: {
          doCheck = false;
        });
        go = prev.go.overrideAttrs (old: {
          doCheck = false;
        });
      })
    ];
  };

  autofdo-kernel = pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.override (old: {
    autofdo = ../../kernel.afdo;
  });
in {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amd_pstate" "kvm_amd" "cpuid" "i2c-dev" "zenpower" "corefreqk"];
  boot.kernelParams = ["amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=active" "usbcore.autosuspend=-1"];
  boot.kernelPackages = lib.mkForce (pkgs.mkCachyPackageSet autofdo-kernel);
  # boot.extraModulePackages = with config.boot.kernelPackages; [CoreFreq];
  # boot.kernelPackages = pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4;
  # boot.kernelPackages = pkgs-optimized.linuxKernel.packagesFor (let
  #   version = "6.17.3";
  #   isLTS = false;
  #   suffix = "xanmod1";
  #   hash = "sha256-VL1SCMB89P0UcCbtPdkjxcCZqQZpnSTlzzf9e8uzkyA=";
  # in
  #   with pkgs;
  #     pkgs-optimized.linuxKernel.buildLinux rec {
  #       inherit version;
  #       pname = "linux-xanmod";
  #       modDirVersion = lib.versions.pad 3 "${version}-${suffix}";

  #       src = fetchFromGitLab {
  #         owner = "xanmod";
  #         repo = "linux";
  #         rev = modDirVersion;
  #         inherit hash;
  #       };

  #       structuredExtraConfig = with lib.kernel; {
  #         # CPUFreq governor Performance
  #         CPU_FREQ_DEFAULT_GOV_PERFORMANCE = lib.mkOverride 60 yes;
  #         CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = lib.mkOverride 60 no;

  #         # Full preemption
  #         PREEMPT = lib.mkOverride 60 yes;
  #         PREEMPT_VOLUNTARY = lib.mkOverride 60 no;

  #         # Google's BBRv3 TCP congestion Control
  #         TCP_CONG_BBR = yes;
  #         DEFAULT_BBR = yes;

  #         # Preemptive Full Tickless Kernel at 250Hz
  #         HZ = freeform "250";
  #         HZ_250 = yes;
  #         HZ_1000 = no;

  #         # RCU_BOOST and RCU_EXP_KTHREAD
  #         RCU_EXPERT = yes;
  #         RCU_FANOUT = freeform "64";
  #         RCU_FANOUT_LEAF = freeform "16";
  #         RCU_BOOST = yes;
  #         RCU_BOOST_DELAY = freeform "0";
  #         RCU_EXP_KTHREAD = yes;
  #       };

  #       inherit isLTS;
  #     });

  boot.kernelPatches = [
    {
      name = "lact-max-clocks";
      patch = pkgs.fetchpatch {
        url = "https://gitlab.com/fpsflow/power_limit_removal/-/raw/main/highest_clocks.patch";
        sha256 = "sha256-vUW9N6urYbDOSpcHqkmAb2UY18FphkUl/oO8lIxvVxs=";
      };
    }
    # pkgs-optimized.linuxKernel.kernelPatches.bridge_stp_helper
    # pkgs-optimized.linuxKernel.kernelPatches.request_key_helper
  ];

  environment.systemPackages = [pkgs.lact];
  programs.corefreq.enable = true;
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
    # settings = {
    #   daemon = {
    #     log_level = "info";
    #     admin_group = "wheel";
    #   };
    #   gpus = {
    #     "1002:7550-1ED3:8900-0000:03:00.0" = {
    #       voltage_offset = -50;
    #       max_memory_clock = 1614;
    #       pmfw_options = {
    #         zero_rpm = false;
    #       };
    #       power_cap = 340.0;
    #     };
    #   };
    # };
  };
  hardware.amdgpu = {
    opencl.enable = true;
    overdrive.enable = true;
    initrd.enable = true;
  };
}
