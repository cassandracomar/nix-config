source `~/.config/nushell/oh-my-posh.nu`
source `~/.config/nushell/config.nu`

# manually configure carapace completions so we can replace nix completions with
# those from fish
let external_completer = {|spans|
  # if the current command is an alias, get it's expansion
  let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)

  # overwrite
  let spans = (if $expanded_alias != null  {
    # put the first word of the expanded alias first in the span
    $spans | skip 1 | prepend ($expanded_alias | split row " ")
  } else {
    $spans | skip 1 | prepend ($spans.0)
  })
  let quote_if_needed = {|value|
    let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
    if ($need_quote) {
      let expanded_path = if (($value | path exists) and $value starts-with ~) {$value | path expand --no-symlink} else {$value}
      $'"($expanded_path | str replace --all "\"" "\\\"")"'
    } else {$value}
  }
  let unquote = {|value|
    $value | str replace --all "'" "" | str replace --all '"' "" | str replace --all "`" ""
  }

  let fish_completer = {|spans|
    fish --command $"complete '--do-complete=($spans | do $unquote $in | each {do $quote_if_needed $in} | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
      do $quote_if_needed $row.value
    }
  }
  let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json}

  match $spans.0 {
    _ => $fish_completer
  } | do $in $spans
}

# insert an extra line of prompt to keep PWD on it's own line
# let old_prompt_command = $env.PROMPT_COMMAND

$env.config | merge deep {
  completions: {
    external: {
      enable: true
      completer: $external_completer
    }
  }
  render_right_prompt_on_last_line: false
} | { config: $in }
  | load-env

# $env.PROMPT_COMMAND = {||
#   let old_prompt = do $old_prompt_command
#   $"($old_prompt)\n └─>> "
# }

export def --env "git cc" [server_org_repo: string] {
  let split = $server_org_repo | split column "/" server org repo

  let server = $split | get server.0
  let org = $split | get org.0
  let repo = $split | get repo.0
  mkdir ~/src/$server/$org
  git clone $"git@($server):($org)/($repo)" ~/src/$"($server)/($org)/($repo)"
  cd $"~/src/($server)/($org)/($repo)"
}

export def --wrapped "nh os upgrade" [...raw_args: string] {
  let hostname = (hostname);
  mut raw_args = $raw_args;
  mut host = null;
  if ($raw_args | length) != 0 and (not ($raw_args.0 | str starts-with "-")) {
    $host = $raw_args.0;
    $raw_args = $raw_args | skip 1;
  }

  if $host == "banyan" {
    $env.NH_FLAKE = "~/src/gitlab.com/zanny/banyan" | path expand;
  }

  git -C $env.NH_FLAKE pull
  nix flake update --flake $env.NH_FLAKE --commit-lock-file
  git -C $env.NH_FLAKE push
  
  mut args = [];
  if $host != null and $hostname != $host {
    $args ++= ["--target-host", $"($host).local", "--build-host", $"($host).local", "-H", $host];
  }

  nh os switch ...($args) ...($raw_args)
}

export def --wrapped "nh home upgrade" [...raw_args] {
  git -C $env.NH_FLAKE pull
  nix flake update --flake $env.NH_FLAKE --commit-lock-file
  git -C $env.NH_FLAKE push

  nh home switch -u ...($raw_args)
}

alias ls = eza
