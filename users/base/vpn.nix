{
  pkgs,
  config,
  ...
}: let
  launch-split = pkgs.writeShellScript "launch-split.sh" ''
    ${pkgs.vpn-slice}/bin/vpn-slice --no-fork --domains-vpn-dns drwholdings.com,drw,drw.slack.com --verbose --dump 10.0.0.0/8 2>&1 \
      | sudo -u ${config.home.username} systemd-cat -t vpn-slice
  '';
  launch-vpn = pkgs.writeShellScript "launch-vpn.sh" ''
    sudo sed -i 's/fake/bogus/' /etc/hosts
    PASSWD=$(${pkgs.rbw}/bin/rbw get drwholdings.com)

    sudo openconnect --pid-file "$XDG_RUNTIME_DIR"/openconnect.pid \
      --user=ccomar \
      -g linux \
      --csd-wrapper=${pkgs.openconnect}/libexec/openconnect/csd-post.sh \
      --local-hostname=nylld-ccomar1 \
      -s ${launch-split} \
      nyvpn1.drwholdings.com \
    | systemd-cat -t anyconnect
  '';
  kill-vpn = pkgs.writeShellScript "kill-vpn.sh" ''
    if [[ -f "$XDG_RUNTIME_DIR"/openconnect.pid ]]; then
      sudo kill "$MAINPID" "$(cat "$XDG_RUNTIME_DIR"/openconnect.pid)"
    fi
  '';
in {
  systemd.user.services.anyconnect = {
    Unit = {
      Description = "connect to vpn";
    };

    Service = {
      ExecStart = "${launch-vpn}";
      ExecStop = "${kill-vpn}";
    };
  };
}
