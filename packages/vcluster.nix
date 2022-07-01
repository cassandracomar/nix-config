{ fetchurl, stdenv, ... }:
let version = "0.7.1";
in stdenv.mkDerivation {
  inherit version;
  name = "vcluster-bin";
  src = fetchurl {
    url =
      "https://github.com/loft-sh/vcluster/releases/download/v${version}/vcluster-linux-amd64";
    sha256 = "sha256-TxIyBrAJkIKms776rGOcfITnpFjTFOezIJWT6V0cYZw=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    install -Tm755 $src $out/bin/vcluster-linux-amd64
    ln -s $out/bin/vcluster-linux-amd64 $out/bin/vcluster
  '';
}
