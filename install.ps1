# Install omp-custom on Windows: installs omp when missing, then copies the config.
# Run from a checkout:  powershell -ExecutionPolicy Bypass -File .\install.ps1
# Or pipe:              irm https://raw.githubusercontent.com/quangtiss/omp-custom/main/install.ps1 | iex
$ErrorActionPreference = "Stop"

$RepoSlug = "quangtiss/omp-custom"
$Ref = "main"

$AgentDir = if ($env:OMP_AGENT_DIR) { $env:OMP_AGENT_DIR }
            elseif ($env:PI_CODING_AGENT_DIR) { $env:PI_CODING_AGENT_DIR }
            else { Join-Path $HOME ".omp/agent" }
$SourcesDir = Join-Path $HOME ".omp/sources"

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

function Install-File([string]$Source, [string]$Dest, [string]$Rel) {
    if ((Test-Path $Dest) -and ((Get-FileHash $Dest).Hash -ne (Get-FileHash $Source).Hash)) {
        $backupPath = Join-Path $BackupDir $Rel
        New-Item -ItemType Directory -Force -Path (Split-Path $backupPath) | Out-Null
        Copy-Item -Force $Dest $backupPath
        Write-Host "backup:    $Rel"
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    Copy-Item -Force $Source $Dest
    Write-Host "installed: $Rel"
}

function Install-Tree([string]$SourceRoot, [string]$DestRoot, [string]$RelPrefix) {
    Get-ChildItem -Path $SourceRoot -File -Recurse -Force | ForEach-Object {
        $rel = $_.FullName.Substring($SourceRoot.Length).TrimStart([char[]]@('\', '/'))
        Install-File $_.FullName (Join-Path $DestRoot $rel) (($RelPrefix + '/' + $rel) -replace '\\', '/')
    }
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

    Install-File (Join-Path $RepoDir "config/config.yml") (Join-Path $AgentDir "config.yml") "config.yml"
    Install-File (Join-Path $RepoDir "config/models.yml") (Join-Path $AgentDir "models.yml") "models.yml"
    Install-File (Join-Path $RepoDir "config/mcp.json") (Join-Path $AgentDir "mcp.json") "mcp.json"

    Get-ChildItem -Path (Join-Path $RepoDir "extensions") | ForEach-Object {
        $rel = "extensions/" + $_.Name
        if ($_.PSIsContainer) {
            Install-Tree $_.FullName (Join-Path $AgentDir $rel) $rel
        } else {
            Install-File $_.FullName (Join-Path $AgentDir $rel) $rel
        }
    }

    Install-Tree (Join-Path $RepoDir "skills") (Join-Path $AgentDir "skills") "skills"
    Install-Tree (Join-Path $RepoDir "sources/ponytail") (Join-Path $SourcesDir "ponytail") "sources/ponytail"

    Get-ChildItem -Path (Join-Path $RepoDir "themes") -Filter *.json | ForEach-Object {
        $rel = "themes/" + $_.Name
        Install-File $_.FullName (Join-Path $AgentDir $rel) $rel
    }

    if (Test-Path $BackupDir) {
        Write-Host "Previous files backed up to: $BackupDir"
    }

    if (-not $env:OMP_CUSTOM_SKIP_DEPS) {
        if (Get-Command rtk -ErrorAction SilentlyContinue) {
            Write-Host "rtk: already installed"
        } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing rtk (command rewriting for token savings)..."
            winget install --id rtk-ai.rtk --accept-source-agreements --accept-package-agreements --silent
            $env:Path = "$env:LOCALAPPDATA\Microsoft\WinGet\Links;$env:Path"
        } else {
            Write-Host "rtk missing: install https://github.com/rtk-ai/rtk (winget install rtk-ai.rtk)"
        }

        if (Get-Command graphify -ErrorAction SilentlyContinue) {
            Write-Host "graphifyy: already installed"
        } elseif (Get-Command uv -ErrorAction SilentlyContinue) {
            Write-Host "Installing graphifyy (for /graphify)..."
            uv tool install graphifyy
        } else {
            Write-Host "graphifyy missing: install uv, then 'uv tool install graphifyy'"
        }
    }

    Write-Host "Done. Run 'omp' to verify."
}
finally {
    if ($DownloadedDir) {
        Remove-Item -Recurse -Force $DownloadedDir -ErrorAction SilentlyContinue
    }
}