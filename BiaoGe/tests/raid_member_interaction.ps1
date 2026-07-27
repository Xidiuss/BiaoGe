param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$achievementPath = Join-Path $Root "BiaoGe\Core\Module\Achievement.lua"
$achievementText = Get-Content -LiteralPath $achievementPath -Raw -Encoding UTF8
$failures = @()

$factoryMatch = [regex]::Match(
    $achievementText,
    '(?s)local function CreateRaidButton\(i\)(.*?)for i = 1, 40 do\s+CreateRaidButton\(i\)\s+end'
)

if (-not $factoryMatch.Success) {
    $failures += "Could not isolate the complete 40-slot Raid Member factory."
    $factoryText = ""
} else {
    $factoryText = $factoryMatch.Groups[1].Value
}

foreach ($required in @(
    'CreateFrame("Frame", nil, nil, "BackdropTemplate")',
    'f:EnableMouse(true)',
    'f:SetScript("OnEnter", OnEnter)',
    'f:SetScript("OnLeave", OnLeave)',
    'tinsert(BG.AchievementMainFrame.raidFrame.buttons, f)'
)) {
    if (-not $factoryText.Contains($required)) {
        $failures += "Raid Member factory is missing interaction contract marker: $required"
    }
}

if ($factoryText -match 'SetScript\("On(?:Click|MouseDown|MouseUp)"') {
    $failures += "Raid Member cells must remain hover-only and must not gain a click-selection action."
}

if ($factoryText -match 'SetFrameLevel\(') {
    $failures += "Confirmed parent/child levels must not be replaced by a speculative frame-level offset."
}

if ($achievementText -notmatch 'if not name or not raidAchievement_AllPlayer\[name\] then return end') {
    $failures += "Unavailable comparison data must retain its explicit tooltip guard."
}

if ($achievementText -notmatch 'for i = 1, 40 do\s+CreateRaidButton\(i\)\s+end') {
    $failures += "The canonical factory must continue to own all 40 Raid Member slots."
}

if ($achievementText -notmatch '(?s)BG\.AchievementMainFrame\.ButtonRefresh\s*=\s*bt.*?bt:SetScript\("OnClick"') {
    $failures += "Refresh Data must retain its independent click contract."
}

$selectorFactoryMatch = [regex]::Match(
    $achievementText,
    '(?s)local function CreateButton\(i, ID, child, isStats\)(.*?)function BG\.UpdateAchievementFrame\(\)'
)

if (-not $selectorFactoryMatch.Success) {
    $failures += "Could not isolate the achievement/statistic selector factory."
    $selectorFactoryText = ""
} else {
    $selectorFactoryText = $selectorFactoryMatch.Groups[1].Value
}

foreach ($required in @(
    'CreateFrame("Frame", nil, child, "BackdropTemplate")',
    'f:EnableMouse(true)',
    'f:SetScript("OnEnter"',
    'f:SetScript("OnLeave", OnLeave)',
    'f:SetScript("OnMouseDown", OnClick)',
    'GameTooltip:SetHyperlink(GetAchievementLink(ID))'
)) {
    if (-not $selectorFactoryText.Contains($required)) {
        $failures += "Achievement selector factory is missing interaction marker: $required"
    }
}

foreach ($required in @(
    'local raidAchievementPlayerName',
    'raidAchievementPlayerName = name',
    'local function IsCountedRaidMember(name)',
    'text:SetText((raidAchievement_Total[ID] or 0) .. "/" .. num)'
)) {
    if (-not $achievementText.Contains($required)) {
        $failures += "Other-member achievement fraction is missing marker: $required"
    }
}

$countedMemberCalls = [regex]::Matches($achievementText, 'if IsCountedRaidMember\(name\) then').Count
if ($countedMemberCalls -ne 2) {
    $failures += "The same player-excluding predicate must own numerator and denominator (expected 2 calls, found $countedMemberCalls)."
}

if ($achievementText -notmatch 'return BG\.raidRosterName\[name\] and name ~= raidAchievementPlayerName') {
    $failures += "Achievement fractions must exclude the actual player roster key from loaded raid members."
}

if ($selectorFactoryText -notmatch '(?s)GetAchievementInfo\(ID\).*?if not isStats and not completed then') {
    $failures += "The player's existing personal gold/desaturated achievement state must remain independent from the fraction."
}

foreach ($required in @(
    'local raidAchievementRequest =',
    'UnitIsUnit(unit, "player")',
    'CanInspect(unit, false)',
    'raidAchievementRequest.name = member.name',
    'raidAchievementRequest.guid = guid',
    'local name = raidAchievementRequest.name',
    'RequestNextRaidAchievement(generation)'
)) {
    if (-not $achievementText.Contains($required)) {
        $failures += "Raid comparison acquisition is missing sequential request marker: $required"
    }
}

if ($achievementText -notmatch 'if guid and raidAchievementRequest\.guid and guid ~= raidAchievementRequest\.guid then return end') {
    $failures += "A GUID-bearing ready event from another comparison request must not be attributed to the active member."
}

if ($achievementText -match 'BG\.raidRosterGUID\[guid\]') {
    $failures += "The 3.3.5 ready event has no GUID payload; acquisition must use the identity saved with the active request."
}

if ($achievementText -match 'self\.t >= 0\.2') {
    $failures += "Comparison targets must not be replaced by a 0.2-second polling loop before their ready event."
}

foreach ($diagnosticMarker in @(
    'raidAchievementTrace',
    'RaidMemberInteractionDump',
    'RaidAchievementOneShotDump',
    '/bgraidtest',
    '/bgraidone'
)) {
    if ($achievementText.Contains($diagnosticMarker)) {
        $failures += "Temporary runtime diagnostic must be removed from the production candidate: $diagnosticMarker"
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS Raid Member data, member hover, achievement hover, and other-member counts"
