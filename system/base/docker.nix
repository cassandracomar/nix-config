{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation = {
    docker = {
      enable = true;
      # extraPackages = [ pkgs.zfsUnstable pkgs.fuse-overlayfs ];
      # dockerSocket.enable = true;
      storageDriver = lib.mkDefault "zfs";
      daemon.settings = {
        bip = "172.16.0.100/24";
        # dns = [ "127.0.0.11" ];
      };
    };
    libvirtd.enable = true;
    # containers.storage.settings = {
    #   storage = {
    #     driver = "zfs";
    #     graphroot = "/var/lib/containers/storage";
    #     runroot = "/run/containers/storage";
    #     options.zfs = {
    #       fsname = "data/root/containers";
    #     };
    #   };
    # };
  };
  # services.kubernetes = {
  #   roles = [ "master" "node" ];
  #   masterAddress = "yew.local";
  #   apiserverAddress = "https://yew.local:6443";
  #   easyCerts = true;
  #   apiserver = {
  #     securePort = 6443;
  #     advertiseAddress = "2601:145:427e:4bc2::1";
  #   };
  #   clusterCidr = "2601:145:427e:4bc2::/80";
  #   addons.dns.enable = true;
  #   pki.pkiTrustOnBootstrap = true;
  # };
  # systemd.services.certmgr = {
  #   environment = {
  #     SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  #   };
  #   serviceConfig.BindReadOnlyPaths = [ "/etc/ssl/certs" "/var/lib/cfssl/" ];
  # };
  # security.pki.certificates = [
  #   ''
  #     NixOS
  #     =========
  #     -----BEGIN CERTIFICATE-----
  #     MIIDizCCAnOgAwIBAgIUFmHsQqBsngSeZ5hJeMDvCjFdbhcwDQYJKoZIhvcNAQEL
  #     BQAwUjEXMBUGA1UEBxMOYXV0by1nZW5lcmF0ZWQxDjAMBgNVBAoTBU5peE9TMScw
  #     JQYDVQQLEx5zZXJ2aWNlcy5rdWJlcm5ldGVzLnBraS5jYVNwZWMwHhcNMjMwNDIx
  #     MTUzMzAwWhcNMjQwNDIwMTUzMzAwWjAUMRIwEAYDVQQDEwl5ZXcubG9jYWwwggEi
  #     MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD1JcEtYBWgo/HyaGkteWkczc2i
  #     0TWAcm7amJefwYY9Y8wTsSDJdXV0H1AzyzNL34puopZF/92UA2HPJRdoy8RRNnj/
  #     33vzSXMzoXz+igpo5Yeb8LWmjmzLHlW1MRQsOYFyPNwzsVDsdPG7Xerqgg4iW3Wg
  #     AB0tABBw9b4BKhcT3wuxMZUHwLuZEyGQ5m7RRxhNgoo/3uWTVNA1L/Jk9L414qaS
  #     KeMNos64kcUYkte1PdFVF9nr1NV/VhfF8RzaCElJdpUXL8kat2F2OmgZigEd54O3
  #     rKbexpz923rW/bn4X8ek8FRlDeAMpqPIiIdx2FypgczSUNEwecJaXTcu7ZMDAgMB
  #     AAGjgZYwgZMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
  #     BgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBSepAVzYC8f0wcfHSfCGDHj
  #     a79W/TAfBgNVHSMEGDAWgBQYcrSY3MKJ1HRR++NBHBcXbm0w1TAUBgNVHREEDTAL
  #     ggl5ZXcubG9jYWwwDQYJKoZIhvcNAQELBQADggEBACOg3Ro5URQcCqroyQ4dcJnH
  #     vIB3hN8S5DhajyknTNiSqsAbj3zDEyKEEB30I0/QxCnXOn5PHHenYGfYQrsPtMf5
  #     XSFa/o37Ln3rEBvIbzHAF3BynHCyj281Lw3+zZfe0/1Oc12MhPzlt4gJL38NULcf
  #     RW6fTviqpbohipcFpXiX5rij0SaWmedmjj3GLK/2WiL18KzFKbZyOaZgzzccCm+H
  #     6b0Bo6DjxcjneLpkhpFfLNHvNbKcBcASMeVXqcqCdcCDBGlrXUMa12Ka++spu7GW
  #     j9/fQ22tPs5+ED4hSM5G3fHNJpr27Nj1xQCwVoHAW4dQhNanvSIvxcahksxp554=
  #     -----END CERTIFICATE-----
  #   ''
  # ];
}
