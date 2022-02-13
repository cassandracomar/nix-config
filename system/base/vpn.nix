{ config, lib, pkgs, ... }:

{
  services.tailscale.enable = true;
  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up
    '';
  };

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
