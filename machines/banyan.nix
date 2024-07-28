{ self, lib, pkgs, ... }:
let
  fsTypes = ["f2fs" "ext4" "ext" "exfat" "vfat"];
  # nanopi-r5c-firmware = pkgs.stdenv.mkDerivation rec {
  #   name = "nanopi-r5c-firmware";
  #   version = "12.0.3";
  #   src = pkgs.fetchurl {
  #     url = "https://github.com/inindev/nanopi-r5/releases/download/v${version}/rk3568-nanopi-r5c.dtb";
  #     hash = "0f39zk0zy5cim3sk3ibrjmy5q8yzwhzwhgc8879w04iyv8ydyvli";
  #   };
  #   # srcs = [
  #   #   (pkgs.fetchurl {
  #   #     url = "https://github.com/inindev/nanopi-r5/releases/download/v${version}/rk3568-nanopi-r5c.dtb";
  #   #     hash = "0f39zk0zy5cim3sk3ibrjmy5q8yzwhzwhgc8879w04iyv8ydyvli";
  #   #   })
  #   #   (pkgs.fetchurl {
  #   #     url = "https://github.com/inindev/nanopi-r5/releases/download/v${version}/idbloader-r5c.img";
  #   #     hash = "1xbas0as782x4yzqdb6p19rx3wcr8f5nvnw267cccnv1ajp2j0bi";
  #   #   })
  #   #   (pkgs.fetchurl {
  #   #     url = "https://github.com/inindev/nanopi-r5/releases/download/v${version}/u-boot-r5c.itb";
  #   #     hash = "058zwdniw5fpsxms3hzwdv6xal6rp3mbj8rfl1slh2p0vinqczsd";
  #   #   })
  #   # ];
  #   dontConfigure = true;
  #   dontBuild = true;

  #   installPhase = ''
  #     mkdir -p $out
  #     cp *-r5c.{dtb,img,itb} $out
  #   '';
  # };

  # bl31 = pkgs.buildArmTrustedFirmware rec {
  #   extraMakeFlags = [ "bl31" ];
  #   platform = "rk3568";
  #   extraMeta.platforms = ["aarch64-linux"];
  #   filesToInstall = [ "build/${platform}/release/bl31/bl31.elf"];
  #   platformCanUseHDCPBlob = true;
  # };

  patchFn = c: pkgs.fetchurl {
    url = "https://github.com/u-boot/u-boot/commit/${c.commit}.patch";
    # hash = c.hash;
    sha256 = c.hash;
  };
  u-boot-patches = map patchFn [
    # pci: pcie_dw_rockchip: Configure number of lanes and link width speed
    # https://github.com/u-boot/u-boot/commit/9af0c7732bf1df29138bb63712dc3fcbc6d821af
    { commit = "9af0c7732bf1df29138bb63712dc3fcbc6d821af"; hash = "1hfp7waiimk8z666cisczh5m9jzbk535gl3330n7r3llihzc4kg6"; }

    # phy: rockchip: snps-pcie3: Refactor to use clk_bulk API
    # https://github.com/u-boot/u-boot/commit/3b39592e8e245fc5c7b0a003ac65672ce9cfaf0f
    { commit = "3b39592e8e245fc5c7b0a003ac65672ce9cfaf0f"; hash = "1w1n48p8zwqnjq8nbbryf27yxqkvjbxnibxjyxjvsmzms2cz56gi"; }

    # phy: rockchip: snps-pcie3: Refactor to use a phy_init ops
    # https://github.com/u-boot/u-boot/commit/6cacdf842db5e62e9c26d015eddadd2f2410a6de
    { commit = "6cacdf842db5e62e9c26d015eddadd2f2410a6de"; hash = "1fngcizkws6y01nf02qx46qjf0ngyl144ak3bbxpdrb7xm5zh3m9"; }

    # phy: rockchip: snps-pcie3: Add bifurcation support for RK3568
    # https://github.com/u-boot/u-boot/commit/1ebebfcc25bc8963cbdc6e35504160e5b745cabd
    { commit = "1ebebfcc25bc8963cbdc6e35504160e5b745cabd"; hash = "1m53c0xr0gis6afx2z9svn52pqyx10nd2hpf62vb6l2a9j86g23n"; }

    # phy: rockchip: naneng-combphy: Use signal from comb PHY on RK3588
    # https://github.com/u-boot/u-boot/commit/b37260bca1aa562c6c99527d997c768a12da017b
    { commit = "b37260bca1aa562c6c99527d997c768a12da017b"; hash = "07ab01jx54lqmgz61vvfd0rq29y201m3frffj3lkpfigpky3rynr"; }

    # rockchip: rk3568-nanopi-r5: Update defconfig for NanoPi R5C and R5S
    # https://github.com/u-boot/u-boot/commit/5b155997d445f770e9a2c0d4a20e4eb13eedfede
    { commit = "5b155997d445f770e9a2c0d4a20e4eb13eedfede"; hash = "15303dmm22y8f8rxr2m7vmbc68yzs1dif9dw29s3yy7x7rv170kl"; }

    # rockchip: rk3568-nanopi-r5: Enable PCIe on NanoPi R5C and R5S
    # https://github.com/u-boot/u-boot/commit/a9e9445ea2bb010444621e563a79bc33fe064f9c
    { commit = "a9e9445ea2bb010444621e563a79bc33fe064f9c"; hash = "0ia6czpvql2ii99366w8vmg1dvrrf03d4kcjkn9pxxx437lqzn6x"; }

    # power: regulator: Only run autoset once for each regulator
    # https://github.com/u-boot/u-boot/commit/d99fb64a98af3bebf6b0c134291c4fb89e177aa2
    { commit = "d99fb64a98af3bebf6b0c134291c4fb89e177aa2"; hash = "1vi58sn7jlr2pf90znqxx2n372z6cy2yz0sadnpnvflf9xffpmii"; }

    # regulator: rk8xx: Return correct voltage for buck converters
    # https://github.com/u-boot/u-boot/commit/04c38c6c4936f353de36be60655f402922292a37
    { commit = "04c38c6c4936f353de36be60655f402922292a37"; hash = "0pcy0ni4y4sav7cnbrh4spigk260yn9hab3vhh52j9pcbcqzjcyl"; }

    # regulator: rk8xx: Return correct voltage for switchout converters
    # https://github.com/u-boot/u-boot/commit/bb657ffdd688dc08073734a402914ec0a8492d53
    { commit = "bb657ffdd688dc08073734a402914ec0a8492d53"; hash = "1kwn1098fpmrrmmij0q27mznyf95vy3ip8s6nfljmp7rsj2q27s6"; }
  ];

  u-boot-r5c = (pkgs.buildUBoot {
    defconfig = "nanopi-r5c-rk3568_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = pkgs.rkbin.BL31_RK3568;
    ROCKCHIP_TPL = pkgs.rkbin.TPL_RK3568;
    filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
    extraPatches = u-boot-patches;

    version = "2023.10";
    src = pkgs.fetchFromGitHub {
      owner = "u-boot";
      repo = "u-boot";
      rev = "v2023.10";
      sha256 = "sha256-f0xDGxTatRtCxwuDnmsqFLtYLIyjA5xzyQcwfOy3zEM=";
    };
  });
  linuxPackages = pkgs.linuxKernel.hardenedPackagesFor pkgs.linux_6_9 {};
in {config, modulesPath, ...}:
let
  r5c-dtb = "${config.system.build.toplevel}/dtbs/rockchip/rk3568-nanopi-r5c.dtb";
in {
  imports = [
    # "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/installer/sd-card/sd-image.nix"
    "${self.inputs.nixos-hardware}/friendlyarm/nanopi-r5c"
    "${modulesPath}/profiles/minimal.nix"
  ];

  formatAttr = "sdImage";
  sdImage = {
    firmwarePartitionOffset = 16;
    populateFirmwareCommands = let
      configTxt = pkgs.writeText "config.txt" ''
        # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
        # when attempting to show low-voltage or overtemperature warnings.
        avoid_warnings=1

        [r5c]
        kernel=u-boot-rockchip.bin
      '';
    in lib.mkForce ''
        cp ${u-boot-r5c}/u-boot-rockchip.bin firmware/
        cp ${configTxt} firmware/config.txt
      '';
    populateRootCommands = lib.mkForce ''
        mkdir -p ./files/boot
        cp ${r5c-dtb} ./files/boot/rk3568-nanopi-r5c.dtb
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot -n ${config.hardware.deviceTree.name}
      '';
    postBuildCommands = lib.mkForce ''
      ${pkgs.gptfdisk}/bin/sgdisk -g $img
      ${pkgs.busybox}/bin/sync

      dd bs=4k seek=8 if=${u-boot-r5c}/u-boot.itb of=$img conv=notrunc
      dd bs=4k seek=2048 if=${u-boot-r5c}/idbloader.img of=$img conv=notrunc,fsync
    '';
    compressImage = false;
  };

  boot.kernelPackages = linuxPackages;
  boot.supportedFilesystems = lib.mkForce fsTypes;
  boot.initrd.supportedFilesystems = lib.mkForce fsTypes;
  system.stateVersion = "24.05";
  environment.noXlibs = lib.mkForce true;
}
