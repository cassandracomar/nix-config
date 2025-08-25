source `~/.config/nushell/config.nu`
source `~/.config/nushell/default-config.nu`

$env.config = $env.config | merge deep {
  buffer_editor: ["emacsclient", "-t"]
  edit_mode: "vi"
  cursor_shape: {
    vi_insert: "line"
    vi_normal: "block"
  }
  render_right_prompt_on_last_line: false
}
$env.TERM = "wezterm"

$env.config.render_right_prompt_on_last_line = false

if $env.config.render_right_prompt_on_last_line {
   print "failed to set render_right_prompt_on_last_line"
}
