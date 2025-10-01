#!/usr/bin/env sh

get_icon_for() {
  APP="$1"
  icon_content="(image :icon '${APP,,}' :icon-size 'large-toolbar')"

  # for d in $(echo "$XDG_DATA_DIRS" | sed 's/:/\n/g');
  # do
  #     applications_dir="$d/applications"
  #     if [ -d "$applications_dir" ];
  #     then
  #       for f in $(find "$applications_dir" -type f);
  #       do
  #           application=$(cat "$f")
  #           application_name=$(echo "$application" | sed -n 's/^Name=\(.*\)$/\1/p')
  #           if [[ "$application_name" == "$APP" ]];
  #           then
  #               icon=$(echo "$application" | sed -n 's/^Icon=\(.*\)$/\1/p')
  #               echo "icon: $icon" >/dev/stderr
  #               if [ -f $icon ];
  #               then
  #                 # the icon is a path to a file
  #                 icon_content=$(echo "(image :path '$icon' :image-width 24 :image-height 24)")
  #               fi
  #               break 2;
  #           fi
  #       done
  #     fi
  # done

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
