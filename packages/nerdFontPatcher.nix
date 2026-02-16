{
  nerd-font-patcher,
  parallel,
  stdenv,
}: pkg:
stdenv.mkDerivation {
  pname = "${pkg.pname}-nerd-font";
  version = pkg.version;

  src = pkg;

  nativeBuildInputs = [nerd-font-patcher parallel];

  buildPhase = ''
    find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -0 -P ''${NIX_BUILD_CORES} cd {//} '&&' nerd-font-patcher --complete --careful {/}
  '';
  installPhase = ''
    mkdir -p $out/share/fonts/{truetype,opentype}
    find \( -name "*NerdFont*.ttf" -o -name "*Name*.otf" \) -print0 | xargs -0 -I'{}' install -m644 {} $out/{}
  '';
}
