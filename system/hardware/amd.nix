{
  config,
  pkgs,
  nixpkgs,
  lib,
  ...
}: let
  autofdo-kernel = pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.override (old: {
    autofdo = ../../kernel.afdo;
  });

  perf = pkgs.perf.overrideAttrs (old: {
    version = pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.version;
    src = pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.src;
  });

  autofdo-profile = pkgs.writeScriptBin "autofdo-profile" ''
    #!${pkgs.runtimeShell}
    WORKING_DIR=$(mktemp -d)
    sudo sh -c "echo 0 > /proc/sys/kernel/kptr_restrict"
    sudo sh -c "echo 0 > /proc/sys/kernel/perf_event_paranoid"

    perf record -e cpu/event=0xc4,umask=0x0,name=br_inst_retired.taken/ -a -N -b -c 500009 -o $WORKING_DIR/kernel.data -- time sh -c "nix build nixpkgs#linux_xanmod_latest --rebuild --log-format internal-json -v |& nom --json"

    ${pkgs.llvm}/bin/llvm-profgen --kernel --binary=${config.boot.kernelPackages.kernel.dev}/vmlinux --perfdata=$WORKING_DIR/kernel.data -o /home/cassandra/src/github.com/cassandracomar/nix-config/kernel.afdo
  '';
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
in {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amd_pstate" "kvm_amd" "cpuid" "i2c-dev" "zenpower" "corefreqk"];
  boot.kernelParams = ["amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=active" "usbcore.autosuspend=-1"];
  boot.kernelPackages = lib.mkForce (pkgs.mkCachyPackageSet autofdo-kernel);
  boot.extraModulePackages = with config.boot.kernelPackages; [zenpower];

  boot.kernelPatches = [
    {
      name = "lact-max-clocks";
      patch = pkgs.fetchpatch {
        url = "https://gitlab.com/fpsflow/power_limit_removal/-/raw/main/highest_clocks.patch";
        sha256 = "sha256-vUW9N6urYbDOSpcHqkmAb2UY18FphkUl/oO8lIxvVxs=";
      };
    }
    {
      name = "amdgpu-hdmi-vrr";
      patch = pkgs.fetchpatch {
        url = "https://lore.kernel.org/lkml/20260203185626.55428-1-tomasz.pakula.oficjalny@gmail.com/t.mbox.gz";
        hash = "sha256-fMzveDZinJM5MM/U+lchGqknNcQFYT2h7kdkYkeYEYs=";
        decode = decodeMbox;
      };
    }
  ];

  environment.systemPackages = [pkgs.lact perf autofdo-profile];
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
  };
  hardware.amdgpu = {
    opencl.enable = true;
    overdrive.enable = true;
    initrd.enable = false;
  };
}
