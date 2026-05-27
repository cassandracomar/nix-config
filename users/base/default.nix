{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./emacs.nix
    ./environment.nix
    ./haskell.nix
    ./kubernetes.nix
    ./mail.nix
    ./packages.nix
    # ./rust.nix
    ./shell-cfg.nix
    ./pinnacle.nix
    # ./xmonad.nix
    ./vpn.nix
  ];

  home.packages = with pkgs; [
    rustc
    (pkgs.symlinkJoin {
      name = "cargo-${cargo.version}";
      inherit (cargo) version meta;
      paths = [cargo];
      postBuild = ''
        completion="$out/share/fish/vendor_completions.d/cargo.fish"
        if [ -L "$completion" ]; then
          rm "$completion"
          cp ${cargo}/share/fish/vendor_completions.d/cargo.fish "$completion"
          sed -i "s|/nix/store/[a-z0-9]\{32\}-cargo-bootstrap[^/]*|${cargo}|g" "$completion"
        fi
      '';
    })
  ];
  xdg.userDirs.setSessionVariables = true;
  gtk.gtk4.theme = config.gtk.theme;
}
