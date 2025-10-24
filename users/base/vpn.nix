{
  pkgs,
  config,
  ...
}: let
  vpn-slice = pkgs.vpn-slice.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/dlenski/vpn-slice/pull/158.patch";
          sha256 = "sha256-vPsG8An0CnZDMmdZ3d4eZucwafLzO3BE3RaRqqHM8KU=";
        })
      ];
  });
  launch-split = pkgs.writeShellScript "launch-split.sh" ''
    ${vpn-slice}/bin/vpn-slice --no-fork --domains-vpn-dns drwholdings.com,drw,drw.slack.com --verbose --dump 10.0.0.0/8 2>&1 \
    | sudo -u ${config.home.username} systemd-cat -t vpn-slice
  '';
  launch-vpn = pkgs.writeShellScript "launch-vpn.sh" ''
    sudo sed -i 's/fake/bogus/' /etc/hosts

    ${pkgs.rbw}/bin/rbw get drwholdings.com ccomar \
    | sudo ${pkgs.openconnect}/bin/openconnect --pid-file "$XDG_RUNTIME_DIR"/openconnect.pid \
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
  fixup-dns = pkgs.writeShellScript "fixup-dns.sh" ''
    sudo ${pkgs.systemd}/bin/resolvectl domain tun0 drwholdings.com drw drw.slack.com
  '';
in {
  systemd.user.services.anyconnect = {
    Unit = {
      Description = "connect to vpn";
    };

    Service = {
      PIDFile = "openconnect.pid";
      ExecStart = "${launch-vpn}";
      ExecStop = "${kill-vpn}";
    };
  };
  systemd.user.services.vpn-dns = {
    Unit = {
      Description = "fixup vpn dns";
      After = ["anyconnect.service"];
      BindsTo = ["anyconnect.service"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${fixup-dns}";
      RemainAfterExit = true;
    };
  };
}
