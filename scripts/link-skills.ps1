$ErrorActionPreference = 'Stop'
$skills = Get-ChildItem "$PSScriptRoot/../modules/users/paul/skills" -Directory

foreach ($app in @('.codex', '.claude')) {
    $directory = Join-Path $env:USERPROFILE "$app/skills"
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    foreach ($skill in $skills) {
        $path = Join-Path $directory $skill.Name
        $link = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($link) {
            if ($link.LinkType -ne 'Junction') { throw "Refusing to replace directory: $path" }
            if ($link.Target[0] -eq $skill.FullName) { continue }
            [IO.Directory]::Delete($path, $false)
        }
        New-Item -ItemType Junction -Path $path -Target $skill.FullName | Out-Null
        Write-Host "Linked $path"
    }
}
