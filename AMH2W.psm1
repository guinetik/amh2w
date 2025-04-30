# AMH2W.psm1 — Module Entrypoint

# Determine module root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 1) Dot-source every .ps1 under core\ (recursively)
Get-ChildItem -Path (Join-Path $scriptDir 'core') `
              -Filter '*.ps1' -File -Recurse |
  ForEach-Object { . $_.FullName }

# 2) Dot-source every .ps1 under all\ (recursively)
Get-ChildItem -Path (Join-Path $scriptDir 'all') `
              -Filter '*.ps1' -File -Recurse |
  ForEach-Object { . $_.FullName }

# 3) Export every function loaded
Export-ModuleMember -Function *
