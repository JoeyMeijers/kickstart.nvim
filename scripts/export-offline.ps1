<#
.SYNOPSIS
    Bundelt deze Neovim-installatie tot een pakket voor een Windows-machine zonder internet.

.DESCRIPTION
    Draait op een Windows-machine MET internet, waar deze config al een keer volledig
    is opgestart (plugins binnengehaald, treesitter-parsers gecompileerd, Mason-pakketten
    geinstalleerd).

    Meegenomen wordt alleen wat op de doelmachine niet zelf op te halen is:
      - de config, als git bundle (behoudt de historie)
      - de lazy.nvim plugin-map
      - de gecompileerde treesitter-parsers
      - de Mason registry-cache -- zonder deze kan Mason niets via Nexus installeren
      - de Mason-pakketten die van GitHub-releases komen

    NIET meegenomen: alles wat via npm of pip binnenkomt. Op de doelmachine leveren
    Nexus en pip die zelf, en dat scheelt ruim 750 MB.

.PARAMETER OutputPath
    Map waarin het pakket wordt aangemaakt. Standaard de huidige map.

.PARAMETER IncludePypi
    Neem ook de PyPI-pakketten (basedpyright) mee. Alleen nodig als pip op de
    doelmachine geen index kan bereiken.

.PARAMETER Zip
    Maak na het stagen ook een .zip. Let op: Compress-Archive kan struikelen over
    zeer lange paden; de map zelf is altijd bruikbaar.

.PARAMETER DryRun
    Toon wat er zou gebeuren zonder iets te schrijven.

.EXAMPLE
    .\export-offline.ps1 -DryRun
    .\export-offline.ps1 -OutputPath D:\transfer
#>

[CmdletBinding()]
param(
    [string] $OutputPath = (Get-Location).Path,
    [string] $ConfigPath = (Join-Path $env:LOCALAPPDATA 'nvim'),
    [string] $DataPath   = (Join-Path $env:LOCALAPPDATA 'nvim-data'),
    [switch] $IncludePypi,
    [switch] $Zip,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# Mason-pakketten die van GitHub-releases komen. Alles wat hier niet staat komt
# via npm (Nexus) of pip en hoeft dus niet mee.
$GithubPackages = @('ruff', 'stylua', 'lua-language-server')
$PypiPackages   = @('basedpyright')

function Write-Step { param([string] $Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Warn { param([string] $Message) Write-Host "  ! $Message" -ForegroundColor Yellow }
function Write-Fail { param([string] $Message) Write-Host "  x $Message" -ForegroundColor Red }

function Get-DirectorySize {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sum) { return 0 }
    return $sum
}

function Copy-Tree {
    param([string] $Source, [string] $Destination)
    # robocopy in plaats van Copy-Item: die laatste faalt op paden > 260 tekens,
    # en plugin-mappen zitten vol diepe boomstructuren.
    # Exitcodes 0-7 zijn succes; 8 en hoger is een echte fout.
    $null = robocopy $Source $Destination /E /NFL /NDL /NJH /NJS /NP /R:2 /W:1
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy faalde ($LASTEXITCODE) bij het kopieren van $Source"
    }
    $global:LASTEXITCODE = 0
}

# ---------------------------------------------------------------- preflight --

Write-Step 'Vooraf controleren'

$problems = @()

if (-not (Test-Path -LiteralPath $ConfigPath)) { $problems += "config niet gevonden: $ConfigPath" }
if (-not (Test-Path -LiteralPath $DataPath))   { $problems += "data niet gevonden: $DataPath" }

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { $problems += 'git niet op PATH -- nodig voor de config-bundle' }

$nvim = Get-Command nvim -ErrorAction SilentlyContinue
if (-not $nvim) { Write-Warn 'nvim niet op PATH; parser-controle wordt overgeslagen' }

$parserDir = Join-Path $DataPath 'site\parser'
$parsers = @()
if (Test-Path -LiteralPath $parserDir) {
    $parsers = @(Get-ChildItem -LiteralPath $parserDir -Filter '*.so' -File |
                 ForEach-Object { $_.BaseName } | Sort-Object)
}
if ($parsers.Count -eq 0) {
    $problems += "geen treesitter-parsers in $parserDir -- start nvim een keer en laat de compilatie afmaken"
} else {
    Write-Host "    $($parsers.Count) parsers: $($parsers -join ', ')"
}

# Parsers worden op de doelmachine niet gebouwd (grammars komen van GitHub), dus
# een onvolledige set hier is een onvolledige set daar. De CLI moet aanwezig zijn
# geweest om ze te maken; ontbreekt hij, dan klopt er iets niet.
$ts = Get-Command tree-sitter -ErrorAction SilentlyContinue
if (-not $ts) {
    Write-Warn 'tree-sitter CLI niet op PATH -- nieuwe parsers kunnen hier niet gebouwd worden'
}

$lazyDir = Join-Path $DataPath 'lazy'
if (-not (Test-Path -LiteralPath $lazyDir)) { $problems += "plugin-map niet gevonden: $lazyDir" }

$registryDir = Join-Path $DataPath 'mason\registries'
if (-not (Test-Path -LiteralPath $registryDir)) {
    $problems += "Mason registry-cache niet gevonden: $registryDir -- zonder deze kan Mason op de doelmachine niets installeren"
}

if ($problems.Count -gt 0) {
    foreach ($p in $problems) { Write-Fail $p }
    throw 'Vooraf-controle mislukt; er is niets weggeschreven.'
}

Write-Host '    alles aanwezig' -ForegroundColor Green

# ------------------------------------------------------------------ plannen --

$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$stageName = "nvim-offline-$stamp"
$stageDir  = Join-Path $OutputPath $stageName

$wanted = @($GithubPackages)
if ($IncludePypi) { $wanted += $PypiPackages }

$packagesDir = Join-Path $DataPath 'mason\packages'
$packages = @()
foreach ($name in $wanted) {
    $dir = Join-Path $packagesDir $name
    if (Test-Path -LiteralPath $dir) {
        $packages += $name
    } else {
        Write-Warn "Mason-pakket '$name' staat niet geinstalleerd; wordt overgeslagen"
    }
}

Write-Step 'Plan'
Write-Host "    doel:     $stageDir"
Write-Host "    config:   $ConfigPath (als git bundle)"
Write-Host "    plugins:  $lazyDir ($([math]::Round((Get-DirectorySize $lazyDir)/1MB,1)) MB)"
Write-Host "    parsers:  $parserDir ($($parsers.Count) stuks)"
Write-Host "    registry: $registryDir"
Write-Host "    mason:    $($packages -join ', ')"
if (-not $IncludePypi) {
    Write-Host '    overgeslagen: npm- en pip-pakketten (komen daar via Nexus/pip)'
}

if ($DryRun) {
    Write-Host ''
    Write-Host 'DryRun: er is niets weggeschreven.' -ForegroundColor Yellow
    return
}

# ------------------------------------------------------------------ stagen --

Write-Step "Pakket samenstellen in $stageDir"

$null = New-Item -ItemType Directory -Path $stageDir -Force

# Config als git bundle: houdt de historie intact, zodat je op de doelmachine
# later gewoon kunt blijven pullen uit een nieuw pakket.
Write-Host '    config...'
$bundlePath = Join-Path $stageDir 'nvim-config.bundle'
Push-Location $ConfigPath
try {
    $isRepo = (git rev-parse --is-inside-work-tree 2>$null)
    if ($LASTEXITCODE -eq 0 -and $isRepo -eq 'true') {
        git bundle create $bundlePath --all 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'git bundle create is mislukt' }
        $dirty = git status --porcelain
        if ($dirty) {
            Write-Warn 'de config heeft niet-gecommitte wijzigingen; die zitten NIET in de bundle'
        }
    } else {
        Write-Warn 'config is geen git-repo; de map wordt plat gekopieerd'
        Remove-Item -LiteralPath $bundlePath -ErrorAction SilentlyContinue
        Copy-Tree -Source $ConfigPath -Destination (Join-Path $stageDir 'config')
    }
} finally {
    Pop-Location
}

Write-Host '    plugins...'
Copy-Tree -Source $lazyDir -Destination (Join-Path $stageDir 'lazy')

Write-Host '    parsers...'
Copy-Tree -Source $parserDir -Destination (Join-Path $stageDir 'parser')

Write-Host '    mason registry...'
Copy-Tree -Source $registryDir -Destination (Join-Path $stageDir 'mason-registries')

foreach ($name in $packages) {
    Write-Host "    mason: $name..."
    Copy-Tree -Source (Join-Path $packagesDir $name) -Destination (Join-Path $stageDir "mason-packages\$name")
}

# De shims in mason\bin verwijzen naar pakketmappen. Ze zijn klein; Mason maakt ze
# opnieuw aan voor alles wat daar alsnog geinstalleerd wordt.
$binDir = Join-Path $DataPath 'mason\bin'
if (Test-Path -LiteralPath $binDir) {
    Write-Host '    mason bin...'
    Copy-Tree -Source $binDir -Destination (Join-Path $stageDir 'mason-bin')
}

# ---------------------------------------------------------------- manifest --

Write-Step 'Manifest schrijven'

$nvimVersion = 'onbekend'
if ($nvim) {
    $nvimVersion = (& nvim --version | Select-Object -First 1)
}

$manifest = [ordered]@{
    created       = (Get-Date -Format 'o')
    createdOn     = $env:COMPUTERNAME
    nvimVersion   = $nvimVersion
    parsers       = $parsers
    parserCount   = $parsers.Count
    masonPackages = $packages
    includesPypi  = [bool] $IncludePypi
    notes         = 'npm-pakketten komen op de doelmachine via Nexus; draai daar :MasonToolsInstall'
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stageDir 'manifest.json') -Encoding UTF8

$totalBytes = Get-DirectorySize $stageDir
Write-Host "    $([math]::Round($totalBytes/1MB,1)) MB in $stageDir" -ForegroundColor Green

if ($Zip) {
    Write-Step 'Inpakken'
    $zipPath = "$stageDir.zip"
    try {
        Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $zipPath -Force
        Write-Host "    $zipPath" -ForegroundColor Green
    } catch {
        Write-Warn "inpakken mislukt ($($_.Exception.Message)); gebruik de map $stageDir"
    }
}

Write-Host ''
Write-Host 'Klaar. Kopieer de map naar de doelmachine en draai daar import-offline.ps1.' -ForegroundColor Green
