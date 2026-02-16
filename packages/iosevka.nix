{
  iosevka,
  nerd-font-patcher,
  stdenv,
  parallel,
  python3,
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
in rec {
  fontToolsPyEnv = pyenv;
  iosevka-custom = plainPackage;
  iosevka-nerd-font-pre = stdenv.mkDerivation {
    pname = "iosevka-nerd-font-pre";
    version = plainPackage.version;

    src = plainPackage;

    nativeBuildInputs = [nerd-font-patcher parallel];

    buildPhase = ''
      mkdir $out
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' nerd-font-patcher --complete --careful {/}
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' chmod +x {/}
    '';
    installPhase = "cp -a . $out";
  };
  iosevka-nerd-font = stdenv.mkDerivation {
    pname = "iosevka-nerd-font";
    version = plainPackage.version;
    src = iosevka-nerd-font-pre;

    nativeBuildInputs = [parallel pyenv];

    installPhase = ''
      mkdir -p $out/share/fonts/opentype
      find -name "*NerdFont*.ttf" -exec sh -c 'echo $(dirname {})/$(basename {} .ttf)' \; | parallel -P ''${NIX_BUILD_CORES} -m pyftfeatfreeze -nv -f dlig {//}/{/}.ttf $out/share/fonts/opentype/{/}.otf
    '';
  };
}
