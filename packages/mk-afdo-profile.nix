{
  runCommand,
  llvm,
  profileGeneration,
  kernel,
  perf,
  runtimeShell,
}: let
  kernelBuild = kernel.overrideAttrs (old: {
    name = "${old.name}-${profileGeneration}";
    buildPhase = ''
      ${perf}/bin/perf record -e cpu/event=0xc4,umask=0x0,name=br_inst_retired.taken/ -a -N -b -c 500009 -o kernel.data -- ${runtimeShell} -c "make ${builtins.concatStringsSep " " old.buildFlags}"
    '';
    postInstall = ''
      ${old.postInstall or ""}
      mkdir -p $dev
      install -m644 kernel.data $dev/kernel.data
    '';
    preferLocalBuild = true;
  });
in
  runCommand "${kernel.version}-${profileGeneration}-output.afdo" {} ''
    ${llvm}/bin/llvm-profgen --kernel --binary=${kernelBuild.dev}/vmlinux --profile=${kernelBuild.dev}/kernel.data --format=extbinary --out=$out
  ''
