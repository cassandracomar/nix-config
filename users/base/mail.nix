{
  config,
  pkgs,
  ...
}: {
  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "${pkgs.isync}/bin/mbsync -Ln --all";
      postNew = ''
        ${pkgs.afew}/bin/afew --tag --new --verbose
        ${pkgs.notifymuch}/bin/notifymuch
      '';
    };
    new = {
      ignore = ["trash" "*.json"];
      tags = ["new"];
    };
    search.excludeTags = ["trash" "deleted" "spam"];
    maildir.synchronizeFlags = true;
  };
  programs.afew = {
    enable = true;
    extraConfig = ''
      [SpamFilter]
      [KillThreadsFilter]
      [ListMailsFilter]
      [ArchiveSentMailsFilter]

      [FolderNameFilter.1]
      folder_transforms = cass@nie.rs:nie.rs cass@mountclare.net:mountclare.net
      maildir_separator = /
      folder_lowercases = true

      [Filter.1]
      query = 'from:amazon.com OR from:walmart.com'
      tags = +shopping;-new;-inbox
      message = kind of spammy
    '';
  };
  services.imapnotify.enable = true;

  accounts.email = {
    maildirBasePath = "${config.xdg.dataHome}/maildir";
    accounts = {
      "cass@nie.rs" = {
        address = "cass@nie.rs";
        passwordCommand = "${pkgs.rbw}/bin/rbw get purelymail.com cass@nie.rs";
        mbsync = {
          enable = true;
          create = "both";
        };
        primary = false;
        realName = "Cassandra Comar";
        imap.host = "imap.purelymail.com";
        smtp = {
          host = "smtp.purelymail.com";
        };
        msmtp.enable = true;
        notmuch.enable = true;
        imapnotify = {
          enable = true;
          onNotify = "${pkgs.isync}/bin/mbsync -Ln cass@nie.rs && ${pkgs.notmuch}/bin/notmuch new --no-hooks && ${pkgs.afew}/bin/afew --tag --new --verbose && ${pkgs.notifymuch}/bin/notifymuch";
        };
        userName = "cass@nie.rs";
      };
      "cass@mountclare.net" = {
        address = "cass@mountclare.net";
        passwordCommand = "${pkgs.rbw}/bin/rbw get purelymail.com cass@mountclare.net";
        mbsync = {
          enable = true;
          create = "both";
        };
        realName = "Cassandra Comar";
        imap.host = "imap.purelymail.com";
        smtp = {
          host = "smtp.purelymail.com";
        };
        msmtp.enable = true;
        notmuch.enable = true;
        imapnotify = {
          enable = true;
          onNotify = "${pkgs.isync}/bin/mbsync -Ln cass@mountclare.net && ${pkgs.notmuch}/bin/notmuch new --no-hooks && ${pkgs.afew}/bin/afew --tag --new --verbose && ${pkgs.notifymuch}/bin/notifymuch";
        };
        userName = "cass@mountclare.net";
      };
    };
  };
}
