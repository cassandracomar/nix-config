{
  config,
  lib,
  pkgs,
  ...
}: {
  services.openvpn.servers = {
    perfect-privacy-los-angeles = {
      config = "config /var/lib/vpns/perfect-privacy/LosAngeles.conf";
      updateResolvConf = true;
      autoStart = false;
    };
    perfect-privacy-new-york = {
      config = "config /var/lib/vpns/perfect-privacy/NewYork.conf";
      updateResolvConf = true;
      autoStart = false;
    };
  };
  environment.etc.openvpn.source = pkgs.update-resolv-conf;
  networking.resolvconf.extraConfig = ''
    name_server='127.0.0.1'
  '';
}
