{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    krew
    kind
    kubernetes-helm
    minikube
    docker-credential-helpers
    pass
    yaml-language-server
    yq
    eksctl
    skaffold
    nodePackages.dockerfile-language-server-nodejs
    tailscale
    jsonnet-bundler
    tanka
    buildkit
    awscli2
    vault
    istioctl
  ];
}
