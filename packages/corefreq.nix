{ zsh, stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  name = "corefreq-${version}-${kernel.version}";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "cyring";
    repo = "CoreFreq";
    rev = "develop";
    sha256 = "sha256-DZiBRg7QNbf+DKRzGPxzp9/irqyr0WW8n8LtOwQ7bHE=";
  };

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;                       # 2

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
    "PREFIX=$(out)"
  ];

  meta = with lib; {
    description = "A kernel module to create V4L2 loopback devices";
    homepage = "https://github.com/aramg/droidcam";
    license = licenses.gpl2;
    maintainers = [ maintainers.makefu ];
    platforms = platforms.linux;
  };
}
