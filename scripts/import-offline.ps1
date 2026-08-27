<#
.SYNOPSIS
    Zet een pakket van export-offline.ps1 op zijn plek op een Windows-machine zonder internet.

.DESCRIPTION
    Bewust simpel gehouden. Op een beheerde werk-PC kan PowerShell in
    Constrained Language Mode draaien, waarin scripts die .NET-types aanroepen
    sneuvelen. Dit script gebruikt daarom alleen cmdlets en robocopy.

    Bestaande installaties worden niet overschreven maar hernoemd naar
    <naam>.bak-<tijdstempel>, zodat je altijd terug kunt.

    Als het pakket met alle Mason-pakketten is gemaakt (het standaardgedrag van
    export-offline.ps1), staat na dit script alles al klaar -- inclusief de
    npm-/pip-pakketten. Je hoeft dan geen :MasonToolsInstall te draaien: dat
    zou op een offline machine alsnog vastlopen op Mason's eigen schema- en
    PyPI-aanroepen naar het publieke internet, los van of Nexus/pip werken.

.PARAMETER Package
    Map (of .zip) die door export-offline.ps1 is gemaakt.

.PARAMETER DryRun
    Toon wat er zou gebeuren zonder iets te wijzigen.

.EXAMPLE
    .\import-offline.ps1 -Package D:\transfer\nvim-offline-20260825-143000 -DryRun
    .\import-offline.ps1 -Package D:\transfer\nvim-offline-20260825-143000
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Package,
    [string] $ConfigPath = (Join-Path $env:LOCALAPPDATA 'nvim'),
    [string] $DataPath   = (Join-Path $env:LOCALAPPDATA 'nvim-data'),
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
# PowerShell 7.3+ zet stderr-regels van externe tools (git 'Cloning into...',
# 'Enumerating objects', etc.) om in afbrekende fouten zodra $ErrorActionPreference
# 'Stop' is -- ook al is de exitcode 0. Dit script controleert $LASTEXITCODE zelf al
# na elke git/robocopy-aanroep, dus die promotie hoeft hier niet.
if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Write-Step { param([string] $Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Warn { param([string] $Message) Write-Host "  ! $Message" -ForegroundColor Yellow }


function Invoke-Native {
    # Draait een extern commando (git, robocopy, ...) met $ErrorActionPreference
    # lokaal op 'Continue'. Zonder dit zet PowerShell elke stderr-regel van zo'n
    # commando -- ook doodgewone voortgangsmeldingen als git's "Cloning into..." --
    # om in een afbrekende fout zodra het script zelf 'Stop' gebruikt. De
    # aanroeper controleert na afloop gewoon $LASTEXITCODE, zoals al gebeurde.
    param([Parameter(Mandatory)][scriptblock] $Script)
    $ErrorActionPreference = 'Continue'
    & $Script
}

function Copy-Tree {
    param([string] $Source, [string] $Destination)
    Invoke-Native { $null = robocopy $Source $Destination /E /NFL /NDL /NJH /NJS /NP /R:2 /W:1 }
    if ($LASTEXITCODE -ge 8) { throw "robocopy faalde ($LASTEXITCODE) bij $Source" }
    $global:LASTEXITCODE = 0
}

function Move-Aside {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $backup = "$Path.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    if ($DryRun) {
        Write-Host "    zou hernoemen: $Path -> $backup"
    } else {
        Rename-Item -LiteralPath $Path -NewName (Split-Path $backup -Leaf)
        Write-Host "    backup: $backup"
    }
    return $backup
}

# ---------------------------------------------------------------- preflight --

Write-Step 'Omgeving controleren'

$mode = $ExecutionContext.SessionState.LanguageMode
Write-Host "    PowerShell LanguageMode: $mode"
if ($mode -ne 'FullLanguage') {
    Write-Warn 'Geen FullLanguage. Dit script mijdt .NET-types, maar mocht het alsnog'
    Write-Warn 'stuklopen, kopieer de mappen dan met de hand -- zie het overzicht onderaan.'
}

if (-not (Test-Path -LiteralPath $Package)) { throw "pakket niet gevonden: $Package" }

# Zip? Eerst uitpakken naar een tijdelijke map.
if ($Package -like '*.zip') {
    $tempDir = Join-Path $env:TEMP "nvim-import-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Step "Uitpakken naar $tempDir"
    if ($DryRun) {
        Write-Warn 'DryRun op een .zip: de inhoud wordt niet uitgepakt, dus alles hieronder'
        Write-Warn 'lijkt te ontbreken. Draai DryRun op de uitgepakte map voor een echte controle.'
    } else {
        $null = New-Item -ItemType Directory -Path $tempDir -Force
        Expand-Archive -LiteralPath $Package -DestinationPath $tempDir -Force
    }
    $Package = $tempDir
}

$manifestPath = Join-Path $Package 'manifest.json'
$manifest = $null
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Write-Host "    pakket gemaakt op $($manifest.createdOn), $($manifest.created)"
    Write-Host "    $($manifest.parserCount) parsers, mason: $($manifest.masonPackages -join ', ')"
} else {
    Write-Warn 'geen manifest.json gevonden; verificatie achteraf wordt overgeslagen'
}

$git = Get-Command git -ErrorAction SilentlyContinue
$bundlePath = Join-Path $Package 'nvim-config.bundle'
$plainConfig = Join-Path $Package 'config'
if ((Test-Path -LiteralPath $bundlePath) -and (-not $git)) {
    throw 'de config zit in een git bundle maar git staat niet op PATH'
}

# -------------------------------------------------------------------- config --

Write-Step 'Config plaatsen'

$null = Move-Aside -Path $ConfigPath

if (Test-Path -LiteralPath $bundlePath) {
    if ($DryRun) {
        Write-Host "    zou clonen: $bundlePath -> $ConfigPath"
    } else {
        Invoke-Native { git clone $bundlePath $ConfigPath 2>$null }
        if ($LASTEXITCODE -ne 0) { throw 'git clone uit de bundle is mislukt' }
        # De origin wijst nu naar een bundle op een stick die er straks niet meer is.
        Push-Location $ConfigPath
        try { Invoke-Native { git remote remove origin 2>$null } } finally { Pop-Location }
        Write-Host "    $ConfigPath (uit bundle, historie behouden)"
    }
} elseif (Test-Path -LiteralPath $plainConfig) {
    if ($DryRun) { Write-Host "    zou kopieren: $plainConfig -> $ConfigPath" }
    else { Copy-Tree -Source $plainConfig -Destination $ConfigPath }
} else {
    throw 'pakket bevat geen config (geen bundle en geen config-map)'
}

# ---------------------------------------------------------------------- data --

Write-Step 'Plugins, parsers en Mason plaatsen'

$null = Move-Aside -Path $DataPath

$moves = @(
    @{ From = 'lazy';             To = 'lazy' },
    @{ From = 'parser';           To = 'site\parser' },
    @{ From = 'mason-registries'; To = 'mason\registries' },
    @{ From = 'mason-bin';        To = 'mason\bin' }
)

foreach ($m in $moves) {
    $src = Join-Path $Package $m.From
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Warn "ontbreekt in pakket: $($m.From)"
        continue
    }
    $dst = Join-Path $DataPath $m.To
    if ($DryRun) { Write-Host "    zou kopieren: $($m.From) -> $dst"; continue }
    Copy-Tree -Source $src -Destination $dst
    Write-Host "    $dst"
}

$srcPackages = Join-Path $Package 'mason-packages'
if (Test-Path -LiteralPath $srcPackages) {
    foreach ($dir in (Get-ChildItem -LiteralPath $srcPackages -Directory)) {
        $dst = Join-Path $DataPath "mason\packages\$($dir.Name)"
        if ($DryRun) { Write-Host "    zou kopieren: mason-packages\$($dir.Name) -> $dst"; continue }
        Copy-Tree -Source $dir.FullName -Destination $dst
        Write-Host "    $dst"
    }
}

if ($DryRun) {
    Write-Host ''
    Write-Host 'DryRun: er is niets gewijzigd.' -ForegroundColor Yellow
    return
}

# ------------------------------------------------------------------ controle --

Write-Step 'Controleren'

$parserDir = Join-Path $DataPath 'site\parser'
$got = @()
if (Test-Path -LiteralPath $parserDir) {
    $got = @(Get-ChildItem -LiteralPath $parserDir -Filter '*.so' -File | ForEach-Object { $_.BaseName })
}
Write-Host "    parsers aangekomen: $($got.Count)"

if ($manifest) {
    $missing = @($manifest.parsers | Where-Object { $got -notcontains $_ })
    if ($missing.Count -gt 0) {
        Write-Warn "ontbrekende parsers: $($missing -join ', ')"
    } else {
        Write-Host '    parsers compleet' -ForegroundColor Green
    }
}

$isMinimal = $manifest -and $manifest.minimal

Write-Host ''
Write-Host 'Klaar. Nog te doen op deze machine:' -ForegroundColor Green
Write-Host '  1. Start nvim. Lazy vindt alle plugins al op schijf.'
if ($isMinimal) {
    Write-Host '  2. Dit pakket is met -Minimal gemaakt: npm-/pip-pakketten ontbreken.'
    Write-Host '     Controleer dat npm naar Nexus wijst (npm config get registry) en draai'
    Write-Host '     :MasonToolsInstall -- houd er rekening mee dat dit kan vastlopen op Mason'
    Write-Host '     eigen schema-/PyPI-aanroepen naar het publieke internet, ongeacht Nexus/pip.'
    Write-Host '     Exporteer in dat geval opnieuw zonder -Minimal.'
} else {
    Write-Host '  2. Alle Mason-pakketten (inclusief npm/pip) zaten al in het pakket --'
    Write-Host '     :MasonToolsInstall is niet nodig.'
}
Write-Host '  3. Controleer met :checkhealth en open een .component.html uit een Angular-project.'
Write-Host ''
Write-Host 'Mocht dit script niet mogen draaien, dan is dit alles wat het doet:'
Write-Host "  <pakket>\lazy             -> $DataPath\lazy"
Write-Host "  <pakket>\parser           -> $DataPath\site\parser"
Write-Host "  <pakket>\mason-registries -> $DataPath\mason\registries"
Write-Host "  <pakket>\mason-bin        -> $DataPath\mason\bin"
Write-Host "  <pakket>\mason-packages\* -> $DataPath\mason\packages\"
Write-Host "  git clone <pakket>\nvim-config.bundle $ConfigPath"
