{
  stdenv,
  lib,
  fetchFromGitHub,
  kernelPackage,
}:
stdenv.mkDerivation rec {
  name = "corefreq-${version}-${kernelVersion}";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "cyring";
    repo = "CoreFreq";
    tag = "2.1.2";
    sha256 = "sha256-nCkQ03/h3uP0KcX1sTaOdaB1Eh9tBZgLnJu8AoRAa04=";
  };

  patches = [./corefreq-fix.patch];

  buildInputs = kernelPackage.moduleBuildDependencies;
  kernel = kernelPackage.dev;
  kernelVersion = kernelPackage.modDirVersion;

  env.NIX_CFLAGS_COMPILE = "-I${src}/${stdenv.hostPlatform.qemuArch}";
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
  installFlags = ["PREFIX=$(out)"];

  meta = with lib; {
    description = "CoreFreq, a CPU monitoring software with BIOS like functionalities";
    homepage = "https://github.com/cyring/CoreFreq";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
