{
  iosevka,
  nerd-font-patcher,
  stdenv,
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
in {
  iosevka-custom = plainPackage;
  iosevka-nerd-font = stdenv.mkDerivation {
    pname = "iosevka-nerd-font";
    version = plainPackage.version;

    src = plainPackage;

    nativeBuildInputs = [nerd-font-patcher parallel];

    buildPhase = ''
      mkdir $out
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' nerd-font-patcher --complete --careful {/}
      find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' chmod +x {/}
    '';
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find \( -name "*NerdFont*.ttf" \) -print0 | xargs -0 -I'{}' install -m644 {} $out/{}
    '';
  };
}
