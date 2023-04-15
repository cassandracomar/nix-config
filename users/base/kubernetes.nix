{ config, lib, pkgs, ... }:

let
  kustomize' = pkgs.buildGoModule rec {
    pname = "kustomize";
    version = "5.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "kubernetes-sigs";
      repo = pname;
      rev = "kustomize/v${version}";
      sha256 = "sha256-wVdB9fTLYg7Ma0dRgDt7X7ncN0+04DyT8kp2+/aQ018=";
    };
    vendorSha256 = "sha256-bY3TxRErkUEaBCSk0w7LhvLC10YDCJhPV73fKwlWuFI=";
    GOWORK = "off";

    ldflags = let t = "sigs.k8s.io/kustomize/api/provenance"; in
      [
        "-s"
        "-X ${t}.version=${version}"
        "-X ${t}.gitCommit=${src.rev}"
      ];

    # avoid finding test and development commands
    modRoot = "kustomize";

    nativeBuildInputs = [ pkgs.installShellFiles ];

    postInstall = ''
      installShellCompletion --cmd kustomize \
        --bash <($out/bin/kustomize completion bash) \
        --fish <($out/bin/kustomize completion fish) \
        --zsh <($out/bin/kustomize completion zsh)
    '';

  };
in
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
    kustomize'
  ];
}
