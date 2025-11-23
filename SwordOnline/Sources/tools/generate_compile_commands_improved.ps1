# Improved generation of compile_commands.json for MSVC .vcxproj files
# Produces clang-style compile commands with MSVC-compatible flags for clang-tidy
$root = "C:\games\source\study\source-jxwin-visualstudio2022\jx1\SwordOnline\Sources"
Set-Location $root

$projects = Get-ChildItem -Recurse -Filter *.vcxproj
$entries = @()

function Normalize-PathEntry([string]$entry, [string]$projDir) {
  $entry = $entry.Trim()
  if ($entry -eq '' -or $entry -match '%\(') { return $null }
  # split ; and remove trailing %\(AdditionalIncludeDirectories) tokens
  $parts = $entry -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
  $out = @()
  foreach ($p in $parts) {
    if ($p -match '%\(') { continue }
    # Expand relative paths
    $candidate = $p
    try {
      if (-not [System.IO.Path]::IsPathRooted($candidate)) { $candidate = Join-Path $projDir $candidate }
      $resolved = Resolve-Path -Path $candidate -ErrorAction SilentlyContinue
      if ($resolved) { $out += $resolved.ProviderPath } else { $out += $candidate }
    } catch { $out += $candidate }
  }
  return $out
}

foreach ($proj in $projects) {
  try { $xml = [xml](Get-Content $proj.FullName) } catch { continue }
  $projDir = Split-Path $proj.FullName -Parent

  # collect default and configuration-specific include dirs and defines
  $includeDirs = @()
  $defines = @()

  foreach ($id in $xml.Project.ItemDefinitionGroup) {
    $cond = ""
    if ($id.Attributes) { $cond = $id.Attributes['Condition'] }
    $cl = $id.ClCompile
    if ($cl -ne $null) {
      if ($cl.AdditionalIncludeDirectories) { $includeDirs += $cl.AdditionalIncludeDirectories.'#text' }
      if ($cl.PreprocessorDefinitions) { $defines += $cl.PreprocessorDefinitions.'#text' }
      if ($cl.AdditionalOptions) { $defines += $cl.AdditionalOptions.'#text' }
    }
  }

  $resolvedIncludes = @()
  foreach ($inc in $includeDirs) {
    $norm = Normalize-PathEntry $inc $projDir
    if ($norm) { $resolvedIncludes += $norm }
  }
  $resolvedIncludes = $resolvedIncludes | Select-Object -Unique

  $resolvedDefines = @()
  foreach ($d in $defines) {
    $parts = $d -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    foreach ($p in $parts) {
      if ($p -match '%\(') { continue }
      # remove trailing semicolons etc
      $clean = $p -replace '\\r\\n','' -replace '\\n',''
      $resolvedDefines += $clean
    }
  }
  $resolvedDefines = $resolvedDefines | Select-Object -Unique

  # gather source files
  $clFiles = @()
  foreach ($ig in $xml.Project.ItemGroup) {
    if ($ig.ClCompile) {
      foreach ($c in $ig.ClCompile) { if ($c.Include) { $clFiles += $c.Include } }
    }
  }

  foreach ($f in $clFiles) {
    $full = Join-Path $projDir $f
    if (-not (Test-Path $full)) { continue }
    $cmd = 'clang++ -x c++ -fms-compatibility -fms-extensions -std=c++17 -c "' + $full + '"'
    foreach ($inc in $resolvedIncludes) { $cmd += ' -I"' + $inc + '"' }
    foreach ($d in $resolvedDefines) {
      # split define=value
      if ($d -match '=') { $pair = $d -split '='; $cmd += ' -D' + $pair[0] + '=' + $pair[1] } else { $cmd += ' -D' + $d }
    }
    $entries += @{ directory = $projDir; file = $full; command = $cmd }
  }
}

$entries | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 compile_commands.json
Write-Output "Wrote improved compile_commands.json with $($entries.Count) entries to $root\compile_commands.json"