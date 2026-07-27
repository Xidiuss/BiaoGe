param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$yyPath = Join-Path $Root "BiaoGe\Core\Module\YY.lua"
$yyText = Get-Content -LiteralPath $yyPath -Raw -Encoding UTF8
$failures = @()

function Require-Text {
    param(
        [string]$Needle,
        [string]$Message
    )

    if (-not $yyText.Contains($Needle)) {
        $script:failures += $Message
    }
}

if ($yyText -match 'SetNumeric\(true\)') {
    $failures += "Nickname EditBoxes must not retain numeric-only input mode."
}

$nicknameMaxByteCalls = [regex]::Matches($yyText, 'SetMaxBytes\(64\)').Count
if ($nicknameMaxByteCalls -ne 3) {
    $failures += "All three nickname EditBoxes must share the chat-safe 64-byte limit (expected 3, found $nicknameMaxByteCalls)."
}

$setAllMatch = [regex]::Match(
    $yyText,
    '(?s)function Y\.SetAll\(\)(.*?)BG\.YYMainFrame\.my\.all\.button = \{\}\s+Y\.SetAll\(\)'
)
if (-not $setAllMatch.Success) {
    $failures += "Could not isolate the saved-evaluation row factory."
} else {
    $setAllText = $setAllMatch.Groups[1].Value
    foreach ($required in @(
        'f:EnableMouse(true)',
        'f:SetScript("OnMouseDown", OnMouseDown)',
        'f:SetScript("OnEnter", OnEnter)',
        'f:SetScript("OnLeave", OnLeave)'
    )) {
        if (-not $setAllText.Contains($required)) {
            $failures += "Saved evaluation cells are missing interaction marker: $required"
        }
    }
}

if ($yyText -match 'YELLOW_FONT_COLOR:GetRGB\(\)') {
    $failures += "Inquiry must not assume YELLOW_FONT_COLOR has a ColorMixin GetRGB method."
}

foreach ($required in @(
    'local function NormalizeNickname(value)',
    'local function SameNickname(left, right)',
    'local function EncodeNickname(value)',
    'local function DecodeNickname(value)',
    'return strtrim(tostring(value or ""))',
    'return strlower(nickname)',
    'return format("%02X", string.byte(character))',
    'return string.char(tonumber(byte, 16))',
    'local nickname = NormalizeNicknameForStorage(edit:GetText())',
    'local sendtext = "yyn" .. EncodeNickname(nickname) .. "," .. previous_date',
    'strmatch(text, "^yyn([%x]+),(%d+)$")',
    'local yy = encodedNickname and DecodeNickname(encodedNickname)',
    'if SameNickname(yy, v.yy)',
    'BG.EndPJ.nickname = yy',
    'BG.EndPJ.new.yy:SetText(BG.EndPJ.nickname or BG.GetLeaderYY())'
)) {
    Require-Text $required "Nickname behavior is missing canonical marker: $required"
}

$sameNicknameCalls = [regex]::Matches($yyText, 'SameNickname\(').Count
if ($sameNicknameCalls -lt 15) {
    $failures += "All identity consumers must share canonical nickname matching (expected at least 15 calls, found $sameNicknameCalls)."
}

if ($yyText -match 'tonumber\([^)]*(?:\byy\b|\.yy\b|cleanedYY\b)[^)]*\)') {
    $failures += "Nickname identity must not be converted through tonumber; only dates and ratings remain numeric."
}

if ($yyText -match 'strmatch\(text,\s*"yy\(%d\+\),\(%d\+\)"\)') {
    $failures += "Share discovery must not retain the numeric-only YY request parser."
}

$searchMatch = [regex]::Match(
    $yyText,
    '(?s)function Y\.SearchButtonOnClick\(\)(.*?)local CDing = \{\}'
)
if (-not $searchMatch.Success) {
    $failures += "Could not isolate the public Inquiry workflow."
} elseif ($searchMatch.Groups[1].Value -notmatch 'local previous_date\s*=\s*tonumber\(date\("%y%m%d", previous_time\)\)\s*or\s*0') {
    $failures += "Inquiry cutoff date must use the proven WotLK nil-to-zero fallback before protocol concatenation."
}

if ($yyText -notmatch 'value\.yy\s*=\s*NormalizeNicknameForStorage\(value\.yy\)') {
    $failures += "Saved nickname values must be normalized for storage while retaining the compatible yy member."
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS YY Evaluation text nickname, row interaction, Inquiry, and Share contract"
