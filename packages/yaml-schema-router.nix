{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "yaml-schema-router";
  version = "0.2.0";
  src = fetchFromGitHub {
    owner = "traiproject";
    repo = "yaml-schema-router";
    rev = "v${version}";
    sha256 = "sha256-GFe5NPW8nxv+bQsG5G26WCf2Z6qrW1WAZBMWFZD8MFI=";
  };

  vendorHash = null;
}
