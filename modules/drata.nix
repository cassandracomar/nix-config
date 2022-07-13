{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.drata-agent;
in {
  options.services.drata-agent = {
    enable = mkEnableOption "turn on drata agent";
    package = mkOption {
      type = types.package;
      default = pkgs.drata-agent;
      defaultText = literalExpression "pkgs.draga-agent";
      description = "the package use to install the drata agent";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.drata-agent = {
      Unit = {
        Description = "drata system agent user service";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/drata-agent --disable-gpu";
        Restart = "always";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
    home.packages = [ cfg.package ];
  };
}
