{ zsh, stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  name = "corefreq-${version}-${kernel.version}";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "cyring";
    repo = "CoreFreq";
    rev = "master";
    sha256 = "sha256-PsFoZiJ69ZxCzh8eAR+ma1xn4/UqswH4kyGbIolRfaM=";
  };

  patches = [ ./corefreq-fix.patch ];

  nativeBuildInputs = kernel.moduleBuildDependencies; # 2

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
    "PREFIX=$(out)"
  ];

  meta = with lib; {
    description = "CoreFreq, a CPU monitoring software with BIOS like functionalities";
    homepage = "https://github.com/cyring/CoreFreq";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
