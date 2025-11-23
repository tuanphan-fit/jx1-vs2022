$root = "C:\games\source\study\source-jxwin-visualstudio2022\jx1\SwordOnline\Sources"
Set-Location $root
$projects = Get-ChildItem -Recurse -Filter *.vcxproj
$entries = @()
foreach ($proj in $projects) {
  try {
    $xml = [xml](Get-Content $proj.FullName)
  } catch { continue }
  $projDir = Split-Path $proj.FullName -Parent
  $includeDirs = @()
  $defines = @()
  $itemDefs = $xml.Project.ItemDefinitionGroup
  foreach ($id in $itemDefs) {
    $cl = $id.ClCompile
    if ($cl -ne $null) {
      if ($cl.AdditionalIncludeDirectories) { $includeDirs += $cl.AdditionalIncludeDirectories }
      if ($cl.PreprocessorDefinitions) { $defines += $cl.PreprocessorDefinitions }
    }
  }
  # normalize include dirs
  $resolvedIncludes = @()
  foreach ($entry in $includeDirs) {
    $parts = $entry -split ';'
    foreach ($p in $parts) {
      $p = $p.Trim()
      if ($p -eq '' -or $p -match '%\(') { continue }
      # replace MSBuild macros if present
      $p = $p -replace '\$\(ProjectDir\)', ''
      $abs = Join-Path $projDir $p
      if (Test-Path $abs) { $resolvedIncludes += (Resolve-Path $abs).ProviderPath } else { $resolvedIncludes += $p }
    }
  }
  # normalize defines
  $resolvedDefines = @()
  foreach ($dentry in $defines) {
    $parts = $dentry -split ';'
    foreach ($d in $parts) {
      $d = $d.Trim()
      if ($d -eq '' -or $d -match '%\(') { continue }
      $resolvedDefines += $d
    }
  }
  # get compile files
  $clFiles = @()
  foreach ($ig in $xml.Project.ItemGroup) {
    if ($ig.ClCompile) {
      foreach ($c in $ig.ClCompile) { if ($c.Include) { $clFiles += $c.Include } }
    }
  }
  foreach ($f in $clFiles) {
    $full = Join-Path $projDir $f
    if (-not (Test-Path $full)) { continue }
    $cmd = 'clang++ -std=c++17 -fms-compatibility -fms-extensions -c ' + '"' + $full + '"'
    foreach ($inc in $resolvedIncludes) { $cmd += ' -I"' + $inc + '"' }
    foreach ($d in $resolvedDefines) {
      $pair = $d -split '='
      if ($pair.Length -eq 2) { $cmd += ' -D' + $pair[0] + '=' + $pair[1] } else { $cmd += ' -D' + $d }
    }
    $entries += @{ directory = $projDir; file = $full; command = $cmd }
  }
}
$entries | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 compile_commands.json
Write-Output "Wrote compile_commands.json with $($entries.Count) entries to $root\compile_commands.json"