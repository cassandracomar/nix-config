{pkgs, ...}: {
  # hardware.pulseaudio.enable = true;
  # hardware.pulseaudio.package = pkgs.pulseaudioFull;
  # hardware.pulseaudio.extraConfig = ''
  #   load-module module-alsa-sink device=hw:0,0 channels=4
  #   load-module module-alsa-source device=hw:0,6 channels=4
  #   load-module module-echo-cancel aec_method='webrtc'
  # '';
  # hardware.pulseaudio.daemon.config = { resample-method = "speex-float-10"; };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
