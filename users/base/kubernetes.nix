{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    krew
    kind
    kubernetes-helm
    minikube
    docker
    docker-buildx
    docker-credential-helpers
    pass
    yq-go
    eksctl
    skaffold
    tailscale
    jsonnet-bundler
    tanka
    buildkit
    #awscli2
    vault
    istioctl
    vcluster
  ];
}
