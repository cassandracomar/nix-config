{
  runCommand,
  binary,
  data,
}:
runCommand "output.afdo" {} ''
  ${./create_llvm_prof} --binary=${binary} --profile=${data} --format=extbinary --out=$out
''
