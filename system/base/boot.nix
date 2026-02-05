{pkgs, ...}: let
  plymouth-op = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "plymouth-onepiece-theme";
    version = "1.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "Anxhul10";
      repo = "onePiece-plymouth";
      rev = "4841da09f4977203b77b8160217a9fcce295d22c";
      sha256 = "sha256-xPBrdGnel1BUe3WoGGMrlfe1QGwYTHhlxclOQtOmIC8=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/plymouth/themes/onePiece-plymouth
      cp -r * $out/share/plymouth/themes/onePiece-plymouth
      find $out/share/plymouth/themes/ -name \*.plymouth -exec sed -i "s@\/usr\/@$out\/@" {} \;

      runHook postInstall
    '';
  };
in {
  boot = {
    # set ZFS options
    supportedFilesystems = ["zfs" "f2fs" "ext4" "xfs" "cifs" "vfat" "ntfs"];
    plymouth = {
      enable = true;
      themePackages = [plymouth-op];
      theme = "onePiece-plymouth";
    };
  };
}
