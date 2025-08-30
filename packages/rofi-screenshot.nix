{
  lib,
  runCommand,
  makeWrapper,
  libnotify,
  rofi-wayland,
  wl-clipboard-rs,
  grim,
  slurp,
  coreutils,
  xdg-user-dirs,
}: let
  pname = "rofi-screenshot";
  version = "08-29-2025";
in
  runCommand pname {
    inherit pname version;

    nativeBuildInputs = [makeWrapper];

    meta = {
      description = "Use rofi to perform various types of screenshots and screen captures";
      mainProgram = "rofi-screenshot";
    };
  } ''
    install -Dm755 ${./rofi-screenshot} $out/bin/${pname}
    patchShebangs $out/bin/${pname}
    wrapProgram $out/bin/${pname} \
      --set PATH ${
      lib.makeBinPath [
        libnotify
        rofi-wayland
        wl-clipboard-rs
        grim
        slurp
        coreutils
        xdg-user-dirs
      ]
    }
  ''
