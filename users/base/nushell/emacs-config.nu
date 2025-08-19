source $`($env.XDG_CONFIG_HOME)/nushell/config.nu`
source $`($env.XDG_CONFIG_HOME)/nushell/default-config.nu`
source $`($env.XDG_CONFIG_HOME)/nushell/eat-config.nu`

alias vim = eat open
alias vi = eat open
alias cat = bat -f -pp

$env.PAGER = "bat -f -pp"
