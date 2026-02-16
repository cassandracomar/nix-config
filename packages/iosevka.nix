{
  iosevka,
  nerd-font-patcher,
  stdenv,
  parallel,
  python3,
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
  pyenv = python3.withPackages (ps:
    with ps; [
      fonttools
      (opentype-feature-freezer.overrideAttrs (old: {
        patches = (old.patches or []) ++ [./feature-freezer-fontTools.patch];
      }))
    ]);
in {
  fontToolsPyEnv = pyenv;
  iosevka-custom = plainPackage;
  iosevka-nerd-font = stdenv.mkDerivation {
    pname = "iosevka-nerd-font";
    version = plainPackage.version;

    src = plainPackage;

    nativeBuildInputs = [nerd-font-patcher parallel];

    buildPhase = ''
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' nerd-font-patcher --complete --careful {/}
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' chmod +x {/}
      find \( -name "*NerdFont*.ttf" -o -name "*NerdFont*.otf" \) -print0 | parallel -0 -I'{}' -P ''${NIX_BUILD_CORES} -m ${pyenv}/bin/pyftfeatfreeze -rnv -f dlig '{}' .
      find . -type f
      exit -1
    '';
    installPhase = "cp -a . $out";
  };
}
