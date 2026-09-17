{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.12.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    rev = "7455eef95f172998421c26ebaa3aac4239a28f14";
    sha256 = "sha256-RXn/yDQANFpuac1Tv8RPnk6PT9tHXGI9Po97Vel2ALE=";
  };

  npmDepsHash = "sha256-BeRj6LpIpGV4ONEHE//nYXTfkB1nfVQpPeJF3LRlyRM=";
  nodejs = nodejs_22;

  meta = {
    description = "Codex agent for the Agent Client Protocol";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
  };
}
