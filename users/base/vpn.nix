{pkgs, ...}: let
  launch-vpn = pkgs.writeShellScript "launch-vpn.sh" ''
    (echo "ccomar" && ${pkgs.rbw}/bin/rbw get drwholdings.com && echo "y") | /opt/cisco/secureclient/bin/vpn -s connect "New York - Linux"
  '';
  kill-vpn = pkgs.writeShellScript "kill-vpn.sh" ''
    /opt/cisco/secureclient/bin/vpn disconnect
  '';
in {
  systemd.user.services.anyconnect = {
    Unit = {
      Description = "connect to vpn";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${launch-vpn}";
      ExecStop = "${kill-vpn}";
      RemainAfterExit = true;
    };
  };
}
