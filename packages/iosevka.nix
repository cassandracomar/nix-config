{
  iosevka,
  callPackage,
  ...
}: let
  privateBuildPlan = {
    family = "Iosevka";
    ligations.inherits = "dlig";
    ligations.enables = ["slasheq"];
    exportGlyphNames = true;
  };
  iosevka-custom =
    (iosevka.override {
      inherit privateBuildPlan;
      set = "-Custom";
    }).overrideAttrs (old: {
      requiredSystemFeatures = (old.requiredSystemFeatures or []) ++ ["big-parallel"];
    });
  iosevka-custom-mono = iosevka.override {
    privateBuildPlan = privateBuildPlan // {spacing = "term";};
    set = "-Custom";
  };
  nerdFontPatcher = callPackage ./nerdFontPatcher.nix {};
in {
  inherit iosevka-custom;
  iosevka-nerd-font = nerdFontPatcher iosevka-custom-mono {};
  iosevka-nerd-font-mono = nerdFontPatcher iosevka-custom-mono {mono = true;};
}
