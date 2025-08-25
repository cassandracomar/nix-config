source `~/.config/nushell/oh-my-posh.nu`

# manually configure carapace completions so we can replace nix completions with
# those from fish
let external_completer = {|spans|
  # if the current command is an alias, get it's expansion
  let expanded_alias = (scope aliases | where name == $spans.0 | get -o 0 | get -o expansion)

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
    nix => $fish_completer
    _ => $carapace_completer
  } | do $in $spans
}

# insert an extra line of prompt to keep PWD on it's own line
let old_prompt_command = $env.PROMPT_COMMAND

{
  config: {
    completions: {
      external: {
        enable: true
        completer: $external_completer
      }
    }
    render_right_prompt_on_last_line: false
    hooks: ($env.config.hooks | default {})
  }
  PROMPT_COMMAND: {||
    let old_prompt = do $old_prompt_command
    $"($old_prompt)\n └─>> "
  }
} | load-env
