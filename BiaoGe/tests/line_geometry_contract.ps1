param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$compatPath = Join-Path $Root "BiaoGe\Core\Compat.lua"
$providerPath = Join-Path $Root "!!!ClassicAPI\Util\WidgetAPI.lua"
$rolePath = Join-Path $Root "BiaoGe\Core\Module\RoleOverview_core.lua"

$compatText = Get-Content -LiteralPath $compatPath -Raw -Encoding UTF8
$providerText = Get-Content -LiteralPath $providerPath -Raw -Encoding UTF8
$roleText = Get-Content -LiteralPath $rolePath -Raw -Encoding UTF8
$failures = @()

if ($compatText -match 'line\.SetStartPoint\s*=\s*function') {
    $failures += "Compat must not replace ClassicAPI line SetStartPoint."
}

if ($compatText -match 'line\.SetEndPoint\s*=\s*function') {
    $failures += "Compat must not replace ClassicAPI line SetEndPoint."
}

if ($compatText -match 'idx\.CreateLine\s*=\s*function') {
    $failures += "Compat must not wrap or replace the hard dependency's CreateLine."
}

foreach ($providerContract in @(
    'SetStartPoint = function',
    'Self._StartAnchor =',
    'SetEndPoint = function',
    'Self._EndAnchor =',
    'UpdateTransform = function'
)) {
    if (-not $providerText.Contains($providerContract)) {
        $failures += "Tracked ClassicAPI provider is missing contract marker: $providerContract"
    }
}

$corePath = Join-Path $Root "BiaoGe\Core"
$createLineCount = 0
Get-ChildItem -LiteralPath $corePath -Recurse -Filter "*.lua" | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    $createLineCount += ([regex]::Matches($text, 'CreateLine\(\)')).Count
}
if ($createLineCount -ne 34) {
    $failures += "Expected the reviewed census of 34 CreateLine consumers; found $createLineCount."
}

$roleLineCount = ([regex]::Matches($roleText, 'CreateLine\(\)')).Count
if ($roleLineCount -ne 6) {
    $failures += "Expected six Character Overview line consumers; found $roleLineCount."
}

$thickBandCount = ([regex]::Matches($roleText, 'SetThickness\(height - 4\)')).Count
if ($thickBandCount -ne 2) {
    $failures += "Expected two Character Overview thick row-band definitions; found $thickBandCount."
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS ClassicAPI owns line endpoint state for all 34 consumers"
