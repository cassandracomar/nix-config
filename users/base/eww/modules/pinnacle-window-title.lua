function get_active_window_title(win)
  print(win:title())
end

get_active_window_title(Window.get_focused())

pinnacle.setup(function()
  Window.connect_signal({
    focused = get_active_window_title
  })
end)
