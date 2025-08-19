source $`($env.XDG_CONFIG_HOME)/nushell/config.nu`
source $`($env.XDG_CONFIG_HOME)/nushell/default-config.nu`

$env.config = {
  buffer_editor: ["emacsclient", "-t"]
  edit_mode: "vi"
  cursor_shape: {
    vi_insert: "line"
    vi_normal: "block"
  }
}
$env.TERM = "wezterm"
