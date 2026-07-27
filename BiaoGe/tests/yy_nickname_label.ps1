param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$yyPath = Join-Path $Root "BiaoGe\Core\Module\YY.lua"
$enUSPath = Join-Path $Root "BiaoGe\Locales\enUS.lua"
$zhCNPath = Join-Path $Root "BiaoGe\Locales\zhCN.lua"
$zhTWPath = Join-Path $Root "BiaoGe\Locales\zhTW.lua"

$yyText = Get-Content -LiteralPath $yyPath -Raw -Encoding UTF8
$enUSText = Get-Content -LiteralPath $enUSPath -Raw -Encoding UTF8
$zhCNText = Get-Content -LiteralPath $zhCNPath -Raw -Encoding UTF8
$zhTWText = Get-Content -LiteralPath $zhTWPath -Raw -Encoding UTF8
$failures = @()

$yyColonKey = "YY$([char]0xFF1A)"
$yyEvaluationKey = "YY$([char]0x8BC4)$([char]0x4EF7)"
$yyColonPattern = 'L\["' + [regex]::Escape($yyColonKey) + '"\]'
$yyEvaluationPattern = 'L\["' + [regex]::Escape($yyEvaluationKey) + '"\]'

function Assert-Count {
    param(
        [string]$Text,
        [string]$Pattern,
        [int]$Expected,
        [string]$Message
    )

    $actual = [regex]::Matches($Text, $Pattern).Count
    if ($actual -ne $Expected) {
        $script:failures += "$Message (expected $Expected, found $actual)."
    }
}

Assert-Count $yyText $yyColonPattern 3 `
    "Exactly three YY Evaluation nickname fields must share the colon label"
Assert-Count $yyText 'L\["YY"\]' 2 `
    "Exactly two YY Evaluation nickname columns must share the plain label"

Assert-Count $enUSText ($yyColonPattern + '\s*=\s*"Nickname:"') 1 `
    "The English nickname field label must read Nickname:"
Assert-Count $enUSText 'L\["YY"\]\s*=\s*"Nickname"' 2 `
    "Both repeated English nickname column assignments must read Nickname"
Assert-Count $enUSText ($yyColonPattern + '\s*=\s*"YY:"') 0 `
    "The obsolete English YY: field label must be absent"
Assert-Count $enUSText 'L\["YY"\]\s*=\s*"YY"' 0 `
    "The obsolete English YY column label must be absent"

Assert-Count $enUSText ($yyEvaluationPattern + '\s*=\s*"YY Evaluation"') 2 `
    "The YY Evaluation product identity must remain unchanged"

Assert-Count $zhCNText ($yyColonPattern + '\s*=\s*true') 1 `
    "The zhCN nickname field label must remain unchanged"
Assert-Count $zhCNText 'L\["YY"\]\s*=\s*true' 2 `
    "Both zhCN nickname column assignments must remain unchanged"
Assert-Count $zhTWText ($yyColonPattern + '\s*=\s*"' + [regex]::Escape($yyColonKey) + '"') 1 `
    "The zhTW nickname field label must remain unchanged"
Assert-Count $zhTWText 'L\["YY"\]\s*=\s*L\["YY"\]' 2 `
    "Both zhTW nickname column assignments must remain unchanged"

$localizedYYKeys = [regex]::Matches($yyText, 'L\["([^"]*YY[^"]*)"\]') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
if ($localizedYYKeys.Count -ne 15) {
    $failures += "The classified YY-bearing source-key census changed (expected 15, found $($localizedYYKeys.Count))."
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS YY Evaluation uses Nickname labels without renaming the product"
