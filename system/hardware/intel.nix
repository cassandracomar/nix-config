{
  config,
  lib,
  pkgs,
  ...
}: {
  hardware.opengl.extraPackages = with pkgs; [vaapiIntel intel-ocl];

  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [vaapiIntel];
}
