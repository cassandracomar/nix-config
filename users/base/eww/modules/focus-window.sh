#!/usr/bin/env sh

pinnacle client <<-EOT
pinnacle.run(function()
  local next = Window.handle.new("$1")
  local focused = Window.get_focused()
  
  if (focused ~= nil and focused:maximized()) then
    focused:lower()
    next:set_maximized(true)
    next:raise()
  end
  
  next:set_focused(true)
end)
EOT
