{
  pkgs,
  poetry2nix,
  ...
}: let
  plainPackage = pkgs.iosevka.override {
    privateBuildPlan = {
      family = "Iosevka";
      ligations.inherits = "dlig";
      ligations.enables = ["slasheq"];
      exportGlyphNames = true;
    };
    set = "Custom";
  };
  nerd-font-patcher = pkgs.nerd-font-patcher.overrideAttrs (old: rec {
    version = "3.2.1";
    src = pkgs.fetchzip {
      url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/FontPatcher.zip";
      sha256 = "sha256-3s0vcRiNA/pQrViYMwU2nnkLUNUcqXja/jTWO49x3BU=";
      stripRoot = false;
    };
  });
  feature-freezer-orig-src = pkgs.fetchFromGitHub {
    owner = "twardoch";
    repo = "fonttools-opentype-feature-freezer";
    rev = "2ae16853bc724c3e377726f81d9fc661d3445827";
    sha256 = "sha256-mIWQF9LTVKxIkwHLCTVK1cOuiaduJyX8pyBZ/0RKIVE=";
  };
  feature-freezer-src = pkgs.stdenv.mkDerivation {
    name = "fonttools-opentype-feature-freezer-src";
    src = feature-freezer-orig-src;
    nativeBuildInputs = [pkgs.rsync];
    patches = [./feature-freezer-poetry-fixes.patch];
    phases = ["unpackPhase" "patchPhase" "installPhase" "fixupPhase"];
    installPhase = ''
      rsync -r ./ $out/
    '';
  };
  feature-freezer = poetry2nix.mkPoetryApplication rec {
    projectDir = feature-freezer-src;
    src = projectDir;
    checkGroups = [];
    doCheck = false;
  };
in {
  iosevka-custom = plainPackage;
  iosevka-nerd-font = pkgs.stdenv.mkDerivation {
    pname = "iosevka-nerd-font";
    version = plainPackage.version;

    src = plainPackage;

    nativeBuildInputs = [nerd-font-patcher];

    buildPhase = ''
      find \( -name \*.ttf -o -name \*.otf \) -execdir nerd-font-patcher --complete --careful {} \;
      find \( -name \*.ttf -o -name \*.otf \) -execdir chmod +x {} \;
      find \( -name "*NerdFont*.ttf" -o -name "*NerdFont*.otf" \) | xargs -n1 ${feature-freezer}/bin/pyftfeatfreeze -rnv -f dlig
    '';
    installPhase = "cp -a . $out";
  };
  pyftfeatfreeze = feature-freezer;
}
