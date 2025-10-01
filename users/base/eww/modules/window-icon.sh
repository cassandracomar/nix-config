#!/usr/bin/env sh

get_icon_for() {
  APP="$1"
  icon_content="(image :icon '${APP,,}' :icon-size 'large-toolbar')"

  echo "$icon_content"
}

map_icons() {
    while IFS= read -r app;
    do
        get_icon_for "$app"
    done
}

watch_app_id() {
    pinnacle client <./modules/pinnacle-window-app-id.lua
}

watch_app_id | map_icons
