# Install omp-custom on Windows: installs omp when missing, then copies the config.
# Run from a checkout:  powershell -ExecutionPolicy Bypass -File .\install.ps1
# Or pipe:              irm https://raw.githubusercontent.com/quangtiss/omp-custom/main/install.ps1 | iex
$ErrorActionPreference = "Stop"

$RepoSlug = "quangtiss/omp-custom"
$Ref = "main"

$AgentDir = if ($env:OMP_AGENT_DIR) { $env:OMP_AGENT_DIR }
            elseif ($env:PI_CODING_AGENT_DIR) { $env:PI_CODING_AGENT_DIR }
            else { Join-Path $HOME ".omp/agent" }

$DownloadedDir = $null
function Get-RepoDir {
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "config/config.yml"))) {
        return $PSScriptRoot
    }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("omp-custom-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $zip = Join-Path $tmp "repo.zip"
    Write-Host "Downloading omp-custom ($Ref)..."
    Invoke-WebRequest -UseBasicParsing "https://codeload.github.com/$RepoSlug/zip/refs/heads/$Ref" -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $repo = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
    if (-not $repo) { throw "Could not unpack the omp-custom archive." }
    $script:DownloadedDir = $tmp
    return $repo.FullName
}

function Install-File([string]$Source, [string]$Rel) {
    $dest = Join-Path $AgentDir $Rel
    if ((Test-Path $dest) -and ((Get-FileHash $dest).Hash -ne (Get-FileHash $Source).Hash)) {
        $backupPath = Join-Path $BackupDir $Rel
        New-Item -ItemType Directory -Force -Path (Split-Path $backupPath) | Out-Null
        Copy-Item -Force $dest $backupPath
        Write-Host "backup:    $Rel"
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item -Force $Source $dest
    Write-Host "installed: $Rel"
}

try {
    $RepoDir = Get-RepoDir

    if (-not (Get-Command omp -ErrorAction SilentlyContinue)) {
        Write-Host "omp not found; installing from https://omp.sh/install.ps1 ..."
        Invoke-Expression (Invoke-RestMethod "https://omp.sh/install.ps1")
        $env:Path = "$env:LOCALAPPDATA\omp;$env:Path"
    }

    if (-not (Get-Command omp -ErrorAction SilentlyContinue)) {
        throw "omp is still not on PATH. Open a new terminal and run this script again."
    }

    $BackupDir = Join-Path (Join-Path $AgentDir "backups") (Get-Date -Format "yyyyMMdd-HHmmss")
    New-Item -ItemType Directory -Force -Path (Join-Path $AgentDir "extensions") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $AgentDir "themes") | Out-Null

    Install-File (Join-Path $RepoDir "config/config.yml") "config.yml"
    Install-File (Join-Path $RepoDir "config/models.yml") "models.yml"
    Install-File (Join-Path $RepoDir "config/mcp.json") "mcp.json"

    Get-ChildItem -Path (Join-Path $RepoDir "extensions") -Filter *.ts | ForEach-Object {
        Install-File $_.FullName ("extensions/" + $_.Name)
    }
    Get-ChildItem -Path (Join-Path $RepoDir "themes") -Filter *.json | ForEach-Object {
        Install-File $_.FullName ("themes/" + $_.Name)
    }

    if (Test-Path $BackupDir) {
        Write-Host "Previous files backed up to: $BackupDir"
    }

    $modelsPath = Join-Path $AgentDir "models.yml"
    if (Select-String -Path $modelsPath -Pattern "PASTE_VECTOR_API_KEY_HERE" -Quiet) {
        Write-Host ""
        Write-Host "Note: provider 'vector' in $modelsPath still uses the API key placeholder."
        Write-Host "Replace PASTE_VECTOR_API_KEY_HERE with your key, then start omp."
        Write-Host "Do not commit a real key to the repo."
    }

    Write-Host "Done. Run 'omp' to verify."
}
finally {
    if ($DownloadedDir) {
        Remove-Item -Recurse -Force $DownloadedDir -ErrorAction SilentlyContinue
    }
}