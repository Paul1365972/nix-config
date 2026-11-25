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

Link "$HOME\.gemini\config\skills" "$paul\skills"

$contexts = @("$HOME\.claude\CLAUDE.md", "$HOME\.codex\AGENTS.md", "$HOME\.config\opencode\AGENTS.md", "$HOME\.gemini\AGENTS.md")
# T3 Code runs Antigravity with a private --gemini-dir per provider instance, so ~/.gemini/AGENTS.md never reaches it.
$contexts += Get-ChildItem "$HOME\.t3\userdata\providers\antigravity" -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { "$($_.FullName)\AGENTS.md" }
foreach ($file in $contexts) {
    Link $file "$paul\AGENTS.md"
}
