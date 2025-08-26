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

  environment.sessionVariables = {
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };
  services.displayManager.environment = {
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };
  environment.variables = {
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  # set up other fonts
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    fontconfig = {
      enable = true;
      antialias = true;
      useEmbeddedBitmaps = true;
      cache32Bit = true;

      defaultFonts = {
        serif = ["Noto Serif Nerd Font"];
        sansSerif = ["Noto Sans Nerd Font"];
        monospace = ["Iosevka Nerd Font"];
      };

      # Fixes antialiasing blur
      hinting = {
        enable = true;
        style = "full"; # no difference
        autohint = false; # no difference
      };

      subpixel = {
        # Makes it bolder
        rgba = "none";
        lcdfilter = "light"; # no difference
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
      noto-fonts-color-emoji
      noto-fonts-emoji-blob-bin
      noto-fonts-monochrome-emoji
      noto-fonts-extra
      nerd-fonts.noto
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
