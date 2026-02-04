{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
}:
buildNpmPackage (finalAttrs: {
  pname = "yaml-language-server";
  version = "1.20.0-fefd3a6d";

  src = fetchFromGitHub {
    owner = "redhat-developer";
    repo = "yaml-language-server";
    rev = "fefd3a6dd9758bec0ef3690b2797e5e939feadc8";
    hash = "sha256-7Qhgu/14vvCL5MK+MJ4hq1B50PtlEZEQgkG01/6sDqg=";
  };

  npmDepsHash = "sha256-lqH1zDRAJrZ1nybPkJLCzXUUahniHz1NQKcKtYXzQPY=";

  strictDeps = true;

  meta = {
    changelog = "https://github.com/redhat-developer/yaml-language-server/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    description = "Language Server for YAML Files";
    homepage = "https://github.com/redhat-developer/yaml-language-server";
    license = lib.licenses.mit;
    mainProgram = "yaml-language-server";
    maintainers = [];
  };
})
