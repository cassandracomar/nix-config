{ lib, pkgs, config, ... }:
with lib;
let cfg = config.services.actualbudget;
in {
  options.services.actualbudget = {
    enable = mkEnableOption "turn on the actualbudget server";
    package = mkOption {
      type = types.package;
      default = pkgs.actualbudget-server;
      defaultText = literalExpression "pkgs.actualbudget-server";
      description = "the package to use for the actualbudget server";
    };
    port = mkOption {
      type = types.port;
      example = 5006;
      default = 5006;
      description = ''
        socket port number the server should run on
      '';
    };
    mode = mkOption {
      type = types.enum [ "development" "production" ];
      example = "development";
      default = "production";
      description =
        "operational mode for the actualbudget server. use production unless you're developing enhancements to the service.";
    };
    listenAddr = mkOption {
      type = types.str;
      example = "127.0.0.1";
      default = "0.0.0.0";
      description = ''
        this corresponds to the hostname setting in the actualbudget configuration.
        this must be an ip mask that a client must match in order to access the server. for example:
             - 127.0.0.1 matches only 1 ipv4 address
             - 0.0.0.0 matches all ipv4 addresses.
             - 10.0.0.0 matches all addresses in the 10.0.0.0/8 CIDR.
             - ::1 matches all ipv6 addresses.
      '';
    };
    dataRootPath = mkOption {
      type = types.path;
      example = "/data";
      default = "/var/run/actualbudget";
      description =
        "the root directory where server and user files should be stored. the serverFilesPath and userFilesPath options override this setting.";
    };
    serverFilesPath = mkOption {
      type = types.path;
      example = "/data/server-files";
      default = "${cfg.dataRootPath}/server-files";
      description =
        "the data path directory where runtime server files should be stored. this defaults to the 'server-files' path under config.services.actualbudget.dataRootPath.";
    };
    userFilesPath = mkOption {
      type = types.path;
      example = "/data/user-files";
      default = "${cfg.dataRootPath}/server-files";
      description =
        "the data path directory where runtime user files should be stored. this defaults to the 'user-files' path under config.services.actualbudget.dataRootPath.";
    };
  };

  config = let
    setConfig = {
      mode = cfg.mode;
      port = cfg.port;
      hostname = cfg.listenAddr;
      serverFiles = cfg.serverFilesPath;
      userFiles = cfg.userFilesPath;
    };
    cfgFile = pkgs.writeTextDir "lib/node_modules/actual-sync/config"
      (builtins.toJSON setConfig);
    package = pkgs.buildEnv {
      name = "actualbudget-server-env";
      paths = [ cfg.package cfgFile ];
    };
  in mkIf cfg.enable {
    systemd.services.actualbudget = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig.ExecStart =
        "${package}/lib/node_modules/actual-sync/app.js";
    };
    environment.systemPackages = [ package ];
  };
}
