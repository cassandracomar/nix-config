{
  config,
  lib,
  pkgs,
  ...
}: {
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = lib.mkDefault "ter-v32n";
    earlySetup = true;
    packages = with pkgs; [terminus_font];
  };

  # set up other fonts
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    fontconfig = {
      enable = true;
      # Fixes pixelation
      antialias = true;

      # Fixes antialiasing blur
      hinting = {
        enable = true;
        style = "full"; # no difference
        autohint = true; # no difference
      };

      subpixel = {
        # Makes it bolder
        rgba = "rgb";
        lcdfilter = "default"; # no difference
      };
    };

    packages = with pkgs; [
      ubuntu_font_family
      iosevka-nerd-font
      inconsolata
      inconsolata-lgc
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      dejavu_fonts
      powerline-fonts
      corefonts
      symbola
      liberation_ttf
      fira-code
      fira-code-symbols
      # mplus-outline-fonts
      dina-font
      proggyfonts
      arphic-ukai
      arphic-uming
      font-awesome
      noto-fonts-extra
      source-han-sans
      wqy_microhei
      wqy_zenhei
    ];
  };
}
