{
  config,
  pkgs,
  lib,
  ...
}: let
  autofdo-kernel = pkgs.cachyosKernels.linux-cachyos-rc-lto.override (old: {
    autofdo = ../../kernel.afdo;
    processorOpt = "zen4";
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
  decodeMbox = pkgs.writeShellScript "decodeMbox" ''
    # The lore.kernel.org mailing list uses public-inbox, which supports
    # downloading threads as a gzip-compressed mbox file (see the "mbox.gz" link
    # next to "Thread overview"). This can be used to download a patch series in
    # a single file. However, public-inbox may not sort the messages in the
    # thread [1], which may break application of the patches. b4 am [2] can be
    # used to sort patches in the mbox file and produce a patch that can be
    # applied with git am or patch.
    # [1]: https://public-inbox.org/meta/20240411-dancing-pink-marmoset-f442d0@meerkat/
    # [2]: https://b4.docs.kernel.org/en/latest/maintainer/am-shazam.html
    # b4 expects git to be in $PATH and $XDG_DATA_HOME to be writable.
    export PATH="${lib.makeBinPath [pkgs.gitMinimal]}:$PATH"
    export XDG_DATA_HOME="$(mktemp -d)"
    gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
  '';
  # corefreq = config.boot.kernelPackages.corefreq.overrideAttrs (old: {
  #   version = "2.1.1";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "cyring";
  #     repo = "CoreFreq";
  #     rev = "develop/next";
  #     sha256 = "sha256-JxvV7r5f9txmnnIBhwAk6q9A81RyAfr+PjOc03OEdsQ=";
  #   };
  # });
in {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amd_pstate" "kvm_amd" "cpuid" "i2c-dev" "zenpower" "corefreqk"];
  boot.kernelParams = ["amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=active" "usbcore.autosuspend=-1"];
  boot.kernelPackages = lib.mkForce (kernelModuleLLVMOverride (pkgs.mkCachyPackageSet autofdo-kernel));
  boot.extraModulePackages = with config.boot.kernelPackages; [zenpower];

  boot.kernelPatches = [
    {
      name = "lact-max-clocks";
      patch = pkgs.fetchpatch {
        url = "https://gitlab.com/fpsflow/power_limit_removal/-/raw/main/highest_clocks.patch";
        sha256 = "sha256-8/pT7mReiGJILVBbgyMl6zqPCurlxI0+EEnEIYHezfI=";
      };
    }
    {
      name = "[PATCH v2 0/3] Fixes for flip_done timeouts";
      patch = pkgs.fetchpatch {
        url = "https://lore.kernel.org/amd-gfx/20260519220529.202096-1-sunpeng.li@amd.com/t.mbox.gz";
        hash = "sha256-+AAisd7COhTkUGXnZHWHNgSd5gjGAqC70nXKAIijwmY=";
        decode = decodeMbox;
      };
    }
  ];

  environment.systemPackages = with pkgs; [lact perf autofdo-profile];
  # programs.corefreq = {
  #   enable = true;
  #   package = corefreq;
  # };
  services.xserver.deviceSection = ''Option "TearFree" "true"'';
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    package = pkgs.scx.rustscheds;
  };

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "powersave";
  services.auto-epp = {
    enable = true;
    settings.Settings = {
      epp_state_for_AC = "balance_performance";
      epp_state_for_BAT = "balance_performance";
    };
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
