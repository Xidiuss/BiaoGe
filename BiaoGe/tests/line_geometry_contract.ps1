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

if ($compatText -match 'idx\.Set(StartPoint|EndPoint|Thickness)\s*=') {
    $failures += "Compat must not install line methods globally on every Texture."
}

$rendererStart = $compatText.IndexOf("local function RenderHorizontalLine")
if ($rendererStart -ge 0) {
    $rendererEnd = $compatText.IndexOf("if idx.CreateLine then", $rendererStart)
} else {
    $rendererEnd = -1
}
if ($rendererEnd -lt 0) {
    $failures += "Could not isolate the BiaoGe horizontal line renderer."
    $rendererText = ""
} else {
    $rendererText = $compatText.Substring($rendererStart, $rendererEnd - $rendererStart)
}

foreach ($rendererContract in @(
    'line:ClearAllPoints()',
    'line:SetPoint("LEFT"',
    'line:SetPoint("RIGHT"',
    'line:SetHeight(line._Thickness or 4)'
)) {
    if (-not $rendererText.Contains($rendererContract)) {
        $failures += "Horizontal line renderer is missing contract marker: $rendererContract"
    }
}

if ($rendererText -match 'GetEffectiveScale|GetRect') {
    $failures += "Horizontal line renderer must use native anchors without manual coordinate or scale normalization."
}

if ($compatText -notmatch 'line\.UpdateTransform\s*=\s*RenderHorizontalLine') {
    $failures += "CreateLine must replace only the returned line's renderer."
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
$directCreateLineCount = 0
Get-ChildItem -LiteralPath $corePath -Recurse -Filter "*.lua" | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    $directCreateLineCount += ([regex]::Matches($text, 'CreateLine\(\)')).Count
}

$roleProviderCallCount = ([regex]::Matches($roleText, 'f:CreateLine\(\)')).Count
if ($roleProviderCallCount -ne 6) {
    $failures += "Expected six direct Character Overview line consumers; found $roleProviderCallCount."
}

$thickBandCount = ([regex]::Matches($roleText, 'SetThickness\(height - 4\)')).Count
if ($thickBandCount -ne 2) {
    $failures += "Expected two Character Overview thick row-band definitions; found $thickBandCount."
}

if ($roleText -match 'CreateOverviewLine|overviewLines|line:UpdateTransform\(\)') {
    $failures += "Character Overview must not retain the temporary manual line reflow."
}

if ($directCreateLineCount -ne 34) {
    $failures += "Expected the reviewed census of 34 CreateLine consumers; found $directCreateLineCount."
}

$startAnchors = [regex]::Matches(
    ((Get-ChildItem -LiteralPath $corePath -Recurse -Filter "*.lua" |
        ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"),
    'SetStartPoint\("([^"]+)"'
)
$endAnchors = [regex]::Matches(
    ((Get-ChildItem -LiteralPath $corePath -Recurse -Filter "*.lua" |
        ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"),
    'SetEndPoint\("([^"]+)"'
)
if ($startAnchors.Count -ne 34 -or $endAnchors.Count -ne 35) {
    $failures += "Expected 34 start and 35 end calls in the horizontal endpoint census; found $($startAnchors.Count)/$($endAnchors.Count)."
}
foreach ($match in @($startAnchors) + @($endAnchors)) {
    if ($match.Groups[1].Value -notmatch '(LEFT|RIGHT)$') {
        $failures += "Non-horizontal endpoint anchor found: $($match.Groups[1].Value)"
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS ClassicAPI owns line endpoint state for all 34 consumers"
