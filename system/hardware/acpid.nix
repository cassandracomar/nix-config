{ config, lib, pkgs, ... }:

{
  services.acpid.handlers = {
    volume-down = {
      event = "button/volumedown";
      action =
        "${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pulseaudioFull}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
    };
    volume-up = {
      event = "button/volumeup";
      action =
        "${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pulseaudioFull}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
    };
    button-mute = {
      event = "button/mute";
      action =
        "${pkgs.sudo}/bin/sudo -u cassandra XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.pulseaudioFull}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
    };
    brightness-down = {
      event = "video/brightnessdown";
      action = "${pkgs.brightnessctl}/bin/brightnessctl s 5%-";
    };
    brightness-up = {
      event = "video/brightnessup";
      action = "${pkgs.brightnessctl}/bin/brightnessctl s 5%+";
    };
  };
}
