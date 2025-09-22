{
  poetry2nix,
  iosevka,
  nerd-font-patcher,
  fetchFromGitHub,
  stdenv,
  applyPatches,
  parallel,
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
  feature-freezer-src = applyPatches {
    src = fetchFromGitHub {
      owner = "twardoch";
      repo = "fonttools-opentype-feature-freezer";
      rev = "2ae16853bc724c3e377726f81d9fc661d3445827";
      sha256 = "sha256-mIWQF9LTVKxIkwHLCTVK1cOuiaduJyX8pyBZ/0RKIVE=";
    };
    patches = [
      ./feature-freezer-poetry-fixes.patch
    ];
  };
  feature-freezer = poetry2nix.mkPoetryApplication {
    projectDir = feature-freezer-src;
    src = feature-freezer-src;
    checkGroups = [];
    doCheck = false;
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
      find \( -name "*NerdFont*.ttf" -o -name "*NerdFont*.otf" \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} -m ${feature-freezer}/bin/pyftfeatfreeze -rnv -f dlig
    '';
    installPhase = "cp -a . $out";
  };
  pyftfeatfreeze = feature-freezer;
}
