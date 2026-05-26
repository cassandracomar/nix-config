{
  iosevka,
  callPackage,
  ...
}: let
  iosevka-custom = iosevka.override {
    privateBuildPlan = {
      family = "Iosevka";
      ligations.inherits = "dlig";
      ligations.enables = ["slasheq"];
      exportGlyphNames = true;
    };
    set = "-Custom";
  };
  nerdFontPatcher = callPackage ./nerdFontPatcher.nix {};
in {
  inherit iosevka-custom;
  iosevka-nerd-font = nerdFontPatcher iosevka-custom {};
  iosevka-nerd-font-mono = nerdFontPatcher iosevka-custom {mono = true;};
}
