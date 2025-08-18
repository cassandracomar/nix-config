{
  stdenv,
  lib,
  fetchFromGitHub,
  kernelPackage,
}:
stdenv.mkDerivation rec {
  name = "corefreq-${version}-${kernelVersion}";
  version = "2.0.8";

  src = fetchFromGitHub {
    owner = "cyring";
    repo = "CoreFreq";
    rev = version;
    sha256 = "sha256-8uCs/Jj208qUtmpiorxtii+0VOfK/EgrcylmJMkcqUQ=";
  };

  patches = [./corefreq-fix.patch];

  nativeBuildInputs = kernelPackage.moduleBuildDependencies;
  kernel = kernelPackage.dev;
  kernelVersion = kernelPackage.modDirVersion;

  makeFlags = [
    "KERNELREL=${kernel}/lib/modules/${kernelVersion}"
    "INSTALL_MOD_PATH=$(out)"
    "PREFIX=$(out)"
    "CORE_COUNT=1024"
    "-j"
  ];

  preInstall = ''
    mkdir -p $out/bin
  '';

  meta = with lib; {
    description = "CoreFreq, a CPU monitoring software with BIOS like functionalities";
    homepage = "https://github.com/cyring/CoreFreq";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
