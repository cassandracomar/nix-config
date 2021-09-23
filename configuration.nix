# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:
let
  nixpkgs = (import <nixpkgs> { });
  iosevkaCustom = nixpkgs.iosevka.override {
    privateBuildPlan = {
      family = "Iosevka Custom";
      design =
        [ "ligset-haskell" "ligset-clike" "ligset-javascript" "ligset-swift" ];

    };
    set = "custom";
  };
in {

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports = [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    /etc/nixos/cachix.nix
  ];

  # allow unfree
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverides = pkgs:
    with pkgs; {
      steam = steam.override {
        nativeOnly = true;
        extraLibraries = [ pipewire.lib networkmanager ];
        extraPkgs = [ pipewire.lib ];
      };
      nur = import (builtins.fetchTarball
        "https://github.com/nix-community/NUR/archive/master.tar.gz") {
          inherit pkgs;
        };
    };

  # set the kernel version
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;

  # set ZFS options
  boot.supportedFilesystems =
    [ "zfs" "f2fs" "ext4" "xfs" "cifs" "vfat" "ntfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  boot.zfs.enableUnstable = true;

  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  # networking.interfaces.enp0s13f0u1u3.useDHCP = false;
  # networking.interfaces.enp0s13f0u1u3.ipv4.addresses = [{
  #   address = "192.168.1.10";
  #   prefixLength = 24;
  # }];
  #networking.interfaces.vethc1c7b69.useDHCP = true;
  networking.networkmanager.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-232n";
    earlySetup = true;
    packages = with pkgs; [ terminus_font ];
  };

  # set up other fonts
  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    fontconfig = { enable = true; };

    fonts = with pkgs; [
      ubuntu_font_family
      iosevkaCustom
      inconsolata
      inconsolata-lgc
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      dejavu_fonts
      powerline-fonts
      corefonts
      symbola
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
      arphic-ukai
      arphic-uming
      font-awesome-ttf
      noto-fonts-extra
      source-han-sans-japanese
      source-han-sans-korean
      source-han-sans-simplified-chinese
      source-han-sans-traditional-chinese
      wqy_microhei
      wqy_zenhei
    ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    htop
    ripgrep
    zsh
    git
    tmux
    xorg.xbacklight
    pamixer
    pavucontrol
    brightnessctl
    bc
    gnupg
    pinentry-curses
    paperkey
    virt-manager
    pulseeffects-legacy
    p7zip
    unrar
    unzip
    thunderbolt
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.extraConfig = ''
    load-module module-alsa-sink device=hw:0,0 channels=4
    load-module module-alsa-source device=hw:0,6 channels=4
    load-module module-echo-cancel aec_method='webrtc'
  '';
  hardware.pulseaudio.daemon.config = { resample-method = "speex-float-10"; };
  services.jack = {
    jackd.enable = true;
    # support ALSA only programs via ALSA JACK PCM plugin
    alsa.enable = false;
    # support ALSA only programs via loopback device (supports programs like Steam)
    loopback = {
      enable = true;
      # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
      #dmixConfig = ''
      #  period_size 2048
      #'';
    };
  };
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   jack.enable = true;
  #   pulse.enable = true;
  #   socketActivation = true;
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  #services.xserver.xkbOptions = "eurosign:e";

  services.xserver = {
    deviceSection = ''
      Option "TearFree" "true"
    '';
    # Enable touchpad support.
    libinput = {
      enable = true;
      clickMethod = "clickfinger";
      naturalScrolling = true;
      additionalOptions = ''MatchIsTouchpad "on"'';
    };

    # set up the display manager
    displayManager = {
      lightdm = {
        enable = true;

      };
      autoLogin = {
        enable = true;
        user = "cassandra";
      };
    };
    displayManager.defaultSession = "none+xsession";

    # set up the session
    windowManager.session = lib.singleton {
      name = "xsession";
      start = pkgs.writeScript "xsession" ''
        #!${pkgs.runtimeShell}
        if test -f $HOME/.xsession; then
          exec ${pkgs.runtimeShell} -c $HOME/.xession
        else
          echo "No xession script found"
        fi
      '';
    };

    wacom.enable = true;
  };

  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    libvdpau-va-gl
    vaapiVdpau
    intel-ocl
    pipewire
    pulseaudioFull
  ];
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [
    vaapiIntel
    libvdpau-va-gl
    vaapiVdpau
    pipewire
    pulseaudioFull
  ];
  services.picom.enable = true;
  services.picom.backend = "glx";
  services.picom.vSync = true;
  services.picom.shadowOpacity = 1.0;

  services.tlp = { enable = true; };
  services.acpid.enable = true;
  powerManagement.enable = true;
  powerManagement.powertop.enable = false;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cassandra = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "sound"
      "docker"
      "libvirtd"
      "transmission"
      "jackaudio"
    ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };
  nix.trustedUsers = [ "root" "cassandra" ];

  users.users.root = { shell = pkgs.zsh; };

  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    %wheel	ALL=(ALL:ALL)	NOPASSWD:	ALL
  '';

  programs.zsh.enable = true;
  programs.java.enable = true;

  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.fwupd.enable = true;
  services.autorandr.enable = true;

  services.openvpn.servers = {
    perfect-privacy-montreal = {
      config = "config /var/lib/vpns/perfect-privacy/Montreal.conf";
      updateResolvConf = true;
      autoStart = false;
    };
  };
  environment.etc.openvpn.source = pkgs.update-resolv-conf;
  networking.resolvconf.extraConfig = ''
    name_server='8.8.8.8'
  '';

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "overlay2";
      extraOptions = ''
        --bip 172.16.0.100/24
      '';
    };
    libvirtd.enable = true;
  };
  programs.dconf.enable = true;

  services.transmission = { enable = true; };

  nix.autoOptimiseStore = true;
  programs.bash.enableCompletion = true;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "16382";
  }];

  programs.steam.enable = true;
  services.unifi.enable = true;
  services.tailscale.enable = true;
  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up
    '';
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

