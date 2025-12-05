#!/usr/bin/env sh

pinnacle client <<-EOT
local layout_requester = Layout.manage(function (layout_args)
  local master_stack = require("pinnacle.layout").builtin.master_stack()
  local root_node = master_stack:layout(layout_args.window_count)
  local tree_id = layout_args.tags[1] and layout_args.tags[1].id or 0

  return {
    root_node = root_node,
    tree_id = tree_id,
  }
end)

local next = Window.handle.new("$1")
local focused = Window.get_focused()

if (focused ~= nil and focused:maximized()) then
  focused:lower()
  next:set_maximized(true)
  next:raise()
end

focused:swap(next)
next:set_focused(true)
layout_requester:request_layout(nil)
EOT
