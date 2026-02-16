{
  nerd-font-patcher,
  fd,
  stdenv,
  lib,
}: pkg:
stdenv.mkDerivation {
  pname = "${lib.strings.toLower pkg.pname}-nerd-font";
  version = pkg.version;
  src = pkg;
  nativeBuildInputs = [nerd-font-patcher fd];
  installPhase = ''
    mkdir -p $out/share/fonts/{truetype,opentype}
    fd -e ttf -e otf -j ''${NIX_BUILD_CORES} -x nerd-font-patcher --complete --careful --outputdir $out/{//} {//}/{/}
  '';
}
