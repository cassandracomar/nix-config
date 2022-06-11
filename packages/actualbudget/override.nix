{ pkgs, system }:

let nodePackages = import ./default.nix { inherit pkgs system; };
in nodePackages // {
  actualbudget-server = nodePackages."actualbudget-server-raw".override {
    src = pkgs.fetchgit {
      url = "https://github.com/katrovman/actual-server-fork";
      sha256 = "sha256-uv8tT2R3AEQ5SfrHM7To0QMgoU5WmMvnRNgsctWWLdc";
    };
    preRebuild = ''
      substituteInPlace package.json \
        --replace '"@actual-app/api": "file:actual-app-api-4.1.0.tgz",' '"@actual-app/api": "katrovman/actual-fork",'
      substituteInPlace package.json \
        --replace '"@actual-app/web": "file:actual-app-web-4.1.0.tgz",' '"@actual-app/web": "katrovman/actual-fork",'
      substituteInPlace package.json \
        --replace '"uuid": "^3.3.2",' '"uuid": "^3.4.0",'
    '';
  };
}
