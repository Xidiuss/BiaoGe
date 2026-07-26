param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$dbPath = Join-Path $Root "BiaoGe\Core\DB\DB_FilterClassItem.lua"
$localePath = Join-Path $Root "BiaoGe\Locales\enUS.lua"
$dbText = Get-Content -LiteralPath $dbPath -Raw -Encoding UTF8
$localeText = Get-Content -LiteralPath $localePath -Raw -Encoding UTF8
$failures = @()

$wotlkStart = $dbText.IndexOf("if BG.IsWLK then")
$wotlkEnd = if ($wotlkStart -ge 0) {
    $dbText.IndexOf("            else", $wotlkStart)
} else {
    -1
}

if ($wotlkStart -lt 0 -or $wotlkEnd -lt 0) {
    $failures += "Could not isolate the WotLK statistic mapping."
    $wotlkText = ""
} else {
    $wotlkText = $dbText.Substring($wotlkStart, $wotlkEnd - $wotlkStart)
}

$labels = @(
    @('\u529B\u91CF', "Strength"),
    @('\u654F\u6377', "Agility"),
    @('\u667A\u529B', "Intellect"),
    @('\u7CBE\u795E', "Spirit"),
    @('5\u56DE\u6CD5\u529B\u503C', "Mana Regen"),
    @('\u547D\u4E2D', "Hit"),
    @('\u6025\u901F', "Haste"),
    @('\u66B4\u51FB', "Critical Strike"),
    @('\u9632\u5FA1', "Defense"),
    @('\u62DB\u67B6', "Parry"),
    @('\u8EB2\u95EA', "Dodge"),
    @('\u683C\u6321', "Block Rating"),
    @('\u683C\u6321\u503C', "Block Value"),
    @('\u653B\u51FB\u5F3A\u5EA6', "Attack Power"),
    @('\u7CBE\u51C6', "Expertise"),
    @('\u62A4\u7532\u7A7F\u900F', "Armor Penetration"),
    @('\u8FD1\u6218\u653B\u51FB', "Melee Attack"),
    @('\u8FDC\u7A0B\u653B\u51FB', "Ranged Attack"),
    @('\u6CD5\u672F\u5F3A\u5EA6', "Spell Power")
)

foreach ($entry in $labels) {
    $keyPattern = $entry[0]
    $label = $entry[1]
    $localePattern = 'L\["' + $keyPattern + '"\]\s*=\s*"' +
        [regex]::Escape($label) + '"'
    if ($localeText -notmatch $localePattern) {
        $failures += "Missing enUS statistic label: $label"
    }

    $mappingPattern = 'name\s*=\s*"' + $keyPattern +
        '".*name2\s*=\s*GetFilterStatName\("' + $keyPattern + '"'
    if ($wotlkText -notmatch $mappingPattern) {
        $failures += "WotLK statistic does not use its localized display label: $label"
    }
}

if ($wotlkText -notmatch "local function GetFilterStatName\(name, fallback\)") {
    $failures += "WotLK mapping is missing GetFilterStatName."
}
if ($wotlkText -notmatch "local localized = L\[name\]") {
    $failures += "GetFilterStatName must resolve the project locale."
}
if ($wotlkText -notmatch "localized ~= name") {
    $failures += "GetFilterStatName must preserve the client label when a locale key is missing."
}

$mappedCount = ([regex]::Matches($wotlkText, 'name2\s*=\s*GetFilterStatName\(')).Count
if ($mappedCount -ne 19) {
    $failures += "Expected 19 localized WotLK display mappings, found $mappedCount."
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS WotLK filter statistics have complete localized display labels"
