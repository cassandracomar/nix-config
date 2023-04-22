{ config, lib, pkgs, androidImages, ... }:
let
  androidFiles = pkgs.runCommand "updater.ndra.io" { } ''
    mkdir -p $out
    cd $out
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (device: cfg: ''
      ${cfg.config.build.releaseScript}
    '') androidImages)}
  '';
  updaterScript = pkgs.writeScriptBin "updater.sh" ''
    mkdir -p /var/www/updater.ndra.io
    cp -r ${androidFiles}/* /var/www/updater.ndra.io
  '';
in
{
  services.nginx = {
    enable = true;
    virtualHosts."updater.ndra.io" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www/updater.ndra.io";
    };
  };
  systemd.services.nginx.preStart = "${updaterScript}/bin/updater.sh";
  # systemd.services.nginx.serviceConfig.ReadWritePaths = [ "/var/spool/nginx/logs/" ];
  security.acme.certs = {
    "updater.ndra.io".email = "cass@ndra.io";
  };
  security.acme.acceptTerms = true;
}
