{ config, lib, pkgs, pkgs-master, ... }:

{
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
