$root = "C:\games\source\study\source-jxwin-visualstudio2022\jx1\SwordOnline\Sources"
Set-Location $root
$clang = 'C:\Program Files\LLVM\bin\clang-tidy.exe'
$checks = "-*,modernize-use-nullptr,modernize-loop-convert,modernize-pass-by-value,modernize-make-unique"
if (-not (Test-Path $clang)) { Write-Error "clang-tidy not found at $clang"; exit 1 }
if (-not (Test-Path "compile_commands.json")) { Write-Error "compile_commands.json not found in $root"; exit 1 }
Remove-Item -ErrorAction Ignore clang-tidy-full.log
$files = Get-ChildItem -Recurse -Filter *.cpp
foreach ($f in $files) {
  Write-Output "Running: $($f.FullName)"
  & $clang -p . -fix -fix-errors -checks=$checks -- "$($f.FullName)" 2>&1 | Out-File -Append clang-tidy-full.log
}
Write-Output "Done. See clang-tidy-full.log for details."