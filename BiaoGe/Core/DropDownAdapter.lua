-- DropDownAdapter.lua
-- Replaces LibUIDropDownMenu-4.0 with a wrapper around !!!ClassicAPI's C_UIDropDownMenu system.
-- Root cause: LibUIDropDownMenu.lua:512 requires TooltipBackdropTemplateMixin (retail-only).
-- !!!ClassicAPI provides a full, compatible C_UIDropDownMenu_* API instead.

local AddonName, ns = ...

local _counter = 0
local function AutoName(name)
    if name and name ~= "" then return name end
    _counter = _counter + 1
    return "BiaoGeDropDown" .. _counter
end

local Adapter = {}

function Adapter:Create_UIDropDownMenu(name, parent)
    local frameName = AutoName(name)
    local frame = CreateFrame("Frame", frameName, parent, "C_UIDropDownMenuTemplate")
    -- Attach named children as properties for LibUIDropDownMenu-4.0 compatibility.
    -- C_UIDropDownMenuTemplate creates $parentText, $parentLeft, $parentMiddle,
    -- $parentRight, $parentButton as globals but not as frame table properties.
    frame.Text   = _G[frameName .. "Text"]
    frame.Left   = _G[frameName .. "Left"]
    frame.Middle = _G[frameName .. "Middle"]
    frame.Right  = _G[frameName .. "Right"]
    frame.Button = _G[frameName .. "Button"]
    return frame
end

function Adapter:UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList)
    C_UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList)
end

function Adapter:UIDropDownMenu_CreateInfo()
    return C_UIDropDownMenu_CreateInfo()
end

function Adapter:UIDropDownMenu_AddButton(info, level)
    C_UIDropDownMenu_AddButton(info, level)
end

function Adapter:UIDropDownMenu_AddSeparator(level)
    local info = C_UIDropDownMenu_CreateInfo()
    info.disabled = 1
    info.notClickable = 1
    info.notCheckable = 1
    C_UIDropDownMenu_AddButton(info, level)
end

function Adapter:UIDropDownMenu_AddSpace(level)
    local info = C_UIDropDownMenu_CreateInfo()
    info.text = " "
    info.disabled = 1
    info.notClickable = 1
    info.notCheckable = 1
    C_UIDropDownMenu_AddButton(info, level)
end

function Adapter:UIDropDownMenu_SetText(frame, text)
    C_UIDropDownMenu_SetText(frame, text)
end

function Adapter:UIDropDownMenu_GetText(frame)
    return C_UIDropDownMenu_GetText(frame)
end

function Adapter:UIDropDownMenu_SetWidth(frame, width, padding)
    C_UIDropDownMenu_SetWidth(frame, width, padding)
end

function Adapter:UIDropDownMenu_SetButtonWidth(frame, width)
    C_UIDropDownMenu_SetButtonWidth(frame, width)
end

function Adapter:UIDropDownMenu_SetAnchor(dropdown, xOffset, yOffset, point, relativeTo, relativePoint)
    C_UIDropDownMenu_SetAnchor(dropdown, xOffset, yOffset, point, relativeTo, relativePoint)
end

function Adapter:UIDropDownMenu_SetSelectedValue(frame, value, useValue)
    C_UIDropDownMenu_SetSelectedValue(frame, value, useValue)
end

function Adapter:UIDropDownMenu_GetSelectedValue(frame)
    return C_UIDropDownMenu_GetSelectedValue(frame)
end

function Adapter:UIDropDownMenu_SetSelectedName(frame, name, useValue)
    C_UIDropDownMenu_SetSelectedName(frame, name, useValue)
end

function Adapter:UIDropDownMenu_GetSelectedName(frame)
    return C_UIDropDownMenu_GetSelectedName(frame)
end

function Adapter:UIDropDownMenu_SetSelectedID(frame, id, useValue)
    C_UIDropDownMenu_SetSelectedID(frame, id, useValue)
end

function Adapter:UIDropDownMenu_GetSelectedID(frame)
    return C_UIDropDownMenu_GetSelectedID(frame)
end

function Adapter:UIDropDownMenu_Refresh(frame, useValue, dropdownLevel)
    C_UIDropDownMenu_Refresh(frame, useValue, dropdownLevel)
end

function Adapter:UIDropDownMenu_RefreshAll(frame, useValue)
    if C_UIDropDownMenu_Refresh then
        C_UIDropDownMenu_Refresh(frame, useValue, 1)
        C_UIDropDownMenu_Refresh(frame, useValue, 2)
    end
end

function Adapter:UIDropDownMenu_ClearAll(frame)
    C_UIDropDownMenu_ClearAll(frame)
end

function Adapter:UIDropDownMenu_JustifyText(frame, justification)
    C_UIDropDownMenu_JustifyText(frame, justification)
end

function Adapter:UIDropDownMenu_SetDisplayMode(frame, displayMode)
    if displayMode == "MENU" then
        frame.displayMode = "MENU"
    end
end

function Adapter:UIDropDownMenu_EnableDropDown(dropDown)
    C_UIDropDownMenu_EnableDropDown(dropDown)
end

function Adapter:UIDropDownMenu_DisableDropDown(dropDown)
    C_UIDropDownMenu_DisableDropDown(dropDown)
end

function Adapter:UIDropDownMenu_SetDropDownEnabled(dropDown, enabled)
    if enabled then
        C_UIDropDownMenu_EnableDropDown(dropDown)
    else
        C_UIDropDownMenu_DisableDropDown(dropDown)
    end
end

function Adapter:UIDropDownMenu_IsEnabled(dropDown)
    return C_UIDropDownMenu_IsEnabled(dropDown)
end

function Adapter:EasyMenu(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
    -- Bypass C_EasyMenu: it passes EasyMenu_Initialize (WotLK native, calls old
    -- UIDropDownMenu_AddButton) instead of C_EasyMenu_Initialize (uses C_ API).
    -- Route through self:ToggleDropDownMenu so hooks and L_ alias sync fire.
    if displayMode == "MENU" then
        menuFrame.displayMode = displayMode
    end
    C_UIDropDownMenu_Initialize(menuFrame, C_EasyMenu_Initialize, displayMode, nil, menuList)
    self:ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuList)
    -- Apply custom autoHideDelay to the list frame's showTimer.
    -- C_UIDropDownMenu uses a global SHOW_TIME (default 2s); StartCounting reads it
    -- on OnLeave. Override showTimer directly after toggle to honour the caller's delay.
    if autoHideDelay then
        local listFrame = _G["C_DropDownList1"]
        if listFrame and listFrame:IsShown() then
            listFrame.showTimer = autoHideDelay
            listFrame.isCounting = 1
        end
    end
end

function Adapter:CloseDropDownMenus(level)
    C_CloseDropDownMenus(level)
end

function Adapter:ToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button)
    C_ToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button)
end

function Adapter:UIDropDownMenu_StartCounting(frame)
    C_UIDropDownMenu_StartCounting(frame)
end

function Adapter:UIDropDownMenu_StopCounting(frame)
    C_UIDropDownMenu_StopCounting(frame)
end

function Adapter:UIDropDownMenu_SetButtonText(level, id, text, colorCode)
    C_UIDropDownMenu_SetButtonText(level, id, text, colorCode)
end

function Adapter:UIDropDownMenu_DisableButton(level, id)
    C_UIDropDownMenu_DisableButton(level, id)
end

function Adapter:UIDropDownMenu_EnableButton(level, id)
    C_UIDropDownMenu_EnableButton(level, id)
end

function Adapter:UIDropDownMenu_SetButtonNotClickable(level, id)
    local btn = _G["C_DropDownList" .. level .. "Button" .. id]
    if btn then btn:Disable() end
end

function Adapter:UIDropDownMenu_SetButtonClickable(level, id)
    local btn = _G["C_DropDownList" .. level .. "Button" .. id]
    if btn then btn:Enable() end
end

function Adapter:UIDropDownMenu_GetValue(id)
    return C_UIDropDownMenu_GetValue(id)
end

function Adapter:UIDropDownMenu_SetFrameStrata(frame, frameStrata)
    if frame and frame.SetFrameStrata then
        frame:SetFrameStrata(frameStrata)
    end
end

function Adapter:UIDropDownMenu_GetCurrentDropDown()
    return C_UIDropDownMenu_GetCurrentDropDown()
end

function Adapter:UIDropDownMenuButton_GetChecked(self)
    return C_UIDropDownMenuButton_GetChecked(self)
end

function Adapter:UIDropDownMenuButton_GetName(self)
    return C_UIDropDownMenuButton_GetName(self)
end

function Adapter:UIDropDownMenu_SetInitializeFunction(frame, initFunction)
    frame.initialize = initFunction
end

function Adapter:UIDropDownMenu_MatchTextWidth(frame, minWidth, maxWidth)
    local text = _G[frame:GetName() .. "Text"]
    if not text then return end
    local width = text:GetWidth()
    if minWidth then width = math.max(width, minWidth) end
    if maxWidth then width = math.min(width, maxWidth) end
    C_UIDropDownMenu_SetWidth(frame, width)
end

ns.LibBG = Adapter

-- Compatibility aliases: BiaoGe was written against LibUIDropDownMenu-4.0 (L_ prefix).
-- !!!ClassicAPI's C_UIDropDownMenu uses C_ prefix — mirror globals under L_ names
-- so all existing BiaoGe code works without modification.
--
-- NOTE: C_UIDROPDOWNMENU_MAXBUTTONS may differ between !!!ClassicAPI versions;
-- always use "or 8" as a fallback to keep L_UIDROPDOWNMENU_MAXBUTTONS a number.
do
    -- Constant (fallback 8 guards against version mismatches in !!!ClassicAPI)
    L_UIDROPDOWNMENU_MAXBUTTONS = C_UIDROPDOWNMENU_MAXBUTTONS or 8

    -- Frame aliases: same object, two names
    -- C_DropDownList frames exist immediately (created at top of C_UIDropDownMenu.lua).
    _G["L_DropDownList1"] = _G["C_DropDownList1"]
    _G["L_DropDownList2"] = _G["C_DropDownList2"]

    -- Button aliases (C_DropDownList1Button1…N → L_DropDownList1Button1…N)
    -- Only copy non-nil entries so we don't propagate missing frames as nil.
    for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
        if _G["C_DropDownList1Button" .. i] then
            _G["L_DropDownList1Button" .. i] = _G["C_DropDownList1Button" .. i]
        end
        if _G["C_DropDownList2Button" .. i] then
            _G["L_DropDownList2Button" .. i] = _G["C_DropDownList2Button" .. i]
        end
    end

    -- Patch ToggleDropDownMenu to:
    -- (a) set .dropdown on the list frame (LibUIDropDownMenu compatibility)
    -- (b) always re-sync L_ aliases so lazy-created or newly grown button frames
    --     are mirrored; also keeps MAXBUTTONS in sync if !!!ClassicAPI grows it.
    -- Strata order table used to compare WoW frame strata strings numerically.
    local _strataOrder = { BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8 }

    local origToggle = Adapter.ToggleDropDownMenu
    function Adapter:ToggleDropDownMenu(level, value, dropDownFrame, anchorName, ...)
        origToggle(self, level, value, dropDownFrame, anchorName, ...)
        -- Always update MAXBUTTONS (hooksecurefunc callbacks in DB.lua / Options.lua
        -- read L_UIDROPDOWNMENU_MAXBUTTONS and require it to be a valid number).
        local maxBtns = C_UIDROPDOWNMENU_MAXBUTTONS or 8
        L_UIDROPDOWNMENU_MAXBUTTONS = maxBtns
        local maxLevels = C_UIDROPDOWNMENU_MAXLEVELS or 2
        -- Sync list-frame aliases (nil at load time until after first toggle)
        for lvl = 1, maxLevels do
            local lListKey = "L_DropDownList" .. lvl
            if not _G[lListKey] then
                _G[lListKey] = _G["C_DropDownList" .. lvl]
            end
            -- Set .dropdown for LibUIDropDownMenu compat
            local listFrame = _G["C_DropDownList" .. lvl]
            if listFrame and lvl == (level or 1) then
                listFrame.dropdown = dropDownFrame
                if dropDownFrame and dropDownFrame.GetFrameLevel and listFrame.SetFrameLevel then
                    listFrame:SetFrameLevel(dropDownFrame:GetFrameLevel() + 30)
                end
                -- Propagate anchor's strata to list frame when anchor is in a higher strata
                -- (e.g. FULLSCREEN_DIALOG panel triggering a dropdown whose list defaults to
                -- FULLSCREEN — without this the list appears behind the panel on first open).
                local anchorFrame = anchorName
                if type(anchorName) == "string" then anchorFrame = _G[anchorName] end
                if type(anchorFrame) == "table" and anchorFrame.GetFrameStrata and listFrame.SetFrameStrata then
                    local aStrata = anchorFrame:GetFrameStrata()
                    local lStrata = listFrame:GetFrameStrata()
                    if (_strataOrder[aStrata] or 0) > (_strataOrder[lStrata] or 0) then
                        listFrame:SetFrameStrata(aStrata)
                        if anchorFrame.GetFrameLevel then
                            listFrame:SetFrameLevel(anchorFrame:GetFrameLevel() + 20)
                        end
                    end
                end
            end
        end
        -- Sync button aliases for any newly created buttons
        for i = 1, maxBtns do
            for lvl = 1, maxLevels do
                local lKey = "L_DropDownList" .. lvl .. "Button" .. i
                if not _G[lKey] then
                    local cFrame = _G["C_DropDownList" .. lvl .. "Button" .. i]
                    if cFrame then _G[lKey] = cFrame end
                end
            end
        end
    end
end
