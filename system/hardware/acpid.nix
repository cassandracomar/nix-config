{ config, lib, pkgs, ... }:

{
  services.acpid.handlers = {
    volume-down = {
      event = "button/volumedown";
      action = ''
        ${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pulseaudioFull}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%

        perc=$(${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pamixer}/bin/pamixer --get-volume)
        volume_id=
        if [ "$perc" -gt 100 ]; then
          volume_id='audio-volume-overamplified-rtl-symbolic.symbolic'
        elif [ "$perc" -gt 66 ]; then
          volume_id='audio-volume-high-rtl-symbolic.symbolic'
        elif [ "$perc" -gt 33 ]; then
          volume_id='audio-volume-medium-rtl-symbolic.symbolic'
        elif [ "$perc" -gt 0 ]; then
          volume_id='audio-volume-low-rtl-symbolic.symbolic'
        else
          volume_id='audio-volume-muted-rtl-symbolic.symbolic'
        fi
        ${pkgs.sudo}/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i $volume_id -h int:value:$perc -h string:x-canonical-private-synchronous:volume &
      '';
    };
    volume-up = {
      event = "button/volumeup";
      action = ''
        ${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pulseaudioFull}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%

        perc=$(${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pamixer}/bin/pamixer --get-volume)
        volume_id=
        if [ "$perc" -gt 100 ]; then
          volume_id='audio-volume-overamplified-rtl-symbolic.symbolic'
        elif [ "$perc" -gt 66 ]; then
          volume_id='audio-volume-high-rtl-symbolic.symbolic'
        elif [ "$perc" -gt 33 ]; then
          volume_id='audio-volume-medium-rtl-symbolic.symbolic'
        elif [ "$perc" -gt 0 ]; then
          volume_id='audio-volume-low-rtl-symbolic.symbolic'
        else
          volume_id='audio-volume-muted-rtl-symbolic.symbolic'
        fi
        ${pkgs.sudo}/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i $volume_id -h int:value:$perc -h string:x-canonical-private-synchronous:volume &
      '';
    };
    button-mute = {
      event = "button/mute";
      action = ''
        ${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pulseaudioFull}/bin/pactl set-sink-mute @DEFAULT_SINK@

        perc=$(${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pamixer}/bin/pamixer --get-volume)
        volume_id='audio-volume-muted-rtl-symbolic.symbolic'
        ${pkgs.sudo}/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i $volume_id -h int:value:$perc -h string:x-canonical-private-synchronous:volume &
      '';
    };
  };
}
