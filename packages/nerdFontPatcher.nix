{
  nerd-font-patcher,
  fd,
  stdenv,
  lib,
}: pkg: {
  mono ? false,
}:
stdenv.mkDerivation {
  pname = "${lib.strings.toLower pkg.pname}-nerd-font${lib.optionalString mono "-mono"}";
  version = pkg.version;
  src = pkg;
  nativeBuildInputs = [nerd-font-patcher fd];
  installPhase = ''
    mkdir -p $out/share/fonts/{truetype,opentype}
    fd -e ttf -e otf -j ''${NIX_BUILD_CORES} -x nerd-font-patcher --complete --careful${lib.optionalString mono " --mono"} --outputdir $out/{//} {//}/{/}
  '';
}
