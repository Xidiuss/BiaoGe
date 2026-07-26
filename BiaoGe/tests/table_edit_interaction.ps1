param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$tablePath = Join-Path $Root "BiaoGe\Core\FBUI\FBUIfunction.lua"
$helperPath = Join-Path $Root "BiaoGe\Core\function2.lua"
$tableText = Get-Content -LiteralPath $tablePath -Raw -Encoding UTF8
$helperText = Get-Content -LiteralPath $helperPath -Raw -Encoding UTF8
$failures = @()

$disableCount = ([regex]::Matches($tableText, 'self:SetEnabled\(false\)')).Count
if ($disableCount -ne 0) {
    $failures += "Tables editable cells still disable themselves during mouse handling ($disableCount matches)."
}

$enableCount = ([regex]::Matches($tableText, 'self:SetEnabled\(true\)')).Count
if ($enableCount -ne 0) {
    $failures += "Tables editable cells still re-enable themselves on mouse-up and clear focus ($enableCount matches)."
}

$frameHideCount = ([regex]::Matches($tableText, 'BG\.FrameHide\(1\)')).Count
if ($frameHideCount -ne 3) {
    $failures += "Expected FrameHide(1) only in the three focus-gained handlers; found $frameHideCount calls."
}

$controlPattern = '(?s)if IsControlKeyDown\(\) then.*?' +
    'self:ClearFocus\(\).*?BG\.GoToItemLib\(self\)'
if ($tableText -notmatch $controlPattern) {
    $failures += "Gear Ctrl-click must exit editing explicitly without disabling the EditBox."
}

$owedStart = $helperText.IndexOf("function BG.CreateQiankuanButton")
$owedEnd = $helperText.IndexOf("function BG.SetListmaijia", $owedStart)
if ($owedStart -lt 0 -or $owedEnd -lt 0) {
    $failures += "Could not isolate BG.CreateQiankuanButton."
    $owedText = ""
} else {
    $owedText = $helperText.Substring($owedStart, $owedEnd - $owedStart)
}

if ($owedText -notmatch 'f:EnableMouse\(true\)') {
    $failures += "The owed marker frame must enable mouse input for tooltip and right-click clear."
}

if ($owedText -notmatch 'f:SetScript\("OnEnter"') {
    $failures += "The owed marker tooltip handler is missing."
}

if ($owedText -notmatch 'f:SetScript\("OnMouseDown"') {
    $failures += "The owed marker right-click handler is missing."
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS Tables edit focus, clear behavior, and owed hit testing are preserved"
