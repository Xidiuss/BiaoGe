param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$auctionPath = Join-Path $Root "BiaoGe\Core\Module\AuctionLog.lua"
$billPath = Join-Path $Root "BiaoGe\Core\Module\DuiZhang.lua"
$itemLibPath = Join-Path $Root "BiaoGe\Core\Module\ItemLib.lua"
$itemOutTimePath = Join-Path $Root "BiaoGe\Core\Module\ItemOutTime.lua"
$lootPath = Join-Path $Root "BiaoGe\Core\Module\Loot.lua"
$tradePath = Join-Path $Root "BiaoGe\Core\Module\Trade.lua"
$compatPath = Join-Path $Root "BiaoGe\Core\Compat.lua"
$functionPath = Join-Path $Root "BiaoGe\Core\function1.lua"
$biaoGePath = Join-Path $Root "BiaoGe\Core\BiaoGe.lua"
$clearBiaoGePath = Join-Path $Root "BiaoGe\Core\Module\ClearBiaoGe.lua"
$yyPath = Join-Path $Root "BiaoGe\Core\Module\YY.lua"
$lootDbPath = Join-Path $Root "BiaoGe\Core\DB\DB_Loot_WLK.lua"
$lootBlacklistPath = Join-Path $Root "BiaoGe\Core\DB\DB_Loot_BlackWhiteList.lua"
$localePath = Join-Path $Root "BiaoGe\Locales\enUS.lua"

$auctionText = Get-Content -LiteralPath $auctionPath -Raw -Encoding UTF8
$billText = Get-Content -LiteralPath $billPath -Raw -Encoding UTF8
$itemLibText = Get-Content -LiteralPath $itemLibPath -Raw -Encoding UTF8
$itemOutTimeText = Get-Content -LiteralPath $itemOutTimePath -Raw -Encoding UTF8
$lootText = Get-Content -LiteralPath $lootPath -Raw -Encoding UTF8
$tradeText = Get-Content -LiteralPath $tradePath -Raw -Encoding UTF8
$compatText = Get-Content -LiteralPath $compatPath -Raw -Encoding UTF8
$functionText = Get-Content -LiteralPath $functionPath -Raw -Encoding UTF8
$biaoGeText = Get-Content -LiteralPath $biaoGePath -Raw -Encoding UTF8
$clearBiaoGeText = Get-Content -LiteralPath $clearBiaoGePath -Raw -Encoding UTF8
$yyText = Get-Content -LiteralPath $yyPath -Raw -Encoding UTF8
$lootDbText = Get-Content -LiteralPath $lootDbPath -Raw -Encoding UTF8
$lootBlacklistText = Get-Content -LiteralPath $lootBlacklistPath -Raw -Encoding UTF8
$localeText = Get-Content -LiteralPath $localePath -Raw -Encoding UTF8
$failures = @()

function Get-Block {
    param(
        [string]$Text,
        [string]$StartPattern,
        [string]$EndPattern,
        [string]$Description
    )

    $match = [regex]::Match($Text, "(?s)$StartPattern(.*?)$EndPattern")
    if (-not $match.Success) {
        $script:failures += "Could not isolate $Description."
        return ""
    }
    return $match.Groups[1].Value
}

# US1: the row that owns hover, context actions, and batch selection must be
# the mouse hit target.
$rowFactory = Get-Block `
    -Text $auctionText `
    -StartPattern 'local function CreateButton\(index, v, isHistory, num\)' `
    -EndPattern '\n\s*function CancelAllChoose\(\)' `
    -Description "the Auto Auction Log row factory"

foreach ($marker in @(
    'f:EnableMouse(true)',
    'f:SetScript("OnEnter"',
    'f:SetScript("OnLeave"',
    'f:SetScript("OnMouseDown"'
)) {
    if (-not $rowFactory.Contains($marker)) {
        $failures += "Auto Auction Log rows are missing interaction marker: $marker"
    }
}

# Post-trade cosmetic gate A: the item name must consume the actual free row
# width and stop before the optional localized Traded marker.
foreach ($marker in @(
    'bts.trade = text',
    'text:SetPoint("TOPRIGHT", bts.trade, "TOPLEFT", -4, 0)',
    'text:SetPoint("TOPRIGHT", bts.frame, "TOPRIGHT", -1, 0)'
)) {
    if (-not $rowFactory.Contains($marker)) {
        $failures += "Auto Auction Log item-name geometry is missing marker: $marker"
    }
}
$fixedRowWidths = ([regex]::Matches(
    $rowFactory,
    'text:SetWidth\(width - bts\.icon:GetWidth\(\)\)'
)).Count
if ($fixedRowWidths -ne 1) {
    $failures += "Only the buyer/amount line may retain the fixed row width (found $fixedRowWidths uses)."
}

# US1: success and failure must share the same routing boundary.
if ($auctionText -notmatch 'local function ResolveAuctionFB\(item\)') {
    $failures += "Automatic-auction outcomes need one canonical raid resolver."
}
$resolverCalls = ([regex]::Matches(
    $auctionText,
    'local FB\s*=\s*ResolveAuctionFB\(zhuangbei\)'
)).Count
if ($resolverCalls -ne 2) {
    $failures += "Success and failure must both use ResolveAuctionFB (expected 2 calls, found $resolverCalls)."
}

$auctionEnd = Get-Block `
    -Text $auctionText `
    -StartPattern 'function BG\.AuctionWAEnd\(endType, zhuangbei, maijia, jine\)' `
    -EndPattern '\n\s*end\s*\n\s*end\s*\n\s*\n\s*--' `
    -Description "BG.AuctionWAEnd"
if ($auctionEnd -match 'local FB\s*=\s*BG\.FB2\s+or\s+BG\.FB1') {
    $failures += "Successful auctions must not skip the item-to-Table resolver."
}
if ($auctionEnd -match 'local FB\s*=\s*BG\.FB1') {
    $failures += "Failed auctions must not route directly to the visible table."
}

# Runtime Gate 1: Search is a visual hint, never a physical filter value.
$searchSetup = [regex]::Match(
    $auctionText,
    '(?s)CreateFrame\("EditBox", nil, f, "BiaoGe_SearchBoxTemplate"\)(.*?)(?:\n\s*end\s*\n\s*end\s*\n\s*\n\s*--)'
)
if (-not $searchSetup.Success) {
    $failures += "Could not isolate the Auto Auction Log search setup."
} else {
    $searchBody = $searchSetup.Groups[1].Value
    if ($searchBody -notmatch 'edit\.Instructions:SetText\(L\["[^"]+"\]\)') {
        $failures += "Auto Auction Log must render a localized visual Search hint."
    }
    if ($localeText -notmatch 'L\["[^"]+"\]\s*=\s*"Search"') {
        $failures += "enUS must provide the standalone visual Search hint."
    }
    foreach ($marker in @(
        'edit:SetText("")',
        'edit:SetScript("OnEditFocusLost", EditBox_ClearHighlight)',
        'edit.Instructions:ClearAllPoints()',
        'edit.Instructions:SetPoint("LEFT", edit, "LEFT", 18, 0)'
    )) {
        if (-not $searchBody.Contains($marker)) {
            $failures += "Auto Auction Log visual Search placeholder is missing marker: $marker"
        }
    }
}

# US2: both localized display bodies must be closed before chat/native hooks
# receive the links.
$closedBillLinks = ([regex]::Matches(
    $billText,
    '(?s)local link\s*=\s*format\(L\["\|Hgarrmission:BiaoGeDuiZhang(?:Copy)?:.*?\)\s*\.\.\s*"\|h\|r"'
)).Count
if ($closedBillLinks -ne 2) {
    $failures += "Both Bills action links must append a closing |h|r (found $closedBillLinks)."
}
if ($billText -notmatch '(?s)BiaoGeDuiZhang == "BiaoGeDuiZhang".*?BG\.DuiZhangSet\(num\)') {
    $failures += "Reconcile payload handling must remain connected to the encoded record."
}
if ($billText -notmatch '(?s)BiaoGeDuiZhang == "BiaoGeDuiZhangCopy".*?CopyBill\(num, FB\)') {
    $failures += "Copy payload handling must remain connected to the encoded record and raid."
}

# Runtime Gate 1: intercepted custom links must dispatch directly instead of
# relying on a post-hook after the compatibility early return.
foreach ($marker in @(
    'function ns.RegisterCustomLinkHandler(',
    'function ns.DispatchCustomLink(',
    'ns.DispatchCustomLink(link, text, button, chatFrame)'
)) {
    if (-not $compatText.Contains($marker)) {
        $failures += "Custom-link compatibility dispatch is missing marker: $marker"
    }
}
$billRegistrations = ([regex]::Matches(
    $billText,
    'ns\.RegisterCustomLinkHandler\("BiaoGeDuiZhang(?:Copy)?"'
)).Count
if ($billRegistrations -ne 2) {
    $failures += "Both Bills action types must register with the direct custom-link dispatcher (found $billRegistrations)."
}

# Runtime Gate 2: chat links must resolve a stable saved-record token before
# indexing mutable Reconciliation arrays, while retaining old numeric links.
foreach ($marker in @(
    'local function ResolveDuiZhangNum(',
    'recordToken = recordToken or (BiaoGe.duizhang[num] and BiaoGe.duizhang[num].t)',
    'num .. ":" .. recordToken',
    'num = ResolveDuiZhangNum(num, recordToken)',
    'local savedNum = #BiaoGe.duizhang',
    'Send(savedNum, sumMoney, FB, recordToken)',
    'BG.SendSystemMessage(L["'
)) {
    if (-not $billText.Contains($marker)) {
        $failures += "Bills stable record resolution is missing marker: $marker"
    }
}
if ($billText -notmatch '(?s)local function ResolveDuiZhangNum\(.*?for i, v in ipairs\(BiaoGe\.duizhang or \{\}\).*?tonumber\(v\.t\).*?BiaoGe\.duizhang\[num\]') {
    $failures += "Bills resolver must prefer timestamp identity and retain legacy numeric-index fallback."
}

# Runtime Gate 1/2: fresh loot metadata is asynchronous in ClassicAPI 1.23,
# whose unresolved callbacks are discarded at timeout. Critical persistence
# therefore needs an idempotent post-window final harvest.
foreach ($marker in @(
    'local function ProcessLootItem(',
    'local lootNumb = numb',
    'Item:CreateFromItemID(itemID)',
    'item:ContinueOnItemLoad(ProcessLootItem)',
    'local lootProcessed',
    'if lootProcessed then return end',
    'lootProcessed = true',
    'BG.After(8, ProcessLootItem)'
)) {
    if (-not $lootText.Contains($marker)) {
        $failures += "Eligible loot cache synchronization is missing marker: $marker"
    }
}
if ($lootText -notmatch '(?s)local function ProcessLootItem\(.*?GetItemInfo\(link\).*?quality < BG\.lootQuality\[FB\]') {
    $failures += "Loot eligibility checks must run inside the post-cache processor."
}

# Runtime Gate 3: Retail renamed the WotLK loot-slot item predicate. Keep the
# compatibility choice local to the one module that owns all nine consumers.
if ($lootText -notmatch '(?m)^local LootSlotHasItem\s*=\s*LootSlotHasItem\s+or\s+LootSlotIsItem\s*$') {
    $failures += "Loot.lua needs one module-local LootSlotHasItem/LootSlotIsItem compatibility alias."
}
$lootSlotConsumers = ([regex]::Matches($lootText, 'LootSlotHasItem\(')).Count
if ($lootSlotConsumers -ne 9) {
    $failures += "The loot-slot compatibility alias must cover all nine consumers (found $lootSlotConsumers)."
}
if ($lootText -match '(?m)^LootSlotHasItem\s*=') {
    $failures += "Loot-slot compatibility must not create or replace a global function."
}

# Runtime Gate 3 follow-up: optional WotLK loot templates can be absent. Both
# loot consumers must share one nil-safe parser instead of calling gsub on
# globals directly.
foreach ($marker in @(
    'local function MatchLootTemplate(msg, template, multiple)',
    'if type(template) ~= "string" then return end',
    'local function ParseLootMessage(msg)'
)) {
    if (-not $lootText.Contains($marker)) {
        $failures += "Nil-safe loot-message parsing is missing marker: $marker"
    }
}
$lootParserConsumers = ([regex]::Matches(
    $lootText,
    '=\s*ParseLootMessage\(msg\)'
)).Count
if ($lootParserConsumers -ne 2) {
    $failures += "Both Loot.lua message consumers must use ParseLootMessage (found $lootParserConsumers)."
}
if ($lootText -match '(?:string\.)?gsub\s*\(\s*LOOT_ITEM|LOOT_ITEM[A-Z_]*:gsub') {
    $failures += "Loot.lua must not call gsub directly on optional LOOT_ITEM globals."
}

# Runtime Gate 3 follow-up: WotLK candidate lookup accepts only the candidate
# index. Preserve the later-client two-argument form behind one helper and
# make every lookup use the index that is later passed to GiveMasterLoot.
foreach ($marker in @(
    'local function GetLootCandidate(slot, index)',
    'if BG.IsWLK_80 then',
    'return GetMasterLootCandidate(index)',
    'return GetMasterLootCandidate(slot, index)'
)) {
    if (-not $lootText.Contains($marker)) {
        $failures += "Master-loot candidate compatibility is missing marker: $marker"
    }
}
$lootCandidateConsumers = ([regex]::Matches(
    $lootText,
    'GetLootCandidate\(li,\s*ci\)'
)).Count
if ($lootCandidateConsumers -ne 4) {
    $failures += "All four master-loot candidate consumers must use the compatibility helper (found $lootCandidateConsumers)."
}
if ($lootText -match 'GetMasterLootCandidate\(li,\s*ci\)') {
    $failures += "Loot.lua still passes the Retail two-argument signature directly on WotLK."
}

# Runtime Gate 3 follow-up: emblems are currency-like exact-ID exclusions, not
# generic stackable loot. Keep the scope in the existing WotLK blacklist.
$wlkBlacklist = Get-Block `
    -Text $lootBlacklistText `
    -StartPattern 'else\s*\n\s*-- WLK.*?BG\.Loot\.blacklist\s*=\s*\{' `
    -EndPattern '\n\s*\}\s*\n\s*-- ICC' `
    -Description "the WotLK loot blacklist"
foreach ($emblemID in @("40752", "40753", "45624", "47241", "49426", "90630")) {
    if ($wlkBlacklist -notmatch ('(?<!\d)' + $emblemID + '(?!\d)')) {
        $failures += "WotLK loot blacklist is missing emblem item $emblemID."
    }
}

# Runtime Gate 3 L7: WotLK exposes only the first seven GetInstanceInfo
# returns. Resolve supported raid IDs once from the native instance name and
# migrate every equivalent consumer without replacing the global API.
foreach ($marker in @(
    'function BG.GetCurrentSupportedInstanceID()',
    'local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()',
    'if instanceID and BG.FBIDtable[instanceID] then',
    'for supportedInstanceID in pairs(BG.FBIDtable) do',
    'if GetRealZoneText(supportedInstanceID) == instanceName then',
    'return supportedInstanceID'
)) {
    if (-not $functionText.Contains($marker)) {
        $failures += "Current supported-instance resolver is missing marker: $marker"
    }
}

$supportedInstanceConsumers = ([regex]::Matches(
    $biaoGeText + $clearBiaoGeText + $yyText,
    'BG\.GetCurrentSupportedInstanceID\(\)'
)).Count
if ($supportedInstanceConsumers -ne 3) {
    $failures += "All three equivalent supported-instance consumers must use the shared resolver (found $supportedInstanceConsumers)."
}

foreach ($consumer in @(
    @{ Name = "Core/BiaoGe.lua"; Text = $biaoGeText },
    @{ Name = "Core/Module/ClearBiaoGe.lua"; Text = $clearBiaoGeText },
    @{ Name = "Core/Module/YY.lua"; Text = $yyText }
)) {
    if ($consumer.Text -match 'select\s*\(\s*8\s*,\s*GetInstanceInfo\(\)\s*\)') {
        $failures += "$($consumer.Name) still reads Retail's absent eighth GetInstanceInfo return."
    }
    if ($consumer.Text -match 'instanceID\s*=\s*GetInstanceInfo\(\)') {
        $failures += "$($consumer.Name) still destructures Retail's absent instanceID return."
    }
}

foreach ($traceMarker in @(
    'bgloottrace',
    'LootTrace',
    'lootTraceEnabled',
    'lootTraceByItemID'
)) {
    if ($lootText.Contains($traceMarker)) {
        $failures += "Temporary loot trace must be removed before production: $traceMarker"
    }
}

# Runtime Gate 3 L10: WotLK has no ENCOUNTER_START/END payload contract.
# Capture the boss row from boss units and use the loot DB only when it gives
# one unambiguous source instead of guessing the first shared-drop match.
foreach ($marker in @(
    'f:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")',
    'local function SetBossIndexFromUnits(',
    'local unit = "boss" .. i',
    'local unitName = UnitName(unit)',
    'bossInfo.name2 == unitName',
    'BG.RegisterEvent("PLAYER_REGEN_ENABLED"',
    'local function GetBossIndexByLootItem(',
    'local difficultyID = GetRaidDifficultyID and GetRaidDifficultyID()',
    'local diffName = BG.diffIDTbl[FB] and BG.diffIDTbl[FB][difficultyID] or "N"',
    'if #candidates == 1 then',
    'lootNumb = GetBossIndexByLootItem(FB, itemID)'
)) {
    if (-not $lootText.Contains($marker)) {
        $failures += "WotLK boss-row routing is missing marker: $marker"
    }
}
if ($lootText -match '(?s)GetBossIndexByLootItem\(.*?return candidates\[1\].*?#candidates') {
    $failures += "Loot DB fallback must prove uniqueness before selecting a boss row."
}

# Runtime Gate 1: WotLK master-looter ownership must not be permanently false.
$masterLooterBlock = Get-Block `
    -Text $compatText `
    -StartPattern 'if not IsMasterLooter then' `
    -EndPattern '\nend\s*\n\s*\n-- 18\.' `
    -Description "the WotLK IsMasterLooter compatibility block"
foreach ($marker in @(
    'GetLootMethod()',
    'partyIndex == 0',
    'raidIndex',
    'BG.masterLooter',
    'BG.playerName'
)) {
    if (-not $masterLooterBlock.Contains($marker)) {
        $failures += "Master-looter compatibility is missing marker: $marker"
    }
}
# Runtime Gate 1: trade-time parsing must tolerate English spacing, case, and
# singular/plural forms.
foreach ($marker in @(
    'local function ParseTradeTimeRemaining(',
    ':lower()',
    'gsub("%s+", "")',
    'h = h or tonumber(normalized:match("(%d+)hour"))',
    'h = h or tonumber(normalized:match("(%d+)hr"))',
    'm = m or tonumber(normalized:match("(%d+)min"))',
    'ParseTradeTimeRemaining(time)'
)) {
    if (-not $itemOutTimeText.Contains($marker)) {
        $failures += "Gear Exp Rem Time parser is missing marker: $marker"
    }
}

# Runtime Gate 1: trade completion follows the saved auction record, not the
# currently visible/physical raid table.
foreach ($marker in @(
    'local function FindAuctionTradeRecord(',
    'for _, FB in ipairs(BG.FBtable) do',
    'BG.GSN(v.maijia) == BG.GSN(tradeName)',
    'for _ = 1, (vv.count or 1) do'
)) {
    if (-not $tradeText.Contains($marker)) {
        $failures += "Cross-table auction trade matching is missing marker: $marker"
    }
}
$tradeState = Get-Block `
    -Text $tradeText `
    -StartPattern 'function T\.SetItemTradeState\(\)' `
    -EndPattern '\n\s*end\s*\n\s*end\s*\n\s*\n\s*--' `
    -Description "T.SetItemTradeState"
if ($tradeState -match 'local FB\s*=\s*BG\.FB2\s+or\s+BG\.FB1') {
    $failures += "Trade status must not be limited to the current physical/visible table."
}
if ($tradeState -match 'IsInRaid\(1\)') {
    $failures += "Trade status must still update after the raid has ended."
}

# Post-commit runtime gate: WotLK sends UI_INFO_MESSAGE with the message as
# its first payload, while later clients prepend an errorType. The sole trade
# completion boundary must normalize both shapes before invoking every
# existing persistence writer.
foreach ($marker in @(
    'local function GetUIInfoMessage(arg1, arg2)',
    'if type(arg2) == "string" then return arg2 end',
    'if type(arg1) == "string" then return arg1 end',
    'local tradeCompleteMessage = ERR_TRADE_COMPLETE or LE_GAME_ERR_TRADE_COMPLETE',
    'BG.RegisterEvent("UI_INFO_MESSAGE", function(self, event, arg1, arg2)',
    'local text = GetUIInfoMessage(arg1, arg2)',
    'if text == tradeCompleteMessage then'
)) {
    if (-not $tradeText.Contains($marker)) {
        $failures += "Trade-complete payload normalization is missing marker: $marker"
    }
}
$tradeCompleteBlock = Get-Block `
    -Text $tradeText `
    -StartPattern 'BG\.RegisterEvent\("UI_INFO_MESSAGE"' `
    -EndPattern '\n\s*end\)\s*\n\s*end\)' `
    -Description "the UI_INFO_MESSAGE trade-completion block"
foreach ($marker in @(
    'BG.tradeSameMoney:SaveTradeMoney()',
    'BG.tradeSeeFrame.frame:SaveMoney()',
    'T.SetItemTradeState()',
    'T.SaveTradeFastGiveMoney()'
)) {
    if (-not $tradeCompleteBlock.Contains($marker)) {
        $failures += "Trade completion lost downstream writer: $marker"
    }
}
if ($tradeText -match 'BG\.RegisterEvent\("UI_INFO_MESSAGE", function\(self, event, _, text\)') {
    $failures += "Trade completion still assumes the later-client two-payload UI_INFO_MESSAGE shape."
}

# Post-trade cosmetic gate C: Reset and Update must agree about preview
# eligibility, and every visible English label must use an existing locale
# key and measured geometry.
$tradePreviewReset = Get-Block `
    -Text $tradeText `
    -StartPattern 'function BG\.tradeSeeFrame\.frame:Reset\(\)' `
    -EndPattern '\n\s*end\s*\n\s*\n\s*function BG\.tradeSeeFrame\.frame:Update\(\)' `
    -Description "Accounting Preview Reset"
if ($tradePreviewReset -notmatch 'IsInRaid\(1\)\s+and\s+not BG\.IsAutoCreateBill\(\)') {
    $failures += "Accounting Preview Reset must suppress automatic-bill raid members just like Update."
}
foreach ($marker in @(
    'text:SetWordWrap(false)',
    'text:SetWidth(text:GetStringWidth())',
    'f:SetWidth(edit:GetWidth() + text:GetWidth() + 18)'
)) {
    if (-not $tradeText.Contains($marker)) {
        $failures += "Trade preview localization/layout is missing marker: $marker"
    }
}
$refundKey = [regex]::Match(
    $tradeText,
    '(?s)CreateFrame\("CheckButton", "BiaoGeTradeRefundCheck".*?bt\.Text:SetText\(L\["([^"]+)"\]\)'
)
if (-not $refundKey.Success -or
    -not $localeText.Contains('L["' + $refundKey.Groups[1].Value + '"]')) {
    $failures += "The Return item checkbox must use an enUS-defined localization key."
} else {
    $refundEnglish = [regex]::Match(
        $localeText,
        'L\["' + [regex]::Escape($refundKey.Groups[1].Value) + '"\]\s*=\s*"([^"]+)"'
    )
    if (-not $refundEnglish.Success -or $refundEnglish.Groups[1].Value -ne "Return item") {
        $failures += "The concise enUS refund action must read 'Return item'."
    }
}
$automaticDebt = [regex]::Match(
    $tradeText,
    'qiankuanText = format\("\|cffFF0000" \.\. L\["([^"]+)"\] \.\. RR, qiankuan\)'
)
if (-not $automaticDebt.Success -or
    -not $localeText.Contains('L["' + $automaticDebt.Groups[1].Value + '"]')) {
    $failures += "The automatic-auction debt suffix must color an enUS-defined plain localization key."
}

# Post-trade return gate D: both clients already own the successful trade
# snapshot. They must apply the same local reversal without inventing a new
# addon-message protocol, and the reversed sale must become Unauctioned
# rather than polluting the duplicate/error Re-auction projection.
foreach ($marker in @(
    'local function FindReturnedTableItem(Player, link)',
    'local function RemoveReturnedAuctionRecord(returned)',
    'local function FinalizeReturnedItem(returned)',
    'returned.buyer:Clear()',
    'returned.money:Clear()',
    'returned.money:ClearQK()',
    'tremove(BiaoGe[returned.FB].auctionLog, newestIndex)',
    'if #BG.trade.playeritems == 1 and BG.IsMLByName(BG.trade.target) then',
    'local returned = FindReturnedTableItem(BG.playerName, BG.trade.playeritems[1].link)',
    'FinalizeReturnedItem(returned)'
)) {
    if (-not $tradeText.Contains($marker)) {
        $failures += "Cross-client returned-item finalization is missing marker: $marker"
    }
}
if ($tradeText -match 'SendAddonMessage\([^,\r\n]+,\s*"[^"]*[Rr]eturn') {
    $failures += "Returned-item synchronization must use the existing local trade snapshot, not a new wire protocol."
}

# US3: cache readiness must cover the bundled seven-second ClassicAPI item
# loader and perform one final synchronous harvest.
if ($itemLibText -match 'timeElapsed\s*>=\s*2') {
    $failures += "Gear Lib must not declare its item cache ready after two seconds."
}
$timeoutMatch = [regex]::Match(
    $itemLibText,
    'local ITEM_CACHE_TIMEOUT\s*=\s*(\d+(?:\.\d+)?)'
)
if (-not $timeoutMatch.Success -or [double]$timeoutMatch.Groups[1].Value -lt 7) {
    $failures += "Gear Lib cache timeout must cover the seven-second item-loader window."
}
foreach ($marker in @(
    'local function CacheItemInfo(',
    'local function FinalizePendingItems()',
    'for itemID in pairs(pendingItems) do',
    'CacheItemInfo(FB, itemID)'
)) {
    if (-not $itemLibText.Contains($marker)) {
        $failures += "Gear Lib cache completion is missing marker: $marker"
    }
}

# Every numeric WotLK dungeon source used by the DB must resolve to a name.
$mapIDs = [regex]::Matches($lootDbText, 'GetRealZoneText\((\d+)\)') |
    ForEach-Object { [int]$_.Groups[1].Value } |
    Sort-Object -Unique
foreach ($mapID in $mapIDs) {
    if ($compatText -notmatch ('\[' + $mapID + '\]\s*=\s*"[^"]+"')) {
        $failures += "GetRealZoneText compatibility map is missing WotLK dungeon ID $mapID."
    }
}

# Every localized key consumed by the WotLK loot DB needs an enUS assignment;
# otherwise the locale metatable returns '?' and Acquisition becomes partial.
$dbLocaleKeys = [regex]::Matches($lootDbText, 'L\["([^"]+)"\]') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
$enLocaleKeys = [regex]::Matches($localeText, 'L\["([^"]+)"\]\s*=') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
$missingLocaleKeys = @($dbLocaleKeys | Where-Object { $_ -notin $enLocaleKeys })
if ($missingLocaleKeys.Count -gt 0) {
    $failures += "enUS is missing $($missingLocaleKeys.Count) WotLK loot-source keys: $($missingLocaleKeys -join ', ')"
}

# Protect the already-correct category and data ownership boundaries.
foreach ($equipLoc in @(
    "INVTYPE_2HWEAPON",
    "INVTYPE_WEAPON",
    "INVTYPE_WEAPONMAINHAND",
    "INVTYPE_RANGED",
    "INVTYPE_RANGEDRIGHT",
    "INVTYPE_THROWN",
    "INVTYPE_RELIC"
)) {
    if ($itemLibText -notmatch ('key\s*=\s*\{[^}]*"' + $equipLoc + '"')) {
        $failures += "Gear Lib category mapping lost $equipLoc."
    }
}
foreach ($difficulty in @("H10", "H25")) {
    if ($lootDbText -notmatch ('BG\.Loot\[FB\]\.' + $difficulty + '\.boss1\s*=\s*\{\s*\d+')) {
        $failures += "ICC source data must retain populated $difficulty loot."
    }
}
$tocBlock = Get-Block `
    -Text $lootDbText `
    -StartPattern '-- TOC\s+do\s+local FB = "TOC"' `
    -EndPattern '\n\s*-- ULD' `
    -Description "the TOC loot dataset"
foreach ($intentionalID in @("46024", "45311")) {
    if (-not $tocBlock.Contains($intentionalID)) {
        $failures += "Intentional Trial of the Champion redistribution lost item $intentionalID."
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS critical auction, Bills, and Gear Lib workflow contracts"
