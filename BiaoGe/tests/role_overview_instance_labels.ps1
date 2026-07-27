param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$rolePath = Join-Path $Root "BiaoGe\Core\Module\RoleOverview.lua"
$optionsPath = Join-Path $Root "BiaoGe\Core\Options.lua"
$compatPath = Join-Path $Root "BiaoGe\Core\Compat.lua"
$localePath = Join-Path $Root "BiaoGe\Locales\enUS.lua"
$roleText = Get-Content -LiteralPath $rolePath -Raw -Encoding UTF8
$optionsText = Get-Content -LiteralPath $optionsPath -Raw -Encoding UTF8
$compatText = Get-Content -LiteralPath $compatPath -Raw -Encoding UTF8
$localeText = Get-Content -LiteralPath $localePath -Raw -Encoding UTF8
$failures = @()

function Get-BranchBlock {
    param(
        [string]$Text,
        [string]$StartPattern,
        [string]$EndPattern,
        [string]$Description
    )

    $match = [regex]::Match(
        $Text,
        "(?s)$StartPattern(.*?)$EndPattern"
    )
    if (-not $match.Success) {
        $script:failures += "Could not isolate $Description."
        return ""
    }
    return $match.Groups[1].Value
}

$roleWotlk = Get-BranchBlock `
    -Text $roleText `
    -StartPattern 'elseif BG\.IsWLK_80 then\s+BG\.FBCDall_table\s*=\s*\{' `
    -EndPattern '\n\s*\}\s*elseif BG\.IsTitan then' `
    -Description "the WotLK RoleOverview dataset"

$optionsWotlk = Get-BranchBlock `
    -Text $optionsText `
    -StartPattern 'elseif BG\.IsWLK_80 then' `
    -EndPattern 'elseif BG\.IsTitan then' `
    -Description "the WotLK options section"

$wotlkOptions = @(
    @("25RS", "25\u7EA2\u7389", "724", "25", "FF4500", "[25]RS"),
    @("10RS", "10\u7EA2\u7389", "724", "10", "FF4500", "[10]RS"),
    @("25ICC", "25\u51B0\u51A0", "631", "25", "9370DB", "[25]ICC"),
    @("10ICC", "10\u51B0\u51A0", "631", "10", "9370DB", "[10]ICC"),
    @("25TOC", "25\u5341\u5B57\u519B", "649", "25", "FF69B4", "[25]TOGC"),
    @("10TOC", "10\u5341\u5B57\u519B", "649", "10", "FF69B4", "[10]TOGC"),
    @("25OL", "25\u9ED1\u9F99", "249", "25", "FFA500", "[25]ONY"),
    @("10OL", "10\u9ED1\u9F99", "249", "10", "FFA500", "[10]ONY"),
    @("25ULD", "25\u5965\u675C\u5C14", "603", "25", "00BFFF", "[25]ULDUAR"),
    @("10ULD", "10\u5965\u675C\u5C14", "603", "10", "00BFFF", "[10]ULDUAR"),
    @("25NAXX", "25\u7EB3\u514B", "533", "25", "32CD32", "[25]NAXX"),
    @("10NAXX", "10\u7EB3\u514B", "533", "10", "32CD32", "[10]NAXX"),
    @("25EOE", "25\u84DD\u9F99", "616", "25", "1E90FF", "[25]EOE"),
    @("10EOE", "10\u84DD\u9F99", "616", "10", "1E90FF", "[10]EOE"),
    @("25OS", "25\u9ED1\u66DC\u77F3", "615", "25", "8B4513", "[25]OS"),
    @("10OS", "10\u9ED1\u66DC\u77F3", "615", "10", "8B4513", "[10]OS"),
    @("25VOA", "25\u5B9D\u5E93", "624", "25", "FFFF00", "[25]VOA"),
    @("10VOA", "10\u5B9D\u5E93", "624", "10", "FFFF00", "[10]VOA")
)

foreach ($entry in $wotlkOptions) {
    $key, $localeKey, $instanceID, $size, $color, $short = $entry
    $identityPattern = '\{\s*name\s*=\s*"' + [regex]::Escape($key) +
        '".*?name2\s*=\s*L\["' + $localeKey +
        '"\].*?name3\s*=\s*enUS\s+and\s+"' + [regex]::Escape($short) +
        '".*?color\s*=\s*"' + $color +
        '".*?fbId\s*=\s*' + $instanceID +
        '.*?num\s*=\s*' + $size +
        '.*?type\s*=\s*"fb"\s*\}'
    if ($roleWotlk -notmatch $identityPattern) {
        $failures += "Missing compact label or changed identity for $key ($short)."
    }
}

if ($roleText -notmatch 'local enUS\s*=\s*GetLocale\(\)\s*==\s*"enUS"') {
    $failures += "RoleOverview must gate compact labels to enUS."
}

$compactCount = ([regex]::Matches(
    $roleWotlk,
    'name3\s*=\s*enUS\s+and\s*"\[(?:10|25)\][A-Z]+"'
)).Count
if ($compactCount -ne 18) {
    $failures += "Expected 18 compact WotLK labels, found $compactCount."
}

$tbcKeys = @("SW", "BT", "HS", "TK", "SSC", "GL", "ML", "ZA", "KZ", "PT", "STK")
$legacyKeys = @("TAQ", "AQL", "ZUG", "BWL", "MC")
foreach ($key in $tbcKeys + $legacyKeys) {
    $count = ([regex]::Matches(
        $roleWotlk,
        '\{\s*name\s*=\s*"' + [regex]::Escape($key) + '"'
    )).Count
    if ($count -ne 1) {
        $failures += "Expected one historical lockout record for $key, found $count."
    }
}

if ($optionsText -notmatch 'local name3\s*=\s*BG\[tblName\]\[i\]\.name3') {
    $failures += "Options must read the compact presentation label."
}
if ($optionsText -notmatch '\(name3 or name2 or name\):gsub') {
    $failures += "Checkbox text must prefer compact labels over full names."
}
if ($optionsText -notmatch 'local enUS\s*=\s*GetLocale\(\)\s*==\s*"enUS"') {
    $failures += "Options must gate the English tooltip grammar to enUS."
}
if ($optionsText -notmatch 'maxplayers\s*=\s*num\s+and\s+\(num\s*\.\.\s*"\s+man\s+"\)\s+or\s+""') {
    $failures += "enUS tooltip size must use '<num> man '."
}
if ($optionsText -notmatch 'tooltipName\s*=\s*name3\s+and\s+name2:gsub\("\^%d\+%s\*",\s*""\)\s+or\s+GetRealZoneText\(fbId\)') {
    $failures += "Tooltip must strip the duplicated WotLK size and resolve historical full names by instance ID."
}
if ($optionsText -notmatch 'text\s*=\s*"\|cff"\s*\.\.\s*color\s*\.\.\s*maxplayers\s*\.\.\s*tooltipName\s*\.\.\s*RR') {
    $failures += "Tooltip must combine the normalized size and full instance name."
}
if ($optionsText -match 'maxplayers\s*\.\.\s*\(name2 or GetRealZoneText\(fbId\)\)') {
    $failures += "Legacy tooltip concatenation duplicates WotLK size and exposes historical abbreviations."
}

$historicalCompatNames = @{
    624 = "Vault of Archavon"
    580 = "Sunwell Plateau"
    564 = "Black Temple"
    534 = "Hyjal Summit"
    550 = "Tempest Keep"
    548 = "Serpentshrine Cavern"
    565 = "Gruul's Lair"
    544 = "Magtheridon's Lair"
    568 = "Zul'Aman"
    532 = "Karazhan"
    585 = "Magisters' Terrace"
    556 = "Sethekk Halls"
    531 = "Temple of Ahn'Qiraj"
    509 = "Ruins of Ahn'Qiraj"
    309 = "Zul'Gurub"
    469 = "Blackwing Lair"
    409 = "Molten Core"
}
foreach ($mapID in $historicalCompatNames.Keys) {
    $pattern = '\[' + $mapID + '\]\s*=\s*"' +
        [regex]::Escape($historicalCompatNames[$mapID]) + '"'
    if ($compatText -notmatch $pattern) {
        $failures += "GetRealZoneText compatibility map is missing the full name for $mapID ($($historicalCompatNames[$mapID]))."
    }
}

$buttonWidthMatch = [regex]::Match($optionsText, 'local buttonWidth\s*=\s*(\d+)')
if (-not $buttonWidthMatch.Success -or [int]$buttonWidthMatch.Groups[1].Value -lt 120) {
    $failures += "Instance checkbox allocation must be at least 120 pixels."
}

if ($optionsWotlk -match '(?s)CreateTitle\(EXPANSION_NAME1.*?CreateFBCDbutton\([^\r\n]+,\s*true\)') {
    $failures += "Burning Crusade must not initialize collapsed on WotLK."
}
if ($optionsWotlk -match '(?s)CreateTitle\(LFG_LIST_LEGACY.*?CreateFBCDbutton\([^\r\n]+,\s*true\)') {
    $failures += "Legacy must not initialize collapsed on WotLK."
}
if ($optionsWotlk -notmatch 'CreateTitle\(LFG_LIST_LEGACY or L\["\u7ECF\u5178\u65E7\u4E16"\],\s*"40c040"\)') {
    $failures += "Legacy heading must use the project-localized fallback."
}
if ($localeText -notmatch 'L\["\u7ECF\u5178\u65E7\u4E16"\]\s*=\s*"Legacy"') {
    $failures += "enUS Legacy fallback is missing."
}

$fullNameChecks = @(
    @("25\u7EA2\u7389", "25 Ruby Sanctum"),
    @("25\u5341\u5B57\u519B", "25 Trial of the Crusader"),
    @("25\u9ED1\u9F99", "25 Onyxia's Lair"),
    @("25\u5B9D\u5E93", "25 Vault of Archavon")
)
foreach ($entry in $fullNameChecks) {
    $pattern = 'L\["' + $entry[0] + '"\]\s*=\s*"' +
        [regex]::Escape($entry[1]) + '"'
    if ($localeText -notmatch $pattern) {
        $failures += "Full tooltip translation must remain unchanged: $($entry[1])."
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS Character Overview exposes complete WotLK, TBC, and Legacy labels"
