$ErrorActionPreference = 'Stop'
$paul = (Resolve-Path "$PSScriptRoot\..\modules\users\paul").Path
$skills = Get-ChildItem "$paul\skills" -Directory

function Link($path, $target) {
    $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ("$($existing.Target)" -eq $target) { return }
    if ($existing -and -not $existing.LinkType) { throw "Not a link: $path" }
    if ($existing) { $existing.Delete() }
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $arguments = @($path, $target)
    if (Test-Path -LiteralPath $target -PathType Container) { $arguments = @('/J') + $arguments }
    cmd /c mklink @arguments | Out-Null
    if ($LASTEXITCODE) { throw "Could not link $path" }
    Write-Host "Linked $path"
}

foreach ($agent in "$HOME\.claude", "$HOME\.codex") {
    Get-ChildItem "$agent\skills" -Force -ErrorAction SilentlyContinue |
        Where-Object { "$($_.Target)".StartsWith("$paul\skills\", 'OrdinalIgnoreCase') -and -not (Test-Path -LiteralPath $_.Target) } |
        ForEach-Object { $_.Delete(); Write-Host "Unlinked $($_.FullName)" }
    foreach ($skill in $skills) { Link "$agent\skills\$($skill.Name)" $skill.FullName }
}

foreach ($file in "$HOME\.claude\CLAUDE.md", "$HOME\.codex\AGENTS.md", "$HOME\.config\opencode\AGENTS.md") {
    Link $file "$paul\context.md"
}
