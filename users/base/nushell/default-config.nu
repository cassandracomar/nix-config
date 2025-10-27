source `~/.config/nushell/oh-my-posh.nu`

$env.config = ($env.config? | default {})
$env.config.hooks = ($env.config.hooks? | default {})
$env.config.hooks.pre_prompt = (
    $env.config.hooks.pre_prompt?
    | default []
    | append {||
        direnv export json
        | from json --strict
        | default {}
        | items {|key, value|
            let value = do (
                {
                  "PATH": {
                    from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
                    to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
                  }
                }
                | merge ($env.ENV_CONVERSIONS? | default {})
                | get ([[value, optional, insensitive]; [$key, true, true] [from_string, true, false]] | into cell-path)
                | if ($in | is-empty) { {|x| $x} } else { $in }
            ) $value
            return [ $key $value ]
        }
        | into record
        | load-env
    }
)

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

  let fish_completer = {|spans|
      fish --command $"complete '--do-complete=($spans | str join ' ')'"
      | from tsv --flexible --noheaders --no-infer
      | rename value description
      | update value {
          if ($in | path exists) {$'"($in | str replace "\"" "\\\"" )"'} else {$in}
      }
  }
  let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json}

  match $spans.0 {
    nu => $fish_completer
    _ => $carapace_completer
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

export def --env git_checkout [server_org_repo: string] {
  let split = $server_org_repo | split column "/" server org repo

  let server = $split | get server.0
  let org = $split | get org.0
  let repo = $split | get repo.0
  mkdir ~/src/$server/$org
  git clone $"git@($server):($org)/($repo)" $"~/src/($server)/($org)/($repo)"
  cd $"~/src/($server)/($org)/($repo)"
}
