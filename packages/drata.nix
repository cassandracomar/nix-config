{
  lib,
  pkgs,
}: let
  # Please keep the version x.y.0.z and do not update to x.y.76.z because the
  # source of the latter disappears much faster.
  version = "3.2.0";

  src = pkgs.fetchurl {
    url = "https://cdn.drata.com/agent/dist/linux/drata-agent-3.2.0.deb";
    sha256 = "sha256-cZaNZzZanUtsETJAXLBUe4EI1jpRXfHqmC5u9WCk75Q=";
  };
in {
  drata-agent = pkgs.stdenv.mkDerivation {
    name = "drata-agent";

    system = "x86_64-linux";

    inherit src;

    # Required for compilation
    nativeBuildInputs = with pkgs; [
      autoPatchelfHook # Automatically setup the loader, and do the magic
      dpkg
      makeWrapper
    ];

    # Required at running time
    buildInputs = with pkgs; [
      glibc
      ffmpeg
      glib
      nss
      mime-types
      nspr
      atk
      gtk3
      pango
      cairo
      xlibsWrapper
      xorg.libXdamage
      xorg.libxshmfence
    ];

    unpackPhase = "true";

    # Extract and copy executable in $out/bin
    installPhase = ''
      mkdir -p $out/bin
      dpkg -x $src $out
      mv $out/usr/share $out/share
      rm -rf $out/usr
      ln -s $out/opt/Drata\ Agent/drata-agent $out/bin/.drata-agent-unwrapped
      makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/drata-agent --add-flags $out/bin/.drata-agent-unwrapped
      substituteInPlace $out/share/applications/drata-agent.desktop --replace 'Exec="/opt/Drata Agent/drata-agent" %U' "Exec=\"$out/bin/drata-agent\" %U"
    '';

    meta = with lib; {
      description = "drata system agent";
      homepage = "https://app.drata.com";
      license = licenses.mit;
      maintainers = with stdenv.lib.maintainers; [];
      platforms = ["x86_64-linux"];
    };
  };
}
