function get_active_window_app_id(win)
  app_id = win ~= nil and win:app_id() or ""
  print(app_id)
end

get_active_window_app_id(Window.get_focused())

Pinnacle.setup(function()
  Window.connect_signal({
    focused = function(win)
      get_active_window_app_id(win)
    end,
    pointer_enter = function(win)
      get_active_window_app_id(win)
    end,
    pointer_leave = function(win)
      get_active_window_app_id(win)
    end,
    title_changed = function(win)
      get_active_window_app_id(win)
    end
  })
  Tag.connect_signal({
    active = function(tag, active)
      get_active_window_app_id(Window.get_focused())
    end
  })
  Output.connect_signal({
    focused = function(outp)
      get_active_window_app_id(Window.get_focused())
    end
  })
end)
