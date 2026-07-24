local _, ns = ...

-- 0a. SoundKit constants missing on some WotLK 3.3.5 clients.
SOUNDKIT = SOUNDKIT or {}
SOUNDKIT.U_CHAT_SCROLL_BUTTON = SOUNDKIT.U_CHAT_SCROLL_BUTTON or "uChatScrollButton"
SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn"
SOUNDKIT.GS_TITLE_OPTION_OK = SOUNDKIT.GS_TITLE_OPTION_OK or "gsTitleOptionOK"
SOUNDKIT.IG_MAINMENU_CLOSE = SOUNDKIT.IG_MAINMENU_CLOSE or "igMainMenuClose"

-- BiaoGe WotLK 3.3.5 Compatibility Layer
-- Loaded before Core\DB\DB.xml so polyfills are in place at module load time.
-- Requires !!!ClassicAPI to be loaded first (provides: C_Timer, CreateColor,
-- BackdropTemplate, C_Container, C_ChatInfo, SetColorTexture, CreateLine, SetAtlas, Mixin).

-- 1. GetRealmID — not in WotLK 3.3.5; use realm name as a stable key
if not GetRealmID then
    function GetRealmID()
        return GetRealmName():gsub("[%s%-]", "")
    end
end

-- 2. GetCurrentRegion — not in WotLK 3.3.5
if not GetCurrentRegion then
    function GetCurrentRegion()
        return 1
    end
end

-- 3. GetCurrentRegionName — used in function1.lua
if not GetCurrentRegionName then
    function GetCurrentRegionName()
        return "US"
    end
end

-- 4. GetClassColor — not in WotLK 3.3.5; use RAID_CLASS_COLORS instead
if not GetClassColor then
    function GetClassColor(class)
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then
            local hex = string.format("ff%02x%02x%02x",
                math.floor(c.r * 255 + 0.5),
                math.floor(c.g * 255 + 0.5),
                math.floor(c.b * 255 + 0.5))
            return c.r, c.g, c.b, hex
        end
        return 1, 1, 1, "ffffffff"
    end
end

-- 5. C_AddOns — namespace added in DF; WotLK exposes these as bare globals
if not C_AddOns then
    C_AddOns = {
        GetAddOnInfo        = GetAddOnInfo,
        GetAddOnMetadata    = GetAddOnMetadata,
        GetNumAddOns        = GetNumAddOns,
        IsAddOnLoaded       = IsAddOnLoaded,
        LoadAddOn           = LoadAddOn,
        -- GetAddOnEnableState arg order differs (retail: index,char; wotlk: char,index)
        -- Return 2 (enabled) always; metadata check gates actual usage anyway.
        GetAddOnEnableState = GetAddOnEnableState
            and function(index, char) return GetAddOnEnableState(char, index) end
            or function() return 2 end,
    }
end

-- 6. C_Spell — partial stub; ClassicAPI provides this; fallback only
if not C_Spell then
    C_Spell = { GetSpellLink = GetSpellLink }
end

-- 6b. Enum.SocialWhoOrigin — used in WhoHistory.lua; not in ClassicAPI's Enum.lua
if Enum and not Enum.SocialWhoOrigin then
    Enum.SocialWhoOrigin = { Social = 0 }
end

-- 7. C_EncodingUtil — Retail-only compress/decompress; identity stubs preserve
--    correctness since both sender and receiver run the same WotLK build.
if not C_EncodingUtil then
    C_EncodingUtil = {
        CompressString   = function(s) return s end,
        DecompressString = function(s) return s end,
    }
end

-- 8. C_WowTokenPublic — WoW Token doesn't exist in WotLK; stubs silence errors.
if not C_WowTokenPublic then
    C_WowTokenPublic = {
        GetCurrentMarketPrice = function() return nil end,
        UpdateMarketPrice     = function() end,
    }
end

-- 9. C_CurrencyInfo — retail-shaped wrapper for WotLK currency data.
if not C_CurrencyInfo then
    C_CurrencyInfo = {}
end
do
    local nativeGetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
    local getItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
    local fallbackCurrency = {
        [341] = { name = "Emblem of Frost", itemID = 49426 },
        [301] = { name = "Emblem of Triumph", itemID = 47241 },
        [221] = { name = "Emblem of Conquest", itemID = 45624 },
        [102] = { name = "Emblem of Valor", itemID = 40753 },
        [101] = { name = "Emblem of Heroism", itemID = 40752 },
        [241] = { name = "Champion's Seal", itemID = 44990 },
        [61] = { name = "Dalaran Jewelcrafter's Token", itemID = 41596 },
        [81] = { name = "Dalaran Cooking Award", itemID = 43016 },
        [161] = { name = "Stone Keeper's Shard", itemID = 43228 },
        [1900] = { name = ARENA_POINTS or "Arena Points", iconFileID = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon" },
        [1901] = { name = HONOR_POINTS or "Honor Points", iconFileID = "Interface\\PVPFrame\\PVP-Currency-Honor" },
        [42] = { name = "Badge of Justice", itemID = 29434 },
        [2589] = { name = "Sidereal Essence" },
        [2711] = { name = "Defiler's Scourgestone" },
    }

    local function GetCurrencyLinkID(index)
        if GetCurrencyListLink then
            local link = GetCurrencyListLink(index)
            return link and tonumber(link:match("currency:(%d+)"))
        end
    end

    local function GetFallbackIcon(info)
        if info.iconFileID then return info.iconFileID end
        if info.itemID and getItemInfoInstant then
            local icon = select(5, getItemInfoInstant(info.itemID))
            if icon then return icon end
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    local function GetCurrencyListInfoByID(currencyID)
        if not (GetCurrencyListSize and GetCurrencyListInfo) then return end
        for i = 1, GetCurrencyListSize() do
            local name, isHeader, _, _, _, count, field7, field8, field9 = GetCurrencyListInfo(i)
            local icon = field9 ~= nil and field8 or field7
            local itemID = field9 ~= nil and field9 or field8
            if not isHeader then
                local id = GetCurrencyLinkID(i)
                local fallback = fallbackCurrency[currencyID]
                if id == currencyID or itemID == currencyID or (fallback and fallback.itemID == itemID) then
                    return {
                        name = name,
                        iconFileID = icon or (itemID and getItemInfoInstant and select(5, getItemInfoInstant(itemID))),
                        quantity = count or 0,
                        maxQuantity = 0,
                        maxWeeklyQuantity = 0,
                        quantityEarnedThisWeek = 0,
                    }
                end
            end
        end
    end

    function C_CurrencyInfo.GetCurrencyInfo(currencyID)
        currencyID = tonumber(currencyID)
        if not currencyID then return end

        if nativeGetCurrencyInfo then
            local ok, info = pcall(nativeGetCurrencyInfo, currencyID)
            if ok and type(info) == "table"
                and info.name and info.name ~= ""
                and info.iconFileID and info.iconFileID ~= 0 then
                return info
            end
        end

        local info = GetCurrencyListInfoByID(currencyID)
        if info then return info end

        local fallback = fallbackCurrency[currencyID]
        if fallback then
            local quantity = 0
            if currencyID == 1900 and GetArenaCurrency then
                quantity = GetArenaCurrency() or 0
            elseif currencyID == 1901 and GetHonorCurrency then
                quantity = GetHonorCurrency() or 0
            end
            return {
                name = fallback.name,
                iconFileID = GetFallbackIcon(fallback),
                quantity = quantity,
                maxQuantity = 0,
                maxWeeklyQuantity = 0,
                quantityEarnedThisWeek = 0,
            }
        end

        return {
            name = "Currency " .. currencyID,
            iconFileID = "Interface\\Icons\\INV_Misc_QuestionMark",
            quantity = 0,
            maxQuantity = 0,
            maxWeeklyQuantity = 0,
            quantityEarnedThisWeek = 0,
        }
    end
end

-- 10. C_QuestLog.IsQuestFlaggedCompleted — not available in WotLK 3.3.5.
if not C_QuestLog then C_QuestLog = {} end
if not C_QuestLog.IsQuestFlaggedCompleted then
    C_QuestLog.IsQuestFlaggedCompleted = function() return false end
end

-- 11. WARDROBE_SETS — used in tooltip scanning; stub so gsub doesn't crash
if not WARDROBE_SETS then
    WARDROBE_SETS = "__WARDROBE_NA__"
end

-- 6. C_DateAndTime / C_Calendar — stub for BG.AddHolidayLoot
--    Return 0 events so the holiday loot loop simply never executes.
if not C_DateAndTime then
    C_DateAndTime = {}
    function C_DateAndTime.GetCurrentCalendarTime()
        local t = date("*t")
        return { monthDay = t.day, month = t.month, year = t.year,
                 hour = t.hour, minute = t.min }
    end
end
if not C_Calendar then
    C_Calendar = {}
    function C_Calendar.GetNumDayEvents(offset, day) return 0 end
    function C_Calendar.GetDayEvent(offset, day, i)  return nil end
end

-- 7. SettingsPanel proxy — modern replacement for InterfaceOptionsFrame
--    Must be a real Frame so HideUIPanel(SettingsPanel) works.
if not SettingsPanel then
    SettingsPanel = InterfaceOptionsFrame
    if not SettingsPanel.Container then
        -- Prefer InterfaceOptionsFramePanelContainer — it's exactly the content pane WotLK
        -- uses for registered category frames, so scroll frames anchored to it stay within
        -- InterfaceOptionsFrame's bounds and never bleed outside the panel.
        local c = InterfaceOptionsFramePanelContainer
        if not c then
            -- Fallback: build a synthetic container scoped within IOF
            c = CreateFrame("Frame", "BiaoGe_SettingsContainer", InterfaceOptionsFrame)
            c:SetPoint("TOPLEFT",     InterfaceOptionsFrame, "TOPLEFT",     195, -25)
            c:SetPoint("BOTTOMRIGHT", InterfaceOptionsFrame, "BOTTOMRIGHT", -8,   32)
        end
        -- Stub Retail-only nested API (SettingsList.ScrollBox.*) that is guarded by
        -- SettingsPanel:GetAllCategories() returning {} so the code path is never reached.
        c.SettingsList = c.SettingsList or {
            ScrollBox = {
                ScrollToEnd  = function() end,
                ScrollTarget = { GetChildren = function() return end },
            }
        }
        SettingsPanel.Container = c
    end
    if not SettingsPanel.GetAllCategories then
        function SettingsPanel.GetAllCategories() return {} end
    end
    if not SettingsPanel.SelectCategory then
        function SettingsPanel.SelectCategory() end
    end
end

-- 7b. Input/SearchBox template helpers.
-- !!!ClassicAPI's UIPanelTemplates.lua provides the base SearchBox functions,
-- but BiaoGe's local XML template also references Retail helpers that are not
-- present in this 3.3.5 runtime.
do
    local function getColorRGB(color, fallbackR, fallbackG, fallbackB)
        if color then
            if color.GetRGB then
                local r, g, b = color:GetRGB()
                return r or fallbackR, g or fallbackG, b or fallbackB
            end
            if color.r or color.g or color.b then
                return color.r or fallbackR, color.g or fallbackG, color.b or fallbackB
            end
        end
        return fallbackR, fallbackG, fallbackB
    end

    local function setInstructionsShown(editBox)
        local instructions = editBox and editBox.Instructions
        if instructions and instructions.SetShown then
            local text = editBox:GetText() or ""
            instructions:SetShown(text == "")
        end
    end

    if not InputBoxInstructions_OnTextChanged then
        function InputBoxInstructions_OnTextChanged(self)
            setInstructionsShown(self)
        end
    end

    if not InputBoxInstructions_OnDisable then
        function InputBoxInstructions_OnDisable(self)
            local instructions = self and self.Instructions
            if instructions then
                local r, g, b = getColorRGB(self.disabledColor or GRAY_FONT_COLOR, 0.35, 0.35, 0.35)
                instructions:SetTextColor(r, g, b)
                setInstructionsShown(self)
            end
        end
    end

    if not InputBoxInstructions_OnEnable then
        function InputBoxInstructions_OnEnable(self)
            local instructions = self and self.Instructions
            if instructions then
                local r, g, b = getColorRGB(self.enabledColor or HIGHLIGHT_FONT_COLOR, 1, 1, 1)
                instructions:SetTextColor(r, g, b)
                setInstructionsShown(self)
            end
        end
    end

    if not SearchBoxTemplate_OnEditFocusGained then
        if SerachBoxTemplate_OnEditFocusGained then
            SearchBoxTemplate_OnEditFocusGained = SerachBoxTemplate_OnEditFocusGained
        else
            function SearchBoxTemplate_OnEditFocusGained(self)
                self:HighlightText()
                self:SetFontObject("ChatFontSmall")
                if self.searchIcon then
                    self.searchIcon:SetVertexColor(1, 1, 1)
                end
                if self:GetText() == SEARCH then
                    self:SetText("")
                end
                if self.clearButton then
                    self.clearButton:Show()
                end
            end
        end
    end

    if not SearchBoxTemplateClearButton_OnClick then
        function SearchBoxTemplateClearButton_OnClick(self)
            PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
            local editBox = self:GetParent()
            if editBox.clearFunc then
                editBox.clearFunc(editBox)
            end
            editBox:SetText("")
            local onFocusLost = editBox:GetScript("OnEditFocusLost")
            if not editBox:HasFocus() and onFocusLost then
                onFocusLost(editBox)
            end
            editBox:ClearFocus()
        end
    end

    if not SearchBoxTemplate_OnTextChanged then
        function SearchBoxTemplate_OnTextChanged(self)
            setInstructionsShown(self)
            local clearButton = self and self.clearButton
            if clearButton then
                local text = self:GetText() or ""
                clearButton:SetShown(text ~= "" and text ~= SEARCH)
            end
        end
    end
end

-- 12. GetNumClasses — not exposed on all private WotLK servers
if not GetNumClasses then
    function GetNumClasses()
        local n = 0
        for _ in pairs(RAID_CLASS_COLORS or {}) do n = n + 1 end
        return n > 0 and n or 10  -- WotLK has 10 classes
    end
end

-- 13. GetClassInfo — some private WotLK servers return a table or wrong types.
--     Normalize to always return (localizedName:string, classFile:string, classID:number).
do
    local _orig = GetClassInfo
    local _cache
    local function buildCache()
        _cache = {}
        local files = {}
        for f in pairs(RAID_CLASS_COLORS or {}) do files[#files+1] = f end
        table.sort(files)
        for i, file in ipairs(files) do
            local name = (LOCALIZED_CLASS_NAMES_MALE or {})[file] or file
            _cache[i] = { name, file, i }
        end
    end
    function GetClassInfo(classIndex)
        if _orig then
            local a, b, c = _orig(classIndex)
            if type(a) == "string" and a ~= "" then
                return a, (type(b) == "string" and b or a), c
            end
        end
        if not _cache then buildCache() end
        local info = _cache[classIndex]
        if info then return info[1], info[2], info[3] end
    end
end

-- 8. Frame / AnimationGroup methods added after WotLK 3.3.5
--    Patch every Frame sub-type separately; in WotLK each widget type has its
--    own __index table and patching only "Frame" does not cover "Button" etc.
do
    local seenIdx = {}
    local function patchFrameType(wtype)
        local ok, w = pcall(CreateFrame, wtype)
        if not (ok and w) then return end
        local mt  = getmetatable(w)
        local idx = mt and mt.__index
        if type(idx) == "table" and not seenIdx[idx] then
            seenIdx[idx] = true
            if not idx.SetFixedFrameStrata    then idx.SetFixedFrameStrata    = function() end end
            if not idx.SetFixedFrameLevel     then idx.SetFixedFrameLevel     = function() end end
            if not idx.SetHyperlinksEnabled   then idx.SetHyperlinksEnabled   = function() end end
            if not idx.SetObeyStepOnDrag      then idx.SetObeyStepOnDrag      = function() end end
            -- CreateLine: wrap (or install) with 4-arg-capable SetStartPoint/SetEndPoint.
            -- WidgetAPI.lua installs per-instance methods on each line that only handle
            -- the 3-arg form (point, x, y); BiaoGe uses the retail 4-arg form
            -- (point, relativeFrame, x, y) in dozens of places.
            local function wrapLine(line)
                line.SetStartPoint = function(self, point, relOrX, xOff, yOff)
                    if type(relOrX) == "number" then
                        self:SetPoint(point, self:GetParent(), point, relOrX, xOff or 0)
                    else
                        self:SetPoint(point, relOrX, point, xOff or 0, yOff or 0)
                    end
                end
                line.SetEndPoint = function(self, point, relOrX, xOff, yOff)
                    if type(relOrX) == "number" then
                        self:SetPoint(point, self:GetParent(), point, relOrX, xOff or 0)
                    else
                        self:SetPoint(point, relOrX, point, xOff or 0, yOff or 0)
                    end
                end
                return line
            end
            if idx.CreateLine then
                local origCL = idx.CreateLine
                idx.CreateLine = function(self, ...)
                    return wrapLine(origCL(self, ...))
                end
            else
                idx.CreateLine = function(self, ...)
                    local line = self:CreateTexture(...)
                    line.IsLine = true
                    return wrapLine(line)
                end
            end
            -- SetScript wrapping for hyperlink events is intentionally absent here.
            -- Replacing idx.SetScript (shared by ALL frames of this type, including
            -- Clique's secure frames) from insecure addon code taints SetScript
            -- globally, causing "Cannot declare closure factories from insecure code"
            -- and breaking action-bar keybinds.  Use BG.SafeHyperlinkScript() at each
            -- individual call site instead — pcall there is scoped to the specific
            -- frame and never touches the global metatable.
        end
        -- AnimationGroup on each widget type shares the same metatable; patch once
        local ok2, ag = pcall(function() return w:CreateAnimationGroup() end)
        if ok2 and ag then
            local agMT  = getmetatable(ag)
            local agIdx = agMT and agMT.__index
            if type(agIdx) == "table" and not seenIdx[agIdx] then
                seenIdx[agIdx] = true
                if not agIdx.SetToFinalAlpha then agIdx.SetToFinalAlpha = function() end end
            end
        end
        w:Hide()
    end
    for _, wtype in ipairs({"Frame","Button","CheckButton","Slider","EditBox","ScrollFrame","SimpleHTML"}) do
        pcall(patchFrameType, wtype)
    end
end

-- 8c. FontString / Animation methods missing in WotLK 3.3.5
do
    local ok, tmpFrame = pcall(CreateFrame, "Frame")
    if ok and tmpFrame then
        -- FontString: GetWrappedWidth → GetStringWidth
        local tmpFS = tmpFrame:CreateFontString()
        local mt = getmetatable(tmpFS)
        local idx = mt and mt.__index
        if idx then
            if not idx.GetWrappedWidth then idx.GetWrappedWidth = idx.GetStringWidth end
            if not idx.SetRotation     then idx.SetRotation     = function() end end
        end
        -- Animation: SetChildKey (used for keyed animation groups; no-op)
        local ok2, ag = pcall(function() return tmpFrame:CreateAnimationGroup() end)
        if ok2 and ag then
            local anim = ag:CreateAnimation("Alpha")
            local ami = getmetatable(anim)
            local aidx = ami and ami.__index
            if aidx and not aidx.SetChildKey then
                aidx.SetChildKey = function() end
            end
        end
        tmpFrame:Hide()
    end
end

-- 8d. EditBox methods missing in WotLK 3.3.5
--     IsEditable() may not exist on private servers, so track enabled state via
--     a custom _bgEnabled field set by our Enable/Disable/SetEnabled polyfills.
do
    local ok, tmpEdit = pcall(CreateFrame, "EditBox", nil, UIParent)
    if ok and tmpEdit then
        local m = getmetatable(tmpEdit)
        local idx = m and m.__index
        if idx then
            local origSetEnabled = idx.SetEnabled
            idx.SetEnabled = function(self, enabled)
                local state = enabled and true or false
                if self._bgEnabled == state then return end
                if state and self._bgEnabled == nil then
                    self._bgEnabled = true
                    return
                end
                self._bgEnabled = state
                if origSetEnabled then
                    origSetEnabled(self, state)
                elseif type(self.SetEditable) == "function" then
                    self:SetEditable(state)
                end
            end

            local origEnable = idx.Enable
            idx.Enable = function(self)
                if self._bgEnabled == true then return end
                if self._bgEnabled == nil then
                    self._bgEnabled = true
                    return
                end
                self._bgEnabled = true
                if origSetEnabled then
                    origSetEnabled(self, true)
                elseif origEnable then
                    origEnable(self)
                elseif type(self.SetEditable) == "function" then
                    self:SetEditable(true)
                end
            end

            local origDisable = idx.Disable
            idx.Disable = function(self)
                if self._bgEnabled == false then return end
                self._bgEnabled = false
                if origSetEnabled then
                    origSetEnabled(self, false)
                elseif origDisable then
                    origDisable(self)
                elseif type(self.SetEditable) == "function" then
                    self:SetEditable(false)
                end
            end

            if not idx.IsEnabled then
                idx.IsEnabled = function(self)
                    if self._bgEnabled ~= nil then return self._bgEnabled end
                    -- fallback: try IsEditable if available
                    if type(self.IsEditable) == "function" then return self:IsEditable() end
                    return true
                end
            end
            -- ClearHighlightText: select nothing (no-arg HighlightText selects all)
            if not idx.ClearHighlightText then
                idx.ClearHighlightText = function(self)
                    self:HighlightText(0, 0)
                end
            end
        end
        tmpEdit:Hide()
    end
end

-- 8e. PlayerModel methods missing in WotLK 3.3.5
--     SetPitch / SetRoll were added after WotLK; used in FBUI\Model.lua.
do
    local ok, tmpModel = pcall(CreateFrame, "PlayerModel", nil, UIParent)
    if ok and tmpModel then
        local mt = getmetatable(tmpModel)
        local idx = mt and mt.__index
        if idx then
            if not idx.SetPitch then idx.SetPitch = function() end end
            if not idx.SetRoll  then idx.SetRoll  = function() end end
        end
        tmpModel:Hide()
    end
end

-- 8f. DressUpModel methods missing in WotLK 3.3.5 (Retail-only DressUpModel API)
-- MODELFRAME_DEFAULT_ROTATION is defined in retail FrameXML/ModelFrame.lua;
-- absent in WotLK 3.3.5 → SetRotation(nil) → "Usage: SetRotation(radians)" crash.
if not MODELFRAME_DEFAULT_ROTATION then
    MODELFRAME_DEFAULT_ROTATION = -math.pi / 6
end
do
    local ok, tmpModel = pcall(CreateFrame, "DressUpModel", nil, UIParent)
    if ok and tmpModel then
        local mt  = getmetatable(tmpModel)
        local idx = mt and mt.__index
        if idx then
            -- Transmog API (retail-only)
            if not idx.SetUseTransmogSkin       then idx.SetUseTransmogSkin       = function() end end
            if not idx.SetUseTransmogChoices     then idx.SetUseTransmogChoices     = function() end end
            if not idx.SetObeyHideInTransmogFlag then idx.SetObeyHideInTransmogFlag = function() end end
            if not idx.SetDoBlend                then idx.SetDoBlend                = function() end end
            -- Camera scale (retail-only). No-op is safe: BG.DressUp (ItemLib.lua:1742/1745)
            -- already controls zoom via SetPortraitZoom, scale multiplier is purely cosmetic.
            if not idx.SetCamDistanceScale       then idx.SetCamDistanceScale       = function() end end
        end
        tmpModel:Hide()
    end
end

-- 8g. FlashClientIcon — retail global (FrameXML/GlueXML) that flashes the WoW taskbar
-- icon on Windows when the game is backgrounded. Absent in WotLK 3.3.5 → Trade.lua:2892
-- crashes 5× per trade open when BiaoGe.options.tradeFlashClientIcon == 1.
-- No-op is safe: purely cosmetic OS-level alert.
if not FlashClientIcon then
    FlashClientIcon = function() end
end

-- 8h. SetItemRef + ItemRefTooltip:SetHyperlink — WotLK 3.3.5 native doesn't
-- recognize the 'garrmission:' link scheme (Garrison Missions, WoD+).
-- BiaoGe uses it as a custom click target across 7+ modules (DuiZhang,
-- AuctionLog, ItemOutTime, Loot, YY, Receive, ClearBiaoGe, QuickAccounting).
-- Primary fix: wrap SetItemRef to skip garrmission: before native processing.
-- Native SetItemRef crashes at ItemRef.lua:190 (arithmetic on nil startLink)
-- for unrecognised link types, even when SetHyperlink is guarded. Wrapping
-- SetItemRef in Compat.lua (before module load) means BiaoGe's own
-- hooksecurefunc("SetItemRef", ...) handlers still fire after this wrapper
-- returns — click actions (open DuiZhang panel etc.) are preserved.
-- Defense-in-depth: also guard SetHyperlink for addons that call it directly
-- (LibExtraTip, Aux-addon bypass SetItemRef entirely).
do
    local origSetItemRef = SetItemRef
    if origSetItemRef then
        SetItemRef = function(link, text, button, chatFrame)
            if type(link) == "string" and link:sub(1, 12) == "garrmission:" then
                return
            end
            return origSetItemRef(link, text, button, chatFrame)
        end
    end
    local origSetHyperlink = ItemRefTooltip and ItemRefTooltip.SetHyperlink
    if origSetHyperlink then
        ItemRefTooltip.SetHyperlink = function(self, link, ...)
            if type(link) == "string" and link:sub(1, 12) == "garrmission:" then
                return
            end
            return origSetHyperlink(self, link, ...)
        end
    end
end

-- 14. GetAverageItemLevel — added in MoP; not in WotLK 3.3.5
--     Returns (averageItemLevel, averageItemLevelEquipped)
if not GetAverageItemLevel then
    function GetAverageItemLevel()
        return 0, 0
    end
end

-- 15. SPEC_FRAME_PRIMARY_STAT_AGILITY — Retail stat UI global; not in WotLK
--     ITEM_MOD_AGILITY_SHORT is the WotLK localized equivalent.
if not SPEC_FRAME_PRIMARY_STAT_AGILITY then
    SPEC_FRAME_PRIMARY_STAT_AGILITY = ITEM_MOD_AGILITY_SHORT or "Agility"
end

-- 8b. Texture metatable patches (must run after ClassicAPI loaded SetColorTexture etc.)
do
    local ok, tmpFrame = pcall(CreateFrame, "Frame")
    if ok and tmpFrame then
        local tmpTex = tmpFrame:CreateTexture()
        local mt  = getmetatable(tmpTex)
        local idx = mt and mt.__index
        if idx then
            -- 8a. SetGradient: handle new API (CreateColor objects) on old engine
            --     Old: SetGradient(orient, r1,g1,b1, r2,g2,b2)
            --     New: SetGradient(orient, colorObj1, colorObj2)
            local origSetGradient = idx.SetGradient
            if origSetGradient then
                idx.SetGradient = function(self, orient, c1, c2, r2, g2, b2)
                    if type(c1) == "table" and c1.r ~= nil then
                        origSetGradient(self, orient,
                            c1.r, c1.g, c1.b,
                            c2.r or 0, c2.g or 0, c2.b or 0)
                    else
                        origSetGradient(self, orient, c1, c2, r2, g2, b2)
                    end
                end
            end

            -- 8b. SetStartPoint / SetEndPoint — ClassicAPI makes these no-ops;
            --     override with real anchor logic. Support both signatures:
            --     3-arg: (point, x, y)           — relative to parent
            --     4-arg: (point, frame, x, y)    — relative to explicit frame
            idx.SetStartPoint = function(self, point, relOrX, xOff, yOff)
                if type(relOrX) == "number" then
                    self:SetPoint(point, self:GetParent(), point, relOrX, xOff or 0)
                else
                    self:SetPoint(point, relOrX, point, xOff or 0, yOff or 0)
                end
            end
            idx.SetEndPoint = function(self, point, relOrX, xOff, yOff)
                if type(relOrX) == "number" then
                    self:SetPoint(point, self:GetParent(), point, relOrX, xOff or 0)
                else
                    self:SetPoint(point, relOrX, point, xOff or 0, yOff or 0)
                end
            end
            -- 8c. SetThickness — override ClassicAPI no-op
            idx.SetThickness = function(self, h)
                self:SetHeight(h or 1)
            end
            -- 8d. SetAtlas — ClassicAPI throws on missing atlas names (retail atlases
            --     don't exist in WotLK). Wrap to silently make texture invisible instead.
            local origSetTexture = idx.SetTexture
            local origSetVertexColor = idx.SetVertexColor
            local origSetAlpha = idx.SetAlpha
            local origSetTexCoord = idx.SetTexCoord
            local origSetHorizTile = idx.SetHorizTile
            local origSetVertTile = idx.SetVertTile
            if origSetTexture then
                idx.SetColorTexture = function(self, r, g, b, a)
                    origSetTexture(self, "Interface\\Buttons\\WHITE8x8")
                    if origSetTexCoord then
                        origSetTexCoord(self, 0, 1, 0, 1)
                    end
                    if origSetHorizTile then
                        origSetHorizTile(self, false)
                    end
                    if origSetVertTile then
                        origSetVertTile(self, false)
                    end
                    if origSetVertexColor then
                        origSetVertexColor(self, r or 1, g or 1, b or 1)
                    end
                    if origSetAlpha then
                        origSetAlpha(self, a == nil and 1 or a)
                    end
                end
            end
            local origSetAtlas = idx.SetAtlas
            if origSetAtlas then
                idx.SetAtlas = function(self, atlasName, ...)
                    local ok = pcall(origSetAtlas, self, atlasName, ...)
                    if not ok then
                        self:SetTexture(nil)
                    end
                end
            end
        end
        tmpFrame:Hide()
    end
end

-- 8f. Register retail atlas names that BiaoGe uses but don't exist in WotLK 3.3.5.
--     C_Texture.RegisterAtlas maps them to real WotLK texture paths so SetAtlas()
--     shows something instead of leaving the texture blank.
--
--     Pattern for future ports: identify every SetAtlas("retail-name") call,
--     find the equivalent WotLK texture path, register here.
do
    -- LFG role indicator icons — WorldBossCD.lua:256-260
    -- Sprite sheet: Interface\LFGFrame\UI-LFG-ICON-ROLES (64x64)
    -- Top row (y 0-19): small round role indicators (Tank, Healer, DPS)
    -- Write directly to both stores: ClassicAPI <=1.19 SetAtlas reads
    -- ATLAS_INFO_STORAGE, while ClassicAPI 1.23 reads C_Texture.AtlasData.
    local function RegisterBiaoGeAtlas(name, info)
        ATLAS_INFO_STORAGE[name] = info
        if C_Texture and C_Texture.AtlasData then
            C_Texture.AtlasData[name] = info
        end
    end

    ATLAS_INFO_STORAGE = ATLAS_INFO_STORAGE or {}
    RegisterBiaoGeAtlas("ui-lfg-roleicon-tank",   { 19, 19, 0/64, 19/64, 0/64, 19/64, false, false, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES" })
    RegisterBiaoGeAtlas("ui-lfg-roleicon-healer", { 19, 19, 20/64, 39/64, 0/64, 19/64, false, false, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES" })
    RegisterBiaoGeAtlas("ui-lfg-roleicon-dps",    { 19, 19, 40/64, 59/64, 0/64, 19/64, false, false, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES" })
end

-- 8e. BackdropTemplate NineSlice UV fix for WotLK 3.3.5.
--     BackdropTemplateMixin:SetupTextureCoordinates() computes edge repeat
--     values up to ~200 for edgeSize=1 borders (BiaoGe's most common case).
--     On WotLK those extreme UV values + tiling = oversized texture overlays
--     that bleed far outside the frame ("shadow" artifacts).
--     Fix: override SetupTextureCoordinates to use WotLK-safe UV math and
--     swap ChatFrameBackground border pieces to WHITE8x8 (vertex-tinted solid).
--     Also tightens SetBackdropColor and SetBackdropBorderColor so tinting
--     works correctly with the normalised pieces.
do
    local mixin = BackdropTemplateMixin
    if mixin and not mixin.BiaoGeUVFix then
        mixin.BiaoGeUVFix = true

        local WHITE = "Interface\\Buttons\\WHITE8x8"

        local function IsSolid(file)
            return file == "Interface/ChatFrame/ChatFrameBackground"
                or file == "Interface\\ChatFrame\\ChatFrameBackground"
                or file == "Interface/Buttons/WHITE8x8"
                or file == "Interface\\Buttons\\WHITE8x8"
        end

        -- Reset a single NineSlice piece to a safe, bounded, solid white quad.
        -- Vertex colour is applied later by SetBackdropColor / SetBackdropBorderColor.
        local function NormalizePiece(p)
            if not p then return end
            p:SetTexture(WHITE)
            if p.SetTexCoord  then p:SetTexCoord(0, 1, 0, 1) end
            if p.SetHorizTile then p:SetHorizTile(false) end
            if p.SetVertTile  then p:SetVertTile(false)  end
        end

        local coordStart = 0.0625
        local coordEnd = 1 - coordStart
        local textureUVs = {
            TopLeftCorner     = { 0.5078125, coordStart, 0.5078125, coordEnd, 0.6171875, coordStart, 0.6171875, coordEnd },
            TopRightCorner    = { 0.6328125, coordStart, 0.6328125, coordEnd, 0.7421875, coordStart, 0.7421875, coordEnd },
            BottomLeftCorner  = { 0.7578125, coordStart, 0.7578125, coordEnd, 0.8671875, coordStart, 0.8671875, coordEnd },
            BottomRightCorner = { 0.8828125, coordStart, 0.8828125, coordEnd, 0.9921875, coordStart, 0.9921875, coordEnd },
            TopEdge           = { 0.2578125, coordEnd, 0.3671875, coordEnd, 0.2578125, coordStart, 0.3671875, coordStart },
            BottomEdge        = { 0.3828125, coordEnd, 0.4921875, coordEnd, 0.3828125, coordStart, 0.4921875, coordStart },
            LeftEdge          = { 0.0078125, coordStart, 0.0078125, coordEnd, 0.1171875, coordStart, 0.1171875, coordEnd },
            RightEdge         = { 0.1328125, coordStart, 0.1328125, coordEnd, 0.2421875, coordStart, 0.2421875, coordEnd },
        }

        local function ClampBorderPiece(p, pieceName)
            if not p then return end
            if p.SetHorizTile then p:SetHorizTile(false) end
            if p.SetVertTile  then p:SetVertTile(false)  end
            local uv = textureUVs[pieceName]
            if uv and p.SetTexCoord then
                p:SetTexCoord(uv[1], uv[2], uv[3], uv[4], uv[5], uv[6], uv[7], uv[8])
            end
        end

        -- Replace the Retail-atlas UV math with WotLK-safe coordinates.
        function mixin:SetupTextureCoordinates()
            if not self.backdropInfo then return end

            local solidEdge = IsSolid(self.backdropInfo.edgeFile)
            local solidBg   = IsSolid(self.backdropInfo.bgFile)

            -- ---- border pieces ----
            if solidEdge then
                -- Solid-colour border (ChatFrameBackground used as thin line):
                -- replace every border piece with a bounded WHITE8x8 quad.
                NormalizePiece(self.TopLeftCorner)
                NormalizePiece(self.TopRightCorner)
                NormalizePiece(self.BottomLeftCorner)
                NormalizePiece(self.BottomRightCorner)
                NormalizePiece(self.TopEdge)
                NormalizePiece(self.BottomEdge)
                NormalizePiece(self.LeftEdge)
                NormalizePiece(self.RightEdge)
            else
                -- Non-solid border textures use the same atlas sub-regions as
                -- ClassicAPI, but without high repeat UVs. WotLK 3.3.5 renders
                -- those repeat UVs as the clipped texture fragments seen on
                -- edit boxes and panels.
                ClampBorderPiece(self.TopLeftCorner, "TopLeftCorner")
                ClampBorderPiece(self.TopRightCorner, "TopRightCorner")
                ClampBorderPiece(self.BottomLeftCorner, "BottomLeftCorner")
                ClampBorderPiece(self.BottomRightCorner, "BottomRightCorner")
                ClampBorderPiece(self.TopEdge, "TopEdge")
                ClampBorderPiece(self.BottomEdge, "BottomEdge")
                ClampBorderPiece(self.LeftEdge, "LeftEdge")
                ClampBorderPiece(self.RightEdge, "RightEdge")
            end

            -- ---- center piece ----
            local c = self.Center
            if c then
                if solidBg then
                    NormalizePiece(c)
                else
                    local w  = self:GetWidth()
                    local h  = self:GetHeight()
                    local es = self:GetEdgeSize()
                    local sc = self:GetEffectiveScale()
                    local rx, ry = 1, 1
                    if self.backdropInfo.tile then
                        local div = self.backdropInfo.tileSize
                        if not div or div == 0 then div = es end
                        if div and div ~= 0 then
                            rx = (w / div) * sc
                            ry = (h / div) * sc
                        end
                    end
                    if c.SetTexCoord then c:SetTexCoord(0, rx, 0, ry) end
                end
            end
        end

        -- SetBackdropColor: vertex-tint center (WHITE8x8 or real texture).
        local oldSetBackdropColor = mixin.SetBackdropColor
        function mixin:SetBackdropColor(r, g, b, a)
            if not self.backdropInfo then return end
            local c = self.Center
            if c then
                c:SetVertexColor(r or 1, g or 1, b or 1)
                if c.SetAlpha then
                    c:SetAlpha(a == nil and 1 or a)
                elseif oldSetBackdropColor then
                    oldSetBackdropColor(self, r, g, b, a)
                end
            end
        end

        -- SetBackdropBorderColor: vertex-tint all border pieces.
        local oldSetBackdropBorderColor = mixin.SetBackdropBorderColor
        function mixin:SetBackdropBorderColor(r, g, b, a)
            if oldSetBackdropBorderColor then
                oldSetBackdropBorderColor(self, r, g, b, a)
            end
            if not self.backdropInfo then return end
            for _, region in ipairs({
                self.TopLeftCorner,  self.TopRightCorner,
                self.BottomLeftCorner, self.BottomRightCorner,
                self.TopEdge, self.BottomEdge,
                self.LeftEdge, self.RightEdge,
            }) do
                if region then
                    region:SetVertexColor(r or 1, g or 1, b or 1)
                    if region.SetAlpha then
                        region:SetAlpha(a == nil and 1 or a)
                    end
                end
            end
        end
    end
end

-- 9. (removed) UIPanelScrollFrameTemplate_OnLoad patch removed — WoW 3.3.5 compiles
--    <OnLoad function="..."> references at template parse time, so replacing the Lua
--    global has no effect and taints the environment. Each anonymous scroll frame site
--    is fixed individually by giving it a unique name.

-- 17. IsMasterLooter — not in WotLK 3.3.5; used in BG.ImML() (BiaoGe.lua:2266)
-- 16. Retail-shaped item info on WotLK. 3.3.5 GetItemInfo stops at sellPrice,
--     while BiaoGe expects classID/subclassID in returns 12/13.
do
    local _GetItemInfo = GetItemInfo
    local _GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
    local _GetItemSubClassInfo = GetItemSubClassInfo or (C_Item and C_Item.GetItemSubClassInfo)

    local weaponEquipLoc = {
        INVTYPE_WEAPON = true,
        INVTYPE_2HWEAPON = true,
        INVTYPE_WEAPONMAINHAND = true,
        INVTYPE_WEAPONOFFHAND = true,
        INVTYPE_RANGED = true,
        INVTYPE_RANGEDRIGHT = true,
        INVTYPE_THROWN = true,
    }

    local function ExtractItemID(item)
        if type(item) == "number" then
            return item
        elseif type(item) == "string" then
            local itemID = tonumber(item:match("item:(%d+)")) or tonumber(item)
            if itemID then return itemID end
            if item:find(":") then return end
            if _GetItemInfo then
                local _, link = _GetItemInfo(item)
                return link and tonumber(link:match("item:(%d+)"))
            end
        end
    end

    local function FindSubClassID(classID, itemSubType)
        if not (classID and itemSubType and _GetItemSubClassInfo) then return end
        for subClassID = 0, 30 do
            local subClassName = _GetItemSubClassInfo(classID, subClassID)
            if subClassName == itemSubType then
                return subClassID
            end
        end
    end

    local function DeriveClassIDs(itemType, itemSubType, equipLoc)
        local classID
        if weaponEquipLoc[equipLoc] then
            classID = 2
        elseif equipLoc and equipLoc ~= "" then
            classID = 4
        elseif itemType == _G.WEAPON then
            classID = 2
        elseif itemType == _G.ARMOR then
            classID = 4
        end
        return classID, FindSubClassID(classID, itemSubType)
    end

    if _GetItemInfo then
        -- TAINT FIX (spec 004): expose the retail-shaped wrapper as ns.GetItemInfo
        -- instead of overwriting the global. Overwriting the global GetItemInfo from
        -- insecure addon code taints it; the secure macro parser
        -- (ChatFrame.lua CreateCanonicalActions) reads GetItemInfo while resolving
        -- /cast, /use, /castsequence → tainted execution → "blocked from an action
        -- only available to the Blizzard UI" (all action-bar macros dead).
        -- Callers needing classID/subClassID alias `local GetItemInfo = ns.GetItemInfo`.
        ns.GetItemInfo = function(item)
            local name, link, quality, level, minLevel, itemType, itemSubType,
                stackCount, equipLoc, texture, sellPrice, classID, subClassID,
                bindType, expacID, setID, isCraftingReagent = _GetItemInfo(item)

            if not classID then
                classID, subClassID = DeriveClassIDs(itemType, itemSubType, equipLoc)
            end

            return name, link, quality, level, minLevel, itemType, itemSubType,
                stackCount, equipLoc, texture, sellPrice, classID, subClassID,
                bindType, expacID, setID, isCraftingReagent
        end
        if C_Item then
            C_Item.GetItemInfo = ns.GetItemInfo
        end
    end

    if _GetItemInfoInstant then
        -- TAINT FIX (spec 004): same rationale as GetItemInfo above — keep the global
        -- native/ClassicAPI; expose the classID/subClassID-augmented form as ns.*.
        ns.GetItemInfoInstant = function(item)
            local itemID = ExtractItemID(item)
            if not itemID then return end

            local _itemID, itemType, itemSubType, equipLoc, texture, classID, subClassID =
                _GetItemInfoInstant(item)
            if not classID then
                classID, subClassID = DeriveClassIDs(itemType, itemSubType, equipLoc)
            end

            return tonumber(_itemID) or itemID, itemType, itemSubType, equipLoc,
                texture, classID, subClassID
        end
        if C_Item then
            C_Item.GetItemInfoInstant = ns.GetItemInfoInstant
        end
    end
end

if not IsMasterLooter then
    function IsMasterLooter()
        return false
    end
end

-- 18. C_TradeSkillUI — retail-only namespace; WotLK 3.3.5 does not have it.
--     GetTradeSkillDisplayName(skillLineID) is used in RoleOverview.lua:916 to
--     populate SKILLall_table column headers. In WotLK the same skill-line IDs
--     happen to map to real spells so GetSpellInfo gives a reasonable name.
if not C_TradeSkillUI then
    C_TradeSkillUI = {
        GetTradeSkillDisplayName = function(id)
            return GetSpellInfo(id) or ""
        end,
        GetAllProfessionTradeSkillLines = function() return {} end,
        OpenTradeSkill  = function() end,
        CloseTradeSkill = function() end,
        IsTradeSkillLinked  = function() return false end,
        IsTradeSkillGuild   = function() return false end,
        IsTradeSkillReady   = function() return false end,
    }
end

-- 19. Tank stat GlobalStrings — some private WotLK 3.3.5 servers omit these.
--     Used in FilterClassItem.lua:959 as concatenated tooltip text.
--     Also guard against literal "?" placeholder values used by some private builds.
if not STAT_CATEGORY_DEFENSE or STAT_CATEGORY_DEFENSE == "?" then STAT_CATEGORY_DEFENSE = DEFENSE_COLON or "防御等级" end
if not STAT_PARRY    or STAT_PARRY    == "?" then STAT_PARRY    = "招架等级" end
if not STAT_DODGE    or STAT_DODGE    == "?" then STAT_DODGE    = "躲闪等级" end
if not STAT_BLOCK    or STAT_BLOCK    == "?" then STAT_BLOCK    = "格挡等级" end

-- 21. Additional WotLK stat globals used in DB_FilterClassItem.lua (BG.IsWLK path).
--     Private server builds may have nil or "?" placeholder values for these.
do
    local function _s(v, fallback) return (not v or v == "?") and fallback or v end
    HIT_LCD                           = _s(HIT_LCD,                           "命中等级")
    STAT_HASTE                        = _s(STAT_HASTE,                        "急速等级")
    STAT_CRITICAL_STRIKE              = _s(STAT_CRITICAL_STRIKE,              "暴击等级")
    STAT_EXPERTISE                    = _s(STAT_EXPERTISE,                    "精准等级")
    MELEE_ATTACK                      = _s(MELEE_ATTACK,                      "近战攻击")
    RANGED_ATTACK                     = _s(RANGED_ATTACK,                     "远程攻击")
    ITEM_MOD_ATTACK_POWER_SHORT       = _s(ITEM_MOD_ATTACK_POWER_SHORT,       "攻击强度")
    ITEM_MOD_BLOCK_RATING_SHORT       = _s(ITEM_MOD_BLOCK_RATING_SHORT,       "格挡等级")
    ITEM_MOD_BLOCK_VALUE_SHORT        = _s(ITEM_MOD_BLOCK_VALUE_SHORT,        "格挡值")
    ITEM_MOD_ARMOR_PENETRATION_RATING = _s(ITEM_MOD_ARMOR_PENETRATION_RATING, "护甲穿透")
    -- ITEM_MOD_MANA_REGENERATION may contain "%d" (format specifier) on WotLK — use
    -- a clean partial string so the button label and tooltip pattern are both readable.
    if not ITEM_MOD_MANA_REGENERATION or ITEM_MOD_MANA_REGENERATION == "?" or
            ITEM_MOD_MANA_REGENERATION:find("%%d") then
        ITEM_MOD_MANA_REGENERATION = "每5秒恢复"
    end
    -- ITEM_MOD_SPELL_DAMAGE/HEALING_DONE: used with :gsub("%%s",".+") in DB_FilterClassItem.
    -- Guard against nil (crashes the gsub call) and "?" placeholder values.
    if not ITEM_MOD_SPELL_DAMAGE_DONE or ITEM_MOD_SPELL_DAMAGE_DONE == "?" then
        ITEM_MOD_SPELL_DAMAGE_DONE = "增加法术伤害和治疗效果"
    end
    if not ITEM_MOD_SPELL_HEALING_DONE or ITEM_MOD_SPELL_HEALING_DONE == "?" then
        ITEM_MOD_SPELL_HEALING_DONE = "增加治疗效果"
    end
end

-- 20. GetRaidDifficultyID / SetRaidDifficultyID — retail-only (added Cataclysm+).
--     WotLK 3.3.5 uses GetRaidDifficulty() returning 1-4. BiaoGe's difficulty
--     dropdown uses retail-style IDs (3=10N, 4=25N, 5=10H, 6=25H). Map between them.
do
    local build = select(4, GetBuildInfo())
    local _wotlkToRetail = { [1] = 3, [2] = 4, [3] = 5, [4] = 6 }
    local _retailToWotlk = { [3] = 1, [4] = 2, [5] = 3, [6] = 4 }

    if build and build >= 30000 and build < 40000 then
        local oldGetRaidDifficultyID = GetRaidDifficultyID
        local oldSetRaidDifficultyID = SetRaidDifficultyID

        function GetRaidDifficultyID()
            local diffID = oldGetRaidDifficultyID and oldGetRaidDifficultyID()
            if diffID and _retailToWotlk[diffID] then
                return diffID
            end
            if diffID and _wotlkToRetail[diffID] then
                return _wotlkToRetail[diffID]
            end

            local d = GetRaidDifficulty and GetRaidDifficulty() or 1
            return _wotlkToRetail[d] or 3
        end

        function SetRaidDifficultyID(diffID)
            local d = _retailToWotlk[diffID] or diffID or 1
            if SetRaidDifficulty then
                SetRaidDifficulty(d)
            elseif oldSetRaidDifficultyID then
                oldSetRaidDifficultyID(diffID)
            end
        end
    else
        if not GetRaidDifficultyID then
            function GetRaidDifficultyID()
                local d = GetRaidDifficulty and GetRaidDifficulty() or 1
                return _wotlkToRetail[d] or 3
            end
        end
        if not SetRaidDifficultyID then
            function SetRaidDifficultyID(diffID)
                local d = _retailToWotlk[diffID] or 1
                if SetRaidDifficulty then SetRaidDifficulty(d) end
            end
        end
    end
end

-- 21. Font color tables — in WotLK these are plain {r,g,b} tables without methods.
--     LibUIDropDownMenu calls :GetRGB() on them (retail ColorMixin pattern).
do
    local colors = {
        NORMAL_FONT_COLOR, GRAY_FONT_COLOR, HIGHLIGHT_FONT_COLOR,
        RED_FONT_COLOR, GREEN_FONT_COLOR, BLUE_FONT_COLOR,
        WHITE_FONT_COLOR, YELLOW_FONT_COLOR, ORANGE_FONT_COLOR,
    }
    for _, c in ipairs(colors) do
        if type(c) == "table" and c.r ~= nil and not c.GetRGB then
            c.GetRGB = function(self) return self.r, self.g, self.b end
        end
    end
end

-- 22. GameTooltip:SetItemByID — retail-only; WotLK uses SetHyperlink.
--     BiaoGeTooltip inherits from GameTooltip metatable, so patch there.
do
    local mt = getmetatable(GameTooltip)
    local idx = mt and mt.__index
    if idx and not idx.SetItemByID then
        idx.SetItemByID = function(self, itemID)
            self:SetHyperlink("item:" .. tostring(itemID))
        end
    end
end

-- 23. UnitIsSameServer — WotLK requires two args; BiaoGe calls it with one.
--     Replace unconditionally so the single-arg form returns true (no cross-realm).
do
    local _orig = UnitIsSameServer
    UnitIsSameServer = function(unit, otherUnit)
        if not otherUnit then return true end
        if _orig then
            local ok, result = pcall(_orig, unit, otherUnit)
            return ok and result or true
        end
        return true
    end
end

-- 24. BG.SafeHyperlinkScript — defined in Core\DB\Init.lua after BG = {} is created.
-- Compat.lua loads before the DB layer, so BG does not exist here yet.

-- 25. GetRealZoneText — WotLK 3.3.5 ignores any argument and returns the player's
--     current zone instead. BiaoGe calls GetRealZoneText(instanceID) to get instance
--     names for the instance-selection buttons; without this polyfill all buttons show
--     "Dalaran" (the current zone). Intercept calls that pass a numeric ID and return
--     the correct instance name from a static table.
do
    local build = select(4, GetBuildInfo())
    if build >= 30000 and build < 40000 then
        local _zoneNames = {
            -- WotLK instances
            [533] = "Naxxramas",
            [603] = "Ulduar",
            [649] = "Trial of the Crusader",
            [631] = "Icecrown Citadel",
            [615] = "The Obsidian Sanctum",
            [616] = "The Eye of Eternity",
            [249] = "Onyxia's Lair",
            [724] = "The Ruby Sanctum",
            -- TBC instances
            [532] = "Karazhan",
            [565] = "Gruul's Lair",
            [544] = "Magtheridon's Lair",
            [548] = "Serpentshrine Cavern",
            [550] = "The Eye",
            [534] = "Mount Hyjal",
            [564] = "Black Temple",
            [580] = "Sunwell Plateau",
            -- Classic instances
            [409] = "Molten Core",
            [469] = "Blackwing Lair",
            [309] = "Zul'Gurub",
            [509] = "Ruins of Ahn'Qiraj",
            [531] = "Temple of Ahn'Qiraj",
        }
        local _GetRealZoneText = GetRealZoneText
        GetRealZoneText = function(mapID)
            if mapID ~= nil then
                return _zoneNames[mapID] or ""
            end
            return _GetRealZoneText()
        end
    end
end
