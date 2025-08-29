local cjson = require("cjson")

function get_workspaces(output)
  local tags = output:tags()
  local workspaces = {}
  for i, tag in ipairs(tags) do
    local num_windows = 0
    for _, _ in ipairs(tag:windows()) do
      num_windows = num_windows + 1
    end

    workspaces[i] = {
      name = tag:name(),
      is_active = tag:active(),
      is_focused = output:focused(),
      is_empty = num_windows == 0,
    }
  end

  return workspaces
end

function workspaces_by_output()
  local tag_map = {}

  for _, outp in ipairs(Output.get_all()) do
    local workspaces = get_workspaces(outp)
    tag_map[outp.name] = ' (box :orientation "h" :class "workspaces" :space-evenly true'
    for i, tag in ipairs(workspaces) do
      ws = tag.name
      class = ''
      if(tag.is_active)
      then
        class = '"workspaces urgent"'
      elseif (tag.is_empty)
      then
        class = '"workspaces empty"'
      else
        class = '"workspaces occupied"'
      end

      switch_to = ' :onclick "./modules/switch-to.sh ' .. ws .. '"'
      button = '(button :class ' .. class .. switch_to  .. ' (label :class "name" :justify "center" :width 5 :text "' .. ws .. '")' .. ')'
      tag_map[outp.name] = tag_map[outp.name] .. button
    end
    tag_map[outp.name] = tag_map[outp.name] .. ")"
  end

  return tag_map
end

print(cjson.encode(workspaces_by_output()))

Pinnacle.setup(function ()
  Window.connect_signal({
    focused = function(win)
      print(cjson.encode(workspaces_by_output()))
    end,
    pointer_enter = function(win)
      print(cjson.encode(workspaces_by_output()))
    end,
    pointer_leave = function(win)
      print(cjson.encode(workspaces_by_output()))
    end
  })
  Tag.connect_signal({
      active = function(tag, active)
        print(cjson.encode(workspaces_by_output()))
      end
  })
  Output.connect_signal({
      focused = function(outp)
        print(cjson.encode(workspace_by_output()))
      end
  })
end)
