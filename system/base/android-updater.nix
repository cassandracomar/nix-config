{ config, lib, pkgs, androidImages, ... }:
let
  androidFiles = pkgs.runCommand "updater.ndra.io"
    {
      nativeBuildInputs = with pkgs; [ sops age gnupg ];
    } ''
    mkdir -p $out
    cd $out
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (device: cfg: ''
      ${cfg.config.build.releaseScript} ${cfg.config.prevBuildNumber}
    '') androidImages)}
  '';
  updaterScript = ''
    mkdir -p /var/www/updater.ndra.io
    cp --no-preserve owner,mode -r ${androidFiles}/* /var/www/updater.ndra.io
    chown nginx: -R /var/www/updater.ndra.io
  '';
in
{
  services.nginx = {
    enable = true;
    virtualHosts."updater.ndra.io" = {
      enableACME = true;
      addSSL = true;
      root = "/var/www/updater.ndra.io";
    };
  };
  # systemd.services.nginx.serviceConfig.ReadWritePaths = [ "/var/spool/nginx/logs/" ];
  security.acme.certs = {
    "updater.ndra.io".email = "cass@ndra.io";
  };
  security.acme.acceptTerms = true;
  system.activationScripts.androidUpdater = lib.stringAfter [ "var" ] updaterScript;
}
