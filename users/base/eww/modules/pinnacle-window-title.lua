function get_active_window_title(win)
  if (win ~= nil)
  then
    print(win:title())
  end
end

get_active_window_title(Window.get_focused())

Pinnacle.setup(function()
  Window.connect_signal({
    focused = function(win)
      get_active_window_title(win)
    end,
    pointer_enter = function(win)
      get_active_window_title(win)
    end,
    pointer_leave = function(win)
      get_active_window_title(win)
    end
  })
  Tag.connect_signal({
    active = function(tag, active)
      get_active_window_title(Window.get_focused())
    end
  })
  Output.connect_signal({
    focused = function(outp)
      get_active_window_title(Window.get_focused())
    end
  })
end)
