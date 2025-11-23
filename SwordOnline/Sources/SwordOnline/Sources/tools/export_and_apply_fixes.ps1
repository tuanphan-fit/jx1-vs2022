# Export clang-tidy fixes for each .cpp and apply them non-interactively
# Script location is used as root
$scriptPath = $MyInvocation.MyCommand.Definition
$root = Split-Path -Path $scriptPath -Parent
Set-Location $root

$clang = 'C:\Program Files\LLVM\bin\clang-tidy.exe'
$apply = 'C:\Program Files\LLVM\bin\clang-apply-replacements.exe'

if (-not (Test-Path -Path $clang)) {
  Write-Error "clang-tidy not found at: $clang"
  exit 1
}
if (-not (Test-Path -Path $apply)) {
  Write-Error "clang-apply-replacements not found at: $apply"
  exit 1
}

$checks = '-*,modernize-use-nullptr,modernize-loop-convert,modernize-pass-by-value,modernize-make-unique'
$fixdir = Join-Path -Path $root -ChildPath 'clang-fixes'

if (Test-Path -Path $fixdir) { Remove-Item -Recurse -Force -Path $fixdir }
New-Item -ItemType Directory -Path $fixdir | Out-Null

# Ensure compile_commands.json exists
if (-not (Test-Path -Path (Join-Path $root 'compile_commands.json'))) {
  Write-Error "compile_commands.json not found in $root. Run the generate script first."
  exit 1
}

Get-ChildItem -Recurse -Filter *.cpp | ForEach-Object {
  $file = $_.FullName
  $yaml = Join-Path -Path $fixdir -ChildPath ($_.BaseName + '.yaml')
  Write-Output "Exporting fixes for: $file -> $yaml"
  & "${clang}" -p "$root" -export-fixes="$yaml" -checks="$checks" -- "$file" 2>&1 | Tee-Object -FilePath clang-tidy-export.log -Append
}

Write-Output "Applying fixes from: $fixdir"
& "${apply}" "$fixdir" 2>&1 | Tee-Object -FilePath clang-tidy-export.log -Append

Write-Output 'Done. Inspect clang-tidy-export.log and run git status to see modified files.'