{
  fetchurl,
  libunwind,
  gflags,
  openssl,
  elfutils,
  zstd,
  protobufc,
  protobuf_29,
  cmake,
  clang,
  git,
  pkg-config,
  ninja,
  autoPatchelfHook,
  stdenv,
  python3,
  zlib,
  lib,
}:
stdenv.mkDerivation {
  name = "autofdo";
  version = "0.30.1";
  src = fetchurl {
    url = "https://github.com/google/autofdo/releases/download/v0.30.1/create_llvm_prof-x86_64-v0.30.1.zip";
    sha256 = "sha256-jhBOa0iB6sZZY22uF6ZmivXQI6HY3+Atf1pN+CiDj7A=";
  };
  buildInputs = [libunwind gflags openssl openssl.dev elfutils zstd.dev zstd protobufc protobufc.dev elfutils.dev zlib];
  nativeBuildInputs = [protobuf_29 cmake clang git pkg-config ninja autoPatchelfHook python3];
  # cmakeFlags = [
  #   "-DENABLE_TOOL=LLVM"
  #   "-DCMAKE_C_COMPILER=clang"
  #   "-DCMAKE_CXX_COMPILER=clang++"
  #   "-DCMAKE_BUILD_TYPE=Release"
  #   # "-DBUILD_SHARED=On"
  #   "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
  # ];
  installPhase = ''
    ls -l
    exit 1
  '';

  # postInstall = ''
  #   ls -l
  #   ls -l bin/
  #   mkdir -p $out/bin
  #   install -m755 create_llvm_prof $out/bin/
  #   install -m755 profile_merger $out/bin/profile_merger
  #   install -m644 libperf_proto.a $out/lib/libperf_proto.a
  #   install -m644 libperf_proto.so $out/lib/libperf_proto.so
  #   install -m644 third_party/glog/libglog.so.1 $out/lib/libglog.so.1
  #   install -m644 *.so $out/lib/
  #   install -m644 *.a $out/lib/
  #   ldd create_llvm_prof
  # '';

  # fixupPhase = ''
  #   addAutoPatchelfSearchPath $out/lib/
  #   autoPatchelf $out/bin/*
  # '';
}
