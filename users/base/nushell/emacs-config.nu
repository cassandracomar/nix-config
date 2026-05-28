source `~/.config/nushell/config.nu`
source `~/.config/nushell/default-config.nu`
source `~/.config/nushell/eat-config.nu`

alias vim = eat open
alias vi = eat open
alias cat = eat cat

$env.PAGER = "bat -f -pp"
$env.config.render_right_prompt_on_last_line = false
$env.config | merge { render_right_prompt_on_last_line: false } | load-env
$env.PROMPT_COMMAND_RIGHT = null
