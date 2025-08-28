local cjson = require("cjson")

function get_workspaces(output)
  local tags = output:tags()
  local workspaces = {}
  for i, tag in ipairs(tags) do
    workspaces[i] = {
      name = tag:name(),
      is_active = tag:active(),
      is_focused = outp:focused(),
    }
  end

  return workspaces
end

function workspaces_by_output()
  local outputs = Output.get_all()
  local tag_map = {}

  for i, outp in ipairs(outputs) do
    local workspaces = get_workspaces(outp)
    tag_map[outp.name] = ' (box :orientation "h" :class "workspaces"'
    for i, tag in ipairs(workspaces) do
      ws = tag.name
      class = ''
      if(tag.is_focused)
      then
        class = '"focused"'
        if(tag.is_active)
        then
          class = '"urgent"'
        end
      elseif(tag.is_active)
      then
        class = '"occupied"'
      else
        class = '"empty"'
      end

      switch_to = ' :onclick "./modules/switch-to.sh ' .. ws .. '"'
      button = '(button :class ' .. class .. switch_to  .. ' "' .. ws .. '"' .. ')'
      tag_map[outp.name] = tag_map[outp.name] .. ' (eventbox :cursor "hand" ' .. button .. ')'
    end
    tag_map[outp.name] = tag_map[outp.name] .. ")"
  end

  return tag_map
end

print(cjson.encode(workspaces_by_output()))

pinnacle.setup(function ()
  Window.connect_signal({
    focused = function(win)
      print(cjson.encode(workspaces_by_output()))
    end
  })
end)
