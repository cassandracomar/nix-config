{ config, lib, pkgs, ... }:

{
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.extraConfig = ''
    load-module module-alsa-sink device=hw:0,0 channels=4
    load-module module-alsa-source device=hw:0,6 channels=4
    load-module module-echo-cancel aec_method='webrtc'
  '';
  hardware.pulseaudio.daemon.config = { resample-method = "speex-float-10"; };
  # services.jack = {
  #   jackd.enable = true;
  #   # support ALSA only programs via ALSA JACK PCM plugin
  #   alsa.enable = false;
  #   # support ALSA only programs via loopback device (supports programs like Steam)
  #   loopback = {
  #     enable = true;
  #     # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
  #     #dmixConfig = ''
  #     #  period_size 2048
  #     #'';
  #   };
  # };
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   jack.enable = true;
  #   pulse.enable = true;
  #   socketActivation = true;
  # };
}
