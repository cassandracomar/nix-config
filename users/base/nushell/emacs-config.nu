source `~/.config/nushell/config.nu`
source `~/.config/nushell/default-config.nu`
source `~/.config/nushell/eat-config.nu`

alias vim = eat open
alias vi = eat open
alias cat = bat -f -pp

$env.PAGER = "bat -f -pp"
