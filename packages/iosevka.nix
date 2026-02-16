{
  aporetic,
  callPackage,
  ...
}: let
  iosevka-custom = aporetic.override {
    privateBuildPlan = {
      family = "Iosevka";
      ligations.inherits = "dlig";
      ligations.enables = ["slasheq"];
      exportGlyphNames = true;
    };
    set = "Custom";
  };
  nerdFontPatcher = callPackage ./nerdFontPatcher.nix {};
in {
  inherit iosevka-custom;
  iosevka-nerd-font = nerdFontPatcher iosevka-custom;
}
