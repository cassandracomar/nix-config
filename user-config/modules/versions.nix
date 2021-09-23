let
  inherit (import <nixpkgs> { }) fetchFromGitHub lib pipe;
  versionSets = builtins.fromJSON
    (builtins.readFile /home/cassandra/.config/nixpkgs/versions.json);
in builtins.mapAttrs (name: value:
  lib.pipe value [
    (lib.flip builtins.removeAttrs [ "branch" ])
    fetchFromGitHub
  ]) versionSets
