param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$optionsPath = Join-Path $Root "BiaoGe\Core\Options.lua"
$optionsText = Get-Content -LiteralPath $optionsPath -Raw -Encoding UTF8
$failures = @()

$tabCallPattern = '=\s*BG\.OptionsCreateTab\("([^"]+)"'
$tabCalls = [regex]::Matches($optionsText, $tabCallPattern)
$expectedTabs = @(
    "Options_biaoge",
    "Options_autoAuction",
    "Options_roleOverview",
    "Options_boss",
    "Options_map",
    "Options_others",
    "Options_config"
)

if ($tabCalls.Count -ne $expectedTabs.Count) {
    $failures += "Expected seven Interface Options tab call sites; found $($tabCalls.Count)."
} else {
    for ($i = 0; $i -lt $expectedTabs.Count; $i++) {
        if ($tabCalls[$i].Groups[1].Value -ne $expectedTabs[$i]) {
            $failures += "Tab order changed at position $($i + 1): expected $($expectedTabs[$i])."
        }
    }
}

if ($optionsText -notmatch 'local tabButtons\s*=\s*\{\s*\}') {
    $failures += "Options must track the complete runtime tab row."
}

$layoutMatch = [regex]::Match(
    $optionsText,
    '(?s)local function LayoutOptionsTabs\(\)(.*?)function BG\.OptionsCreateTab'
)
if (-not $layoutMatch.Success) {
    $failures += "Could not isolate the complete-row layout function."
    $layoutText = ""
} else {
    $layoutText = $layoutMatch.Groups[1].Value
}

$fontHelperMatch = [regex]::Match(
    $optionsText,
    '(?s)local function SetOptionsTabsFontObjects\(normalFont, disabledFont, highlightFont\)(.*?)local function GetOptionsTabsTextWidth'
)
if (-not $fontHelperMatch.Success -or
    $fontHelperMatch.Groups[1].Value -notmatch 'ipairs\(tabButtons\)' -or
    $fontHelperMatch.Groups[1].Value -notmatch 'SetNormalFontObject\(normalFont\)' -or
    $fontHelperMatch.Groups[1].Value -notmatch 'SetDisabledFontObject\(disabledFont\)' -or
    $fontHelperMatch.Groups[1].Value -notmatch 'SetHighlightFontObject\(highlightFont\)') {
    $failures += "Font fallback must apply one coherent state set to every runtime tab."
}

$textWidthHelperMatch = [regex]::Match(
    $optionsText,
    '(?s)local function GetOptionsTabsTextWidth\(\)(.*?)local function LayoutOptionsTabs'
)
if (-not $textWidthHelperMatch.Success -or
    $textWidthHelperMatch.Groups[1].Value -notmatch 'ipairs\(tabButtons\)' -or
    $textWidthHelperMatch.Groups[1].Value -notmatch 'textWidth\s*=\s*textWidth\s*\+\s*button:GetFontString\(\):GetStringWidth\(\)') {
    $failures += "Intrinsic width measurement must census every current runtime tab."
}

foreach ($marker in @(
    'SettingsPanel.Container:GetWidth() - 30',
    'button:GetFontString():GetStringWidth()',
    'ipairs(tabButtons)',
    'button:SetWidth('
)) {
    if (-not $layoutText.Contains($marker)) {
        $failures += "Row layout is missing contract marker: $marker"
    }
}

if ($layoutText -notmatch 'min\(20,\s*max\(0,\s*\(availableWidth\s*-\s*textWidth\)\s*/\s*#tabButtons\)\)') {
    $failures += "Row allowance must share remaining width, clamp at zero, and preserve the existing 20-pixel maximum."
}

foreach ($compactMarker in @(
    'if textWidth > availableWidth then',
    'BG.FontBlue15',
    'BG.FontWhite18',
    'BG.FontWhite15',
    'BG.FontBlue13',
    'BG.FontWhite14',
    'BG.FontWhite13'
)) {
    if (-not $layoutText.Contains($compactMarker)) {
        $failures += "Overflowing intrinsic label widths must activate the compact row font contract: $compactMarker"
    }
}

if ($layoutText -notmatch '(?s)if textWidth > availableWidth then.*?textWidth\s*=\s*GetOptionsTabsTextWidth\(\)') {
    $failures += "Row width must be remeasured after applying compact fonts."
}

if ($optionsText -notmatch 'tinsert\(tabButtons,\s*bt\)') {
    $failures += "Every constructed options tab must join the row census."
}

if ($optionsText -match 'bt:SetWidth\(t:GetStringWidth\(\)\s*\+\s*20\)') {
    $failures += "Independent text-width-plus-20 sizing still bypasses the container."
}

if ($optionsText -notmatch '(?s)BG\.HideTab\(Frames,\s*BG\["Frame"\s*\.\.\s*name\]\).*?LayoutOptionsTabs\(\).*?BiaoGe\.options\.lastFrame') {
    $failures += "Selection must reflow after enabled-state font changes and preserve lastFrame."
}

if ($optionsText -notmatch 'main:HookScript\("OnShow",\s*LayoutOptionsTabs\)') {
    $failures += "Options must reflow when the container is shown at its final width."
}

if ($optionsText -notmatch '(?s)if BiaoGe\.options\.lastFrame.*?SetEnabled\(false\).*?else.*?SetEnabled\(false\).*?end\s+LayoutOptionsTabs\(\)') {
    $failures += "Initial layout must run after the selected tab receives its disabled font."
}

if ($optionsText -match 'ButtonOptions_config.*?Set(?:Point|Width|Scale)' -or
    $optionsText -match 'name\s*==\s*"Options_config"') {
    $failures += "Configuration must not receive a one-off geometry override."
}

foreach ($preserved in @(
    'bt:SetPoint("TOPLEFT", 15, -35)',
    'bt:SetPoint("LEFT", last, "RIGHT", 0, 0)',
    'BiaoGe.options.lastFrame = "Frame" .. name',
    'BG.PlaySound(1)'
)) {
    if (-not $optionsText.Contains($preserved)) {
        $failures += "Existing options-tab behavior changed or disappeared: $preserved"
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS Interface Options tabs remain within the container"
