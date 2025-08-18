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
      })
    ];
  };

  CoreFreq = pkgs.callPackage ../../packages/corefreq.nix {kernelPackage = config.boot.kernelPackages.kernel;};
in {
  # ensure gccarch-znver3 is in the system features so we can use it to build the kernel
  nix.extraOptions = ''
    system-features = gccarch-znver4 kvm nixos-test big-parallel benchmark
  '';
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amd_pstate" "kvm_amd" "cpuid" "i2c-dev" "zenpower" "corefreqk"];
  boot.kernelParams = ["amdgpu.backlight=0" "acpi_backlight=video" "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=active"];
  boot.extraModulePackages = with config.boot.kernelPackages; [zenpower CoreFreq];
  boot.kernelPackages = pkgs-optimized.linuxKernel.packagesFor pkgs-optimized.linuxKernel.kernels.linux_xanmod_latest;

  environment.systemPackages = [CoreFreq];
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
    scheduler = "rustland";
  };

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "performance";

  services.acpid.handlers = {
    brightness-down = {
      event = "video/brightnessdown";
      action = ''
        #!${pkgs.bash}/bin/bash
        bl=$(brightnessctl -l | grep amdgpu | cut -d' ' -f 2 | cut -d"'" -f 2)
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
        bl=$(brightnessctl -l | grep amdgpu | cut -d' ' -f 2 | cut -d"'" -f 2)
        ${pkgs.brightnessctl}/bin/brightnessctl -d $bl s 5%+
        raw=$(${pkgs.brightnessctl}/bin/brightnessctl -d $bl g)
        perc=$(${pkgs.bc}/bin/bc <<< "scale=4; 100*$raw/255")
        /run/wrappers/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i display-brightness-symbolic.symbolic -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
  };
}
