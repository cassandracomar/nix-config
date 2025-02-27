{
  stdenv,
  lib,
  fetchFromGitHub,
  kernelPackage,
}:
stdenv.mkDerivation rec {
  name = "corefreq-${version}-${kernelVersion}";
  version = "1.98.0";

  src = fetchFromGitHub {
    owner = "cyring";
    repo = "CoreFreq";
    rev = version;
    sha256 = "sha256-s3HSKrN90T6R7SF5VoybwzgF+mBcDVybTMIdtqo0AFY=";
  };

  nativeBuildInputs = kernelPackage.moduleBuildDependencies;
  kernel = kernelPackage.dev;
  kernelVersion = kernelPackage.modDirVersion;

  patches = [./corefreq-fix.patch];

  makeFlags = [
    "KERNELREL=${kernel}/lib/modules/${kernelVersion}"
    "INSTALL_MOD_PATH=$(out)"
    "PREFIX=$(out)"
    "-j"
  ];

  meta = with lib; {
    description = "CoreFreq, a CPU monitoring software with BIOS like functionalities";
    homepage = "https://github.com/cyring/CoreFreq";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
