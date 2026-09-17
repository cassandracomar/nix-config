{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  fetchpatch2,
  codex,
  makeWrapper,
}:
buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.12.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    rev = "v${version}";
    sha256 = "sha256-GIMJm+kifPEMb7XLPSssUu87eEE+aaBr2jZUk8aPD2s=";
  };
  patches = [
    (fetchpatch2 {
      url = "https://patch-diff.githubusercontent.com/raw/agentclientprotocol/codex-acp/pull/395.patch";
      hash = "sha256-jWn7+JYrZH+GeyCPuKSbG0JvYWJKJAav6LrUIZGbgHw";
    })
  ];

  npmDepsHash = "sha256-BeRj6LpIpGV4ONEHE//nYXTfkB1nfVQpPeJF3LRlyRM=";
  nodejs = nodejs_22;

  nativeBuildInputs = [makeWrapper];

  postFixup = ''
    wrapProgram "$out/bin/codex-acp" \
      --set-default CODEX_PATH "${lib.getExe codex}"
  '';

  meta = {
    description = "Codex agent for the Agent Client Protocol";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
  };
}
