{
  iosevka,
  nerd-font-patcher,
  stdenv,
  parallel,
  python3Packages,
  ...
}: let
  plainPackage = iosevka.override {
    privateBuildPlan = {
      family = "Iosevka";
      ligations.inherits = "dlig";
      ligations.enables = ["slasheq"];
      exportGlyphNames = true;
    };
    set = "Custom";
  };
in {
  iosevka-custom = plainPackage;
  iosevka-nerd-font = stdenv.mkDerivation {
    pname = "iosevka-nerd-font";
    version = plainPackage.version;

    src = plainPackage;

    nativeBuildInputs = [nerd-font-patcher parallel];

    buildPhase = ''
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' nerd-font-patcher --complete --careful {/}
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' chmod +x {/}
      find \( -name "*NerdFont*.ttf" -o -name "*NerdFont*.otf" \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} -m ${python3Packages.opentype-feature-freezer}/bin/pyftfeatfreeze -rnv -f dlig
    '';
    installPhase = "cp -a . $out";
  };
}
