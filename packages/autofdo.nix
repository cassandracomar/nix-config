{
  fetchFromGitHub,
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
}:
stdenv.mkDerivation {
  name = "autofdo";
  version = "0.30.1";
  src = fetchFromGitHub {
    owner = "google";
    repo = "autofdo";
    rev = "d4daf249aad2531ac3c96d2a3c46cb75c00bfcb2";
    sha256 = "sha256-HCT8LPu48Vd/CS+G53vPk7tDQAmd7zANtcItHaniYnA=";
    fetchSubmodules = true;
  };
  buildInputs = [libunwind gflags openssl openssl.dev elfutils zstd.dev zstd protobufc protobufc.dev elfutils.dev];
  nativeBuildInputs = [protobuf_29 cmake clang git pkg-config ninja autoPatchelfHook python3];
  cmakeFlags = [
    "-DENABLE_TOOL=LLVM"
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED=On"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
  ];

  postInstall = ''
    ls -l
    ls -l bin/
    mkdir -p $out/bin
    install -m755 create_llvm_prof $out/bin/
    ldd create_gcov
    install -m755 profile_merger $out/bin/profile_merger
    install -m644 libperf_proto.a $out/lib/libperf_proto.a
    install -m644 libperf_proto.so $out/lib/libperf_proto.so
    install -m644 third_party/glog/libglog.so.1 $out/lib/libglog.so.1
  '';

  fixupPhase = ''
    addAutoPatchelfSearchPath $out/lib/
    autoPatchelf $out/bin/*
  '';
}
