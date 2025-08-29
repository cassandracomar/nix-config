local cjson = require("cjson")

-- turn a table whos entries are themselves tables/arrays into a flat array
-- i.e. [[1,2,3], [4, 5, 6]] -> [1, 2, 3, 4, 5, 6]
-- this only removes a single level of nesting
function flatten(t)
  local res = {}
  for _, v in pairs(t) do
    for _, e in pairs(v) do
      table.insert(res, e)
    end
  end

  return res
end

-- get the windows on all active tags on the output
function windows_for_output(output)
  local tags = output:active_tags()
  local windows = {}

  for _, tag in ipairs(tags) do
    windows[tag:name()] = tag:windows()
  end

  return flatten(windows)
end

-- get a table from the output name to the windows active on that output
function windows_for_all_outputs()
  local outputs = Output.get_all()
  local windows = {}
  for _, output in ipairs(outputs) do
    windows[output.name] = windows_for_output(output)
  end

  return windows
end

-- turn the window into a tab bar button
function make_tab(window)
  local class = ':class "tab" '
  local switch_to = ':onclick "./modules/focus-window.sh ' .. window.id .. '" '
  local label = '(label :class "title" :show-truncated true "' .. window:title() .. '")'
  local button = '(button ' .. class .. switch_to .. label .. ')'

  return button
end

-- turn a list of windows into a tab bar, excluding the focused window
function make_tab_bar(windows)
  local tab_bar = '(box :class "tab-bar" :orientation "h" :space-evenly true'
  for i, window in ipairs(windows) do
    if (not window:focused()) then
      tab_bar = tab_bar .. ' ' .. make_tab(window)
    end
  end

  return tab_bar .. ')'
end

-- get tab bars for each output
function get_tab_bars()
  local windows_by_output = windows_for_all_outputs()
  local tab_bars = {}
  for outp, windows in pairs(windows_by_output) do
    tab_bars[outp] = {}
    for _, window in ipairs(windows) do
      local w = {}
      w["title"] = window:title()
      w["id"] = window:id()
      table.insert(tab_bars[outp], w)
    end
  end

  return cjson.encode(tab_bars)
end

print(get_tab_bars())

Pinnacle.setup(function ()
  Window.connect_signal({
    focused = function(win)
      print(get_tab_bars())
    end,
    pointer_enter = function(win)
      print(get_tab_bars())
    end,
    pointer_leave = function(win)
      print(get_tab_bars())
    end
  })
  Tag.connect_signal({
      active = function(tag, active)
        print(get_tab_bars())
      end
  })
  Output.connect_signal({
      focused = function(outp)
        print(get_tab_bars())
      end
  })
end)
