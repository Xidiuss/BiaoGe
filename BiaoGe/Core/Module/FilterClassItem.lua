if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxb = ns.HopeMaxb
local HopeMaxi = ns.HopeMaxi

local pt = print

local F = {}
local RealmId = GetRealmID()
local player = BG.playerName
local _, class = UnitClass("player")

function BG.FilterClassItemUI()
    -- Font
    do
        local color = "Filter_+" -- BG.FontFilter_+
        BG["Font" .. color] = CreateFont("BG.Font" .. color)
        BG["Font" .. color]:SetTextColor(RGB("FFFFFF"))
        BG["Font" .. color]:SetFont(BIAOGE_TEXT_FONT, 25, "OUTLINE")

        local color = "Filter_+_Highlight" -- BG.FontFilter_+_Highlight
        BG["Font" .. color] = CreateFont("BG.Font" .. color)
        BG["Font" .. color]:SetTextColor(RGB("FFFFFF"))
        BG["Font" .. color]:SetFont(BIAOGE_TEXT_FONT, 30, "OUTLINE")
    end

    BG.filterClassButtons = {}
    local function UpdateAllButton(num)
        if type(num) ~= "number" or num < 1 or not BiaoGe.FilterClassItemDB[RealmId][player][num] then
            num = nil
        end
        for k, v in pairs(F.frames) do
            if num then
                v:Show()
            else
                v:Hide()
            end
        end
        for k, bts in pairs(BG.filterClassButtons) do
            local i = 1
            while bts[i] do
                if not num or i ~= num then
                    bts[i].icon:SetDesaturated(true)
                    bts[i].tex:Hide()
                else
                    bts[i].icon:SetDesaturated(false)
                    bts[i].tex:Show()
                end
                i = i + 1
            end
        end
        BiaoGe.FilterClassItemDB[RealmId][player].chooseID = num
        if num then
            BG.FilterClassItemMainFrame.resetButton:Show()
        else
            BG.FilterClassItemMainFrame.resetButton:Hide()
        end

        for key, _ in pairs(F.buttons) do
            if num then
                BiaoGe.FilterClassItemDB[RealmId][player][num][key] = BiaoGe.FilterClassItemDB[RealmId][player][num][key] or {}
            end
            for _, bt in pairs(F.buttons[key]) do
                if num and BiaoGe.FilterClassItemDB[RealmId][player][num][key][bt.key] == 1 then
                    bt:SetChecked(true)
                else
                    bt:SetChecked(false)
                end
            end
        end
    end

    local function UpdateAllFilterClassButtons()
        for k, buttons in pairs(BG.filterClassButtons) do
            BG.CreateFilterClassButtons(buttons)
        end
    end

    local function OnClick(self, enter)
        local num = self.num
        if enter ~= "RightButton" then
            if self.icon:IsDesaturated() then -- 如果已经去饱和（就是不生效的状态）
                UpdateAllButton(num)
            else
                UpdateAllButton(nil)
            end
            if self.type == 3 then
                BGV.UpdateMerchantFrame(nil, true)
            else
            end
            BG.UpdateAllFilter()
            LibBG:CloseDropDownMenus()
        elseif self.type ~= 3 then
            if BG.DropDownListIsVisible(self) then
                _G.L_DropDownList1:Hide()
            else
                local shunxu = {
                    {
                        isTitle = true,
                        text = L["更改至第几位"],
                        notCheckable = true,
                    },
                }
                for i, v in ipairs(BiaoGe.FilterClassItemDB[RealmId][player]) do
                    local a = {
                        text = i,
                        notCheckable = true,
                        func = function()
                            local valueToMove = BiaoGe.FilterClassItemDB[RealmId][player][num]
                            local chooseID = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                            if chooseID then
                                BiaoGe.FilterClassItemDB[RealmId][player][chooseID].moving = true
                            end
                            table.remove(BiaoGe.FilterClassItemDB[RealmId][player], num)
                            table.insert(BiaoGe.FilterClassItemDB[RealmId][player], i, valueToMove)

                            if chooseID then
                                for i, v in ipairs(BiaoGe.FilterClassItemDB[RealmId][player]) do
                                    if v.moving then
                                        chooseID = i
                                        v.moving = nil
                                        break
                                    end
                                end
                                UpdateAllButton(chooseID)
                            end
                            UpdateAllFilterClassButtons()
                            BG.UpdateAllFilter()
                            LibBG:CloseDropDownMenus()
                        end
                    }
                    tinsert(shunxu, a)
                end

                local channelTypeMenu = {
                    {
                        isTitle = true,
                        text = BiaoGe.FilterClassItemDB[RealmId][player][num].Name,
                        notCheckable = true,
                    },

                    {
                        text = L["修改名称/图标"],
                        notCheckable = true,
                        func = function()
                            BG.FilterClassItemMainFrame:Show()
                            BG.FilterClassItemMainFrame.AddFrame:Hide()
                            BG.FilterClassItemMainFrame.AddFrame:Show()
                            BG.FilterClassItemMainFrame.AddFrame.tilte:SetText(L["正在修改方案："] .. BiaoGe.FilterClassItemDB[RealmId][player][num].Name)
                            BG.FilterClassItemMainFrame.AddFrame.edit:SetText(BiaoGe.FilterClassItemDB[RealmId][player][num].Name)
                            BG.FilterClassItemMainFrame.AddFrame.xiugai = num

                            for ii, icon in ipairs(BG.FilterClassItemMainFrame.AddFrame.icons) do
                                if icon.iconpath == BiaoGe.FilterClassItemDB[RealmId][player][num].Icon then
                                    icon.tex:Show()
                                    BG.FilterClassItemMainFrame.AddFrame.icon = icon.iconpath
                                end
                            end

                            for k, v in pairs(BG.FilterClassItemMainFrame.Buttons) do
                                if type(v) == "table" then
                                    v:SetAlpha(0.2)
                                end
                            end
                            BG.FilterClassItemMainFrame.Buttons[num]:SetAlpha(1)
                        end
                    },
                    {
                        text = L["更改顺序"],
                        notCheckable = true,
                        hasArrow = true,
                        menuList = shunxu
                    },
                    {
                        isTitle = true,
                        text = "   ",
                        notCheckable = true,
                    },
                    {
                        text = L["删除方案"],
                        notCheckable = true,
                        func = function()
                            tremove(BiaoGe.FilterClassItemDB[RealmId][player], num)
                            local chooseID = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                            if chooseID then
                                if chooseID == num then
                                    chooseID = nil
                                    UpdateAllButton(chooseID)
                                elseif chooseID > num then
                                    chooseID = chooseID - 1
                                    UpdateAllButton(chooseID)
                                end
                            end
                            UpdateAllFilterClassButtons()
                            BG.UpdateAllFilter()
                        end
                    },
                    {
                        isTitle = true,
                        text = "   ",
                        notCheckable = true,
                    },
                    {
                        text = CANCEL,
                        notCheckable = true,
                        func = function(self)
                            LibBG:CloseDropDownMenus()
                        end,
                    }
                }
                LibBG:EasyMenu(channelTypeMenu, BG.dropDown, self, 0, 0, "MENU", 3)
            end
        end
        BG.UpdateItemLib()
        BG.PlaySound(1)
    end

    function BG.CreateFilterClassButtons(parent)
        for k, v in ipairs(parent) do
            v:Hide()
            parent[k] = nil
        end

        local type = parent.type
        local width = 0

        local i = 1
        while BiaoGe.FilterClassItemDB[RealmId][player][i] do
            local bt = CreateFrame("Button", nil, parent)
            if i == 1 then
                bt:SetPoint("LEFT", 0, 0)
            else
                bt:SetPoint("LEFT", parent[i - 1], "RIGHT", 10, 0)
            end
            bt:SetSize(25, 25)
            bt:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            bt.num = i
            bt.type = type
            width = width + 35
            parent:SetWidth(width)
            tinsert(parent, bt)
            if BG.FilterClassItemMainFrame then
                bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 10)
            end

            local tex = bt:CreateTexture(nil, "BACKGROUND") -- 选中材质
            tex:SetSize(31, 31)
            tex:SetPoint("CENTER")
            tex:SetColorTexture(0, 0.55, 1, 0.28)
            tex:Hide()
            bt.tex = tex

            local icon = bt:CreateTexture(nil, "ARTWORK") -- 图标
            icon:SetAllPoints()
            icon:SetTexture(BiaoGe.FilterClassItemDB[RealmId][player][i].Icon)
            icon:SetDesaturated(true)
            bt.icon = icon
            if BiaoGe.FilterClassItemDB[RealmId][player].chooseID == i then
                icon:SetDesaturated(false)
                tex:Show()
            end

            local hightex = bt:CreateTexture(nil, "HIGHLIGHT") -- 悬停材质
            hightex:SetSize(23, 23)
            hightex:SetPoint("CENTER")
            hightex:SetColorTexture(RGB("FFFFFF", 0.2))

            bt:SetScript("OnClick", OnClick)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -3, 2)
                GameTooltip:ClearLines()
                if type ~= 1 then
                    local r, g, b = RGB(BG.g1)
                    GameTooltip:AddLine(L["使用装备过滤方案："], r, g, b, true)
                end
                GameTooltip:AddLine(BiaoGe.FilterClassItemDB[RealmId][player][bt.num].Name, 1, 1, 1, true)
                if type == 1 then
                    GameTooltip:AddLine(AddTexture("LEFT") .. L["使用方案"], 1, .82, 0, true)
                    GameTooltip:AddLine(AddTexture("RIGHT") .. L["修改方案"], 1, .82, 0, true)
                end
                GameTooltip:Show()
            end)
            BG.GameTooltip_Hide(bt)
            i = i + 1
        end
    end

    local function CreateFilterButton(table, tilte, tilte_onenter, filterType, pailie) --BG.FilterClassItemDB[filterType]
        local height = 28

        local f = CreateFrame("Frame", nil, BG.FilterClassItemFrame)
        f:SetSize(BG.FilterClassItemFrame:GetWidth(), height)
        if F.lastFrame then
            f:SetPoint("TOPLEFT", F.lastFrame, "BOTTOMLEFT", 0, -5)
        else
            f:SetPoint("TOPLEFT", BG.FilterClassItemFrame, "TOPLEFT", 5, -10)
        end
        F.lastFrame = f

        local f_tilte = CreateFrame("Frame", nil, f)
        f_tilte:SetPoint("TOPLEFT", 10, -5)
        f_tilte:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 10)
        local t = f_tilte:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("LEFT")
        t:SetText(tilte)
        f_tilte:SetSize(t:GetStringWidth(), 20)
        f_tilte:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(t:GetText(), 1, 1, 1, true)
            if tilte_onenter then
                GameTooltip:AddLine(tilte_onenter, 1, 0.82, 0, true)
            end
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(f_tilte)

        local l = f:CreateLine()
        l:SetColorTexture(RGB("808080", 1))
        l:SetStartPoint("BOTTOMLEFT", t, -10, -4)
        l:SetEndPoint("BOTTOMLEFT", t, f:GetWidth() - 20, -4)
        l:SetThickness(1.5)

        local buttons = {}
        local width = pailie and f:GetWidth() or 110
        local btheight = 25
        for i, v in ipairs(table) do
            local btName = "BiaoGeFilterBtn_" .. filterType .. "_" .. i
            local bt = CreateFrame("CheckButton", btName, f, "ChatConfigCheckButtonTemplate")
            bt.Text = bt.Text or _G[btName .. "Text"]
            bt:SetSize(25, btheight)
            bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 10)
            if i == 1 then
                bt:SetPoint("TOPLEFT", 10, -height)
                f:SetHeight(f:GetHeight() + btheight)
            elseif not pailie then
                if (i - 1) % 5 ~= 0 then
                    bt:SetPoint("LEFT", buttons[i - 1], "RIGHT", width, 0)
                elseif (i - 1) % 5 == 0 then
                    bt:SetPoint("TOPLEFT", buttons[i - 5], "BOTTOMLEFT", 0, 0)
                    f:SetHeight(f:GetHeight() + btheight)
                end
            else
                bt:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, 0)
                f:SetHeight(f:GetHeight() + btheight)
            end
            buttons[i] = bt
            local _rawVal = type(v.value) == "string" and v.value or nil
            if _rawVal and (_rawVal == "?" or _rawVal:find("%%[ds]")) then _rawVal = nil end
            local text = (v.name2 ~= "?" and v.name2 or nil) or _rawVal or v.name or ""
            text = text:gsub("%(%.%+%)", "xx")
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            bt.Text:SetText(text)
            bt.Text:SetWidth(width)
            bt.Text:SetWordWrap(false)
            bt.key = v.name
            -- hit rect ograniczony do szerokości kolumny (width), NIE do pełnej
            -- (nieprzyciętej) szerokości tekstu — inaczej zakres klikalny skróconej
            -- nazwy "One-ha..." sięgał pełnej "One-Handed Swords" i zachodził na sąsiada.
            bt:SetHitRectInsets(0, -width, 0, 0)
            local _top = BG.FilterClassItemMainFrame:GetTop()
            local _bot = bt:GetBottom()
            if _top and _bot then
                local _newH = _top - _bot + 40
                if _newH > BG.FilterClassItemMainFrame:GetHeight() then
                    BG.FilterClassItemMainFrame:SetHeight(_newH)
                end
            end

            local id = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
            if id then
                if BiaoGe.FilterClassItemDB[RealmId][player][id][filterType][v.name] == 1 then
                    bt:SetChecked(true)
                else
                    bt:SetChecked(false)
                end
            end

            bt:SetScript("OnClick", function(self)
                local id = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                if id then
                    if self:GetChecked() then
                        BiaoGe.FilterClassItemDB[RealmId][player][id][filterType][v.name] = 1
                    else
                        BiaoGe.FilterClassItemDB[RealmId][player][id][filterType][v.name] = nil
                    end
                    BG.PlaySound(1)
                end
                BG.UpdateAllFilter()
                BG.UpdateItemLib()
            end)

            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.Text:GetText(), 1, 1, 1, true)
                if v.onenter then
                    GameTooltip:AddLine(v.onenter, 1, 0.82, 0, true)
                end
                GameTooltip:Show()
            end)
            BG.GameTooltip_Hide(bt)
        end

        return buttons, F.lastFrame
    end

    ------------------------------------------------------------------------
    ------------------------------------------------------------------------

    -- 主框体
    local f = CreateFrame("Frame", "BiaoGeFilterClassItemMainFrame", UIParent, "BackdropTemplate")
    do
        f:SetBackdrop({
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        BG.SetSafeBackground(f, 0, 0, 0, 0.65)
        f:SetBackdropBorderColor(GetClassRGB(nil, "player", 1))
        f:SetWidth(720)   -- 560→720: mieści 5 kolumn × 110px (pełne nazwy) bez zwiększania liczby rzędów (regresja wysokości spec 003/A)
        f:SetHeight(400)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(600)
        f:SetPoint("CENTER", 100, 0)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        f:SetScript("OnMouseDown", function(self)
            LibBG:CloseDropDownMenus()
            BG.ClearFocus()
            self:StartMoving()
        end)
        f:SetScript("OnShow", function(self)
            BG.FilterClassItemMainFrame.AddFrame:Hide()
        end)
        f:SetScript("OnHide", function(self)
            self:Hide()
        end)
        BG.FilterClassItemMainFrame = f

        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 16, "OUTLINE")
        t:SetText(L["< 装备过滤 >"])
        t:SetPoint("TOP", 0, -7)
        t:SetTextColor(1, 1, 1)

        local bt = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        bt:SetPoint("TOPRIGHT", 0, 0)
        bt:SetFrameLevel(f:GetFrameLevel() + 10)

        local bt = BG.CreateButton(f)
        bt:SetSize(130, 25)
        bt:SetPoint("BOTTOMRIGHT", -10, 15)
        bt:SetText(CLOSE)
        bt:SetFrameLevel(f:GetFrameLevel() + 10)
        bt:SetScript("OnClick", function(self)
            self:GetParent():Hide()
        end)
        f.CloseButton = bt
    end

    -- 背景框
    local f = CreateFrame("Frame", "BiaoGeFilterClassItemFrame", BG.FilterClassItemMainFrame)
    do
        f:SetPoint("TOPLEFT", 5, -65)
        f:SetPoint("BOTTOMRIGHT", -5, 5)
        f:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 5)
        BG.FilterClassItemFrame = f
    end
    local Buttons = CreateFrame("Frame", "BiaoGeFilterClassItemButtons", BG.FilterClassItemMainFrame)
    do
        Buttons:SetPoint("TOP", 30, -40)
        Buttons:SetSize(0, 30)
        Buttons:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 5)
        Buttons.type = 1
        BG.FilterClassItemMainFrame.Buttons = Buttons
        tinsert(BG.filterClassButtons, Buttons)
        local t = Buttons:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetText(L["选择方案："])
        t:SetPoint("RIGHT", Buttons, "LEFT", -10, 0)
        t:SetTextColor(1, 0.82, 0)
        BG.FilterClassItemMainFrame.ChossesText = t
        BG.CreateFilterClassButtons(Buttons)
    end
    local Buttons2 = CreateFrame("Frame", nil, BG.MainFrame)
    do
        local offset
        if BG.onlyOneHard then
            offset = 250
        else
            offset = 410
        end
        Buttons2:SetPoint("BOTTOMLEFT", offset, 35)
        Buttons2:SetSize(0, 30)
        Buttons2.type = 2
        -- (usunięto redundantne SetFrameLevel(600) — main frame już ma 600 z głównego
        -- bloku; powtórny SetFrameLevel po utworzeniu dzieci renormalizuje GetFrameLevel()
        -- w dół, przez co ramki tworzone PÓŹNIEJ (AddButton "+", AddFrame) dostawały level
        -- poniżej parenta i były nieklikalne. /fstack: "+" był na <5>, parent na <6>.)
        BG.FilterClassItemMainFrame.Buttons2 = Buttons2
        BG.CreateFilterClassButtons(Buttons2)
        tinsert(BG.filterClassButtons, Buttons2)
        function Buttons2:UpdatePoint()
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", offset, 35)
        end
    end

    -- 新建方案的框体
    local f = CreateFrame("Frame", "BiaoGeFilterClassItemAddFrame", BG.FilterClassItemMainFrame, "BackdropTemplate")
    do
        f:SetPoint("TOPLEFT", 10, -80)
        f:SetPoint("BOTTOMRIGHT", BG.FilterClassItemMainFrame.CloseButton, "BOTTOMRIGHT", 0, -3)
        f:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 20)
        f:SetBackdrop(BG_BACKDROP_PANEL)
        f:SetBackdropColor(0, 0, 0, 1)
        BG.SetSafeBackground(f, 0, 0, 0, 1)   -- solidne nieprzezroczyste tło dialogu (bez prześwitów)
        f:EnableMouse(true)
        f:Hide()
        f:SetScript("OnMouseUp", function(self)
            self:GetParent():StopMovingOrSizing()
        end)
        f:SetScript("OnMouseDown", function(self)
            LibBG:CloseDropDownMenus()
            BG.ClearFocus()
            self:GetParent():StartMoving()
        end)
        f:SetScript("OnHide", function(self)
            self:Hide()
        end)
        BG.FilterClassItemMainFrame.AddFrame = f

        local t = f:CreateFontString()
        do
            t:SetPoint("TOP", 0, -15)
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetTextColor(RGB(BG.g1))
            t:SetText(L["新建过滤方案"])
            f.tilte = t

            local l = f:CreateLine()
            l:SetColorTexture(RGB("808080", 1))
            l:SetStartPoint("BOTTOMLEFT", t, -30, -4)
            l:SetEndPoint("BOTTOMRIGHT", t, 30, -4)
            l:SetThickness(1.5)
        end

        local t = f:CreateFontString()
        t:SetPoint("TOPLEFT", 25, -40)
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetTextColor(RGB("FFD100"))
        t:SetText(L["名称："])

        local edit = CreateFrame("EditBox", nil, f, "BiaoGe_InputBoxTemplate")
        do
            edit:SetSize(150, 20)
            edit:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -5)
            edit:SetText("")
            edit:SetAutoFocus(false)
            edit:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 25)
            f.edit = edit
            edit:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(false)
                    edit:SetText("")
                else
                    edit:SetFocus()
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(true)
                end
            end)
        end

        local t = f:CreateFontString()
        t:SetPoint("TOPLEFT", edit, "BOTTOMLEFT", 0, -12)
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetTextColor(RGB("FFD100"))
        t:SetText(L["图标："])

        f.icons = {}
        local height
        local last
        local maxicon = 12
        local othericon = 31
        local isOther
        for i, iconpath in ipairs(BG.FilterClassItemDB.NewIcon) do
            local bt = CreateFrame("Button", nil, f)
            if i > othericon then
                -- if BG.IsRetail then
                --     break
                -- else
                isOther = true
                -- end
            end
            if not isOther then
                if i == 1 then
                    bt:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
                elseif (i - 1) % maxicon == 0 then
                    bt:SetPoint("TOPLEFT", f.icons[i - maxicon], "BOTTOMLEFT", 0, -10)
                    last = i
                elseif (i - 1) % maxicon ~= 0 then
                    bt:SetPoint("LEFT", f.icons[i - 1], "RIGHT", 10, 0)
                end
            else
                local newi = i - othericon
                if newi == 1 then
                    bt:SetPoint("TOPLEFT", f.icons[last], "BOTTOMLEFT", 0, -10)
                    last = i
                elseif (newi - 1) % maxicon == 0 then
                    bt:SetPoint("TOPLEFT", f.icons[i - maxicon], "BOTTOMLEFT", 0, -10)
                    last = i
                elseif (newi - 1) % maxicon ~= 0 then
                    bt:SetPoint("LEFT", f.icons[i - 1], "RIGHT", 10, 0)
                end
            end
            bt:SetSize(30, 30)
            bt.num = i
            bt.iconpath = iconpath
            bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 25)
            height = f:GetTop() - bt:GetBottom()
            tinsert(f.icons, bt)

            local tex = bt:CreateTexture(nil, "BACKGROUND") -- 选中材质 (niebieska obramówka zaznaczenia)
            tex:SetSize(36, 36)   -- 6px większe niż ikona 30x30 → widoczny 3px niebieski border za ikoną
            tex:SetPoint("CENTER", 0, 0)
            tex:SetColorTexture(0, 0.6, 1, 1)
            tex:Hide()
            bt.tex = tex

            local icon = bt:CreateTexture(nil, "ARTWORK") -- 图标
            icon:SetAllPoints()
            icon:SetTexture(iconpath)

            local hightex = bt:CreateTexture(nil, "HIGHLIGHT") -- 悬停材质
            hightex:SetSize(28, 28)
            hightex:SetPoint("CENTER")
            hightex:SetColorTexture(RGB("FFFFFF", 0.2))

            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                for ii, v in ipairs(f.icons) do
                    if ii ~= self.num then
                        v.tex:Hide()
                    else
                        v.tex:Show()
                    end
                end
                f.icon = iconpath
            end)
        end

        local bt = BG.CreateButton(f)
        bt:SetSize(120, 25)
        bt:SetPoint("TOPLEFT", 25, -height - 15)
        bt:SetText(L["确定"])
        bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 25)
        bt:SetScript("OnEnter", function(self)
            local tbl = {}
            if edit:GetText() == "" then
                tinsert(tbl, L["名称"])
            end
            if not f.icon then
                tinsert(tbl, L["图标"])
            end
            local text = table.concat(tbl, ", ")
            if text ~= "" then
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                if not f.xiugai then
                    GameTooltip:AddLine(L["不能新建"], 1, 0, 0, true)
                else
                    GameTooltip:AddLine(L["不能修改"], 1, 0, 0, true)
                end
                GameTooltip:AddLine(L["还需填写："] .. text, 1, 0.82, 0, true)
                GameTooltip:Show()
            end
        end)
        BG.GameTooltip_Hide(bt)
        bt:SetScript("OnClick", function(self)
            if edit:GetText() == "" or not f.icon then return end
            if not f.xiugai then
                local a = {
                    Name = edit:GetText(),
                    Icon = f.icon,
                    ShuXing = {},
                    Weapon = {},
                    Armor = {},
                    Class = {},
                    Tank = {},
                }
                tinsert(BiaoGe.FilterClassItemDB[RealmId][player], a)
            else
                BiaoGe.FilterClassItemDB[RealmId][player][f.xiugai].Name = edit:GetText()
                BiaoGe.FilterClassItemDB[RealmId][player][f.xiugai].Icon = f.icon
            end
            f:Hide()
            UpdateAllFilterClassButtons()
            BG.UpdateAllFilter()
            BG.PlaySound(1)
        end)
        local lastbt = bt

        local bt = BG.CreateButton(f)
        bt:SetSize(120, 25)
        bt:SetPoint("LEFT", lastbt, "RIGHT", 15, 0)
        bt:SetText(L["返回"])
        bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 25)
        bt:SetScript("OnClick", function(self)
            f:Hide()
            BG.PlaySound(1)
        end)

        -- widoczne (złote) obramówki OK/Back — domyślny czarny border CreateButton
        -- ginie na ciemnym tle dialogu; HookScript re-aplikuje po reset-on-leave
        for _, _b in ipairs({ lastbt, bt }) do
            _b:SetBackdropBorderColor(1, 0.82, 0, 1)
            _b:HookScript("OnLeave", function(self)
                self:SetBackdropBorderColor(1, 0.82, 0, 1)
            end)
        end

        f:SetScript("OnShow", function(self)
            BG.FilterClassItemMainFrame.resetButton:Hide()
            f.xiugai = nil
            f.tilte:SetText(L["新建过滤方案"])
            edit:SetText(L["new"])
            f.icon = nil
            for ii, icon in ipairs(f.icons) do
                icon.tex:Hide()
            end
            for k, v in pairs(BG.FilterClassItemMainFrame.Buttons) do
                if type(v) == "table" then
                    v:SetAlpha(0.2)
                end
            end
            BG.FilterClassItemMainFrame.ChossesText:SetTextColor(1, 0.82, 0, 0.2)
        end)
        f:SetScript("OnHide", function(self)
            BG.FilterClassItemMainFrame.resetButton:Show()
            for k, v in pairs(BG.FilterClassItemMainFrame.Buttons) do
                if type(v) == "table" then
                    v:SetAlpha(1)
                end
            end
            BG.FilterClassItemMainFrame.ChossesText:SetTextColor(1, 0.82, 0, 1)
        end)
    end
    -- 新建方案的按钮
    do
        local bt = CreateFrame("Button", nil, BG.FilterClassItemMainFrame)
        bt:SetNormalFontObject(BG["FontFilter_+"])
        bt:SetHighlightFontObject(BG["FontFilter_+_Highlight"])
        bt:SetPoint("LEFT", Buttons, "RIGHT", 0, 0)
        bt:SetSize(25, 25)
        bt:SetText("+")
        bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 10)
        Buttons.AddButton = bt
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -3, 2)
            GameTooltip:ClearLines()
            if #BiaoGe.FilterClassItemDB[RealmId][player] >= 6 then
                GameTooltip:AddLine(L["方案数量已达上限，不能再新建方案"], 1, 0, 0, true)
            else
                GameTooltip:AddLine(L["新建过滤方案"], 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(bt)
        bt:SetScript("OnClick", function(self)
            if #BiaoGe.FilterClassItemDB[RealmId][player] >= 6 then return end
            if BG.FilterClassItemMainFrame.AddFrame.xiugai then
                BG.FilterClassItemMainFrame.AddFrame:Hide()
            end
            if BG.FilterClassItemMainFrame.AddFrame:IsVisible() then
                BG.FilterClassItemMainFrame.AddFrame:Hide()
            else
                BG.FilterClassItemMainFrame.AddFrame:Show()
            end
            LibBG:CloseDropDownMenus()
            BG.PlaySound(1)
        end)
    end

    -- 重置
    local bt = CreateFrame("Button", nil, BG.FilterClassItemMainFrame)
    do
        bt:SetNormalFontObject(BG.FontRed15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetSize(60, 30)
        bt:SetPoint("TOPLEFT", 5, -40)
        bt:SetText(L["重置"])
        bt:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        bt:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 10)
        BG.FilterClassItemMainFrame.resetButton = bt
        if not BiaoGe.FilterClassItemDB[RealmId][player].chooseID then
            bt:Hide()
        end
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["把方案重置为默认值"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(bt)
        bt:SetScript("OnClick", function(self)
            if BG.DropDownListIsVisible(self) then
                _G.L_DropDownList1:Hide()
            else
                local channelTypeMenu = {
                    {
                        isTitle = true,
                        text = L["重置为默认方案"],
                        notCheckable = true,
                    },
                }

                for i = 1, BG.MaxFilter[class] do
                    local a = {
                        text = BG.FilterClassItemDB.Icon[class .. i].name,
                        notCheckable = true,
                        func = function()
                            for type, _ in pairs(F.buttons) do
                                -- 多选按钮重置
                                for _, bt in pairs(F.buttons[type]) do
                                    local yes
                                    for k, v in pairs(BG.FilterClassItem_Default[type][class .. i]) do
                                        if v == bt.key then
                                            bt:SetChecked(true)
                                            yes = true
                                            break
                                        end
                                    end
                                    if not yes then
                                        bt:SetChecked(false)
                                    end
                                end

                                -- 数据库重置
                                local num = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                                BiaoGe.FilterClassItemDB[RealmId][player][num][type] = {}
                                for k, v in pairs(BG.FilterClassItem_Default[type][class .. i]) do
                                    BiaoGe.FilterClassItemDB[RealmId][player][num][type][v] = 1
                                end
                            end
                            BG.UpdateAllFilter()
                            BG.UpdateItemLib()
                        end
                    }
                    tinsert(channelTypeMenu, a)
                end

                local a = {
                    isTitle = true,
                    text = L["其他"],
                    notCheckable = true,
                }
                tinsert(channelTypeMenu, a)

                local a = {
                    text = L["勾选全部多选框"],
                    notCheckable = true,
                    func = function()
                        for type, _ in pairs(F.buttons) do
                            -- 多选按钮重置
                            for _, bt in pairs(F.buttons[type]) do
                                bt:SetChecked(true)
                            end

                            -- 数据库重置
                            local num = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                            BiaoGe.FilterClassItemDB[RealmId][player][num][type] = {}
                            for k, v in pairs(BG.FilterClassItemDB[type]) do
                                BiaoGe.FilterClassItemDB[RealmId][player][num][type][v.name] = 1
                            end
                        end
                        BG.UpdateAllFilter()
                        BG.UpdateItemLib()
                    end
                }
                tinsert(channelTypeMenu, a)

                local a = {
                    text = L["取消勾选全部多选框"],
                    notCheckable = true,
                    func = function()
                        for type, _ in pairs(F.buttons) do
                            -- 多选按钮重置
                            for _, bt in pairs(F.buttons[type]) do
                                bt:SetChecked(false)
                            end

                            -- 数据库重置
                            local num = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                            BiaoGe.FilterClassItemDB[RealmId][player][num][type] = {}
                        end
                        BG.UpdateAllFilter()
                        BG.UpdateItemLib()
                    end
                }
                tinsert(channelTypeMenu, a)

                local a = {
                    isTitle = true,
                    text = "   ",
                    notCheckable = true,
                }
                tinsert(channelTypeMenu, a)

                local a = {
                    text = CANCEL,
                    notCheckable = true,
                    func = function(self)
                        LibBG:CloseDropDownMenus()
                    end,
                }
                tinsert(channelTypeMenu, a)

                LibBG:EasyMenu(channelTypeMenu, BG.dropDown, self, 0, 0, "MENU", 3)
            end
            BG.PlaySound(1)
        end)
    end
    -- 设置按钮
    local bt = CreateFrame("Button", nil, Buttons2)
    do
        bt:SetPoint("LEFT", Buttons2, "RIGHT", 0, 0)
        bt:SetSize(25, 25)
        bt:SetNormalTexture([[Interface\Icons\INV_Misc_Gear_01]])
        bt:SetPushedTexture([[Interface\Icons\INV_Misc_Gear_01]])
        bt:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
        local function SetButtonIconTexCoord(texture)
            if texture and BG.iconTexCoord then
                texture:SetTexCoord(unpack(BG.iconTexCoord))
            end
        end
        SetButtonIconTexCoord(bt:GetNormalTexture())
        SetButtonIconTexCoord(bt:GetPushedTexture())
        BG.FilterClassItemMainFrame:ClearAllPoints()
        BG.FilterClassItemMainFrame:SetPoint("BOTTOMLEFT", bt, "TOPRIGHT", 0, 30)
        bt:SetScript("OnClick", function(self)
            if BG.FilterClassItemMainFrame:IsVisible() then
                BG.FilterClassItemMainFrame:Hide()
            else
                LibBG:CloseDropDownMenus()
                BG.FilterClassItemFrame:Show()
                BG.FilterClassItemMainFrame.Buttons:Show()
                local chooseID = BiaoGe.FilterClassItemDB[RealmId][player].chooseID
                if (type(chooseID) ~= "number" or chooseID < 1 or not BiaoGe.FilterClassItemDB[RealmId][player][chooseID])
                    and BiaoGe.FilterClassItemDB[RealmId][player][1] then
                    UpdateAllButton(1)
                end
                BG.FilterClassItemMainFrame:ClearAllPoints()
                BG.FilterClassItemMainFrame:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 30)
                BG.FilterClassItemMainFrame:Show()
            end
            BG.PlaySound(1)
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["自定义装备过滤方案"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(bt)
    end

    -- 开始创建多选按钮
    do
        F.frames = {}
        F.buttons = {}

        local type = "Weapon"
        local tilte_onenter = L["例如勾选了单手剑，如果装备是单手剑，则会被过滤"]
        F.buttons[type], F.frames[type] = CreateFilterButton(BG.FilterClassItemDB[type], BG.STC_g1(L["武器类型过滤"]), tilte_onenter, type)
        local type = "Armor"
        local tilte_onenter = L["例如勾选了布甲，如果装备是布甲，则会被过滤"]
        F.buttons[type], F.frames[type] = CreateFilterButton(BG.FilterClassItemDB[type], BG.STC_g1(L["护甲类型过滤"]), tilte_onenter, type)
        local type = "ShuXing"
        local tilte_onenter = L["装备属性中包含特定词缀时，就会被过滤。例如勾选了力量，如果装备中有力量属性，则该装备会被过滤"]
        F.buttons[type], F.frames[type] = CreateFilterButton(BG.FilterClassItemDB[type], BG.STC_g1(L["装备词缀过滤"]), tilte_onenter, type)
        local type = "Class"
        local tilte_onenter = L["像套装兑换物这种有职业限定的装备，不适合你的会被过滤"]
        F.buttons[type], F.frames[type] = CreateFilterButton(BG.FilterClassItemDB[type], BG.STC_g1(L["职业限定过滤"]), tilte_onenter, type, "pailie")
        if BG.FilterClassItem_Default.TankKey then
            local type = "Tank"
            local tilte_onenter = format(L["没有%s任一属性的装备会被过滤（武器、饰品、圣物除外）"], STAT_CATEGORY_DEFENSE .. "/" .. STAT_PARRY .. "/" .. STAT_DODGE .. "/" .. STAT_BLOCK)
            F.buttons[type], F.frames[type] = CreateFilterButton(BG.FilterClassItemDB[type], BG.STC_b1(L["坦克专属过滤"]), tilte_onenter, type, "pailie")
        end
        UpdateAllButton(BiaoGe.FilterClassItemDB[RealmId][player].chooseID)
        BG.FilterClassItemMainFrame.resetButton:SetParent(F.frames[type])
        BG.FilterClassItemMainFrame.resetButton:SetFrameLevel(BG.FilterClassItemMainFrame:GetFrameLevel() + 10)
        BG.FilterClassItemMainFrame.Buttons2:SetParent(BG.FBMainFrame)
    end

    -- spec 005: panel auto-pokazywał się przy load (CreateFrame domyślnie widoczny,
    -- brak Hide() po zbudowaniu) — ukryj; otwierany na żądanie (config/toggle).
    BG.FilterClassItemMainFrame:Hide()

    -- spec 005 #3: ZAGNIEŻDŻONY ESC. WotLK CloseSpecialWindows zamyka WSZYSTKIE ramki
    -- z UISpecialFrames naraz → panel zamykał się razem z głównym oknem. Rozwiązanie:
    -- w UISpecialFrames trzymaj tylko NAJWYŻSZĄ WIDOCZNĄ z {AddFrame, panel, main}.
    -- Każdy ESC zamyka jedną; jej OnHide przelicza i wstawia następną w stosie:
    --   ESC → New filter program (AddFrame) → ESC → Gear filtering (panel) → ESC → okno addonu.
    -- IsVisible() (nie IsShown()): AddFrame jako dziecko panelu zachowuje IsShown=true
    -- przy ukrytym rodzicu — IsVisible odróżnia faktyczną widoczność.
    do
        local escStack = {
            "BiaoGeFilterClassItemAddFrame",   -- top
            "BiaoGeFilterClassItemMainFrame",  -- middle
            "BG.MainFrame",                    -- bottom
        }
        local function UpdateEscTarget()
            for i = #UISpecialFrames, 1, -1 do
                for _, n in ipairs(escStack) do
                    if UISpecialFrames[i] == n then
                        tremove(UISpecialFrames, i)
                        break
                    end
                end
            end
            for _, n in ipairs(escStack) do
                local fr = _G[n]
                if fr and fr:IsVisible() then
                    tinsert(UISpecialFrames, n)
                    break
                end
            end
        end
        for _, n in ipairs(escStack) do
            local fr = _G[n]
            if fr then
                -- OnShow: natychmiast (nie odpala wewnątrz pętli ESC) → nowa ramka od razu celem ESC.
                fr:HookScript("OnShow", UpdateEscTarget)
                -- OnHide: ODROCZ o 1 klatkę. OnHide odpala SYNCHRONICZNIE wewnątrz
                -- CloseSpecialWindows (close-all, bez break) — natychmiastowe dodanie następnej
                -- ramki zostałoby złapane przez TĘ SAMĄ pętlę i też zamknięte ("znów razem").
                fr:HookScript("OnHide", function()
                    if C_Timer and C_Timer.After then
                        C_Timer.After(0, UpdateEscTarget)
                    else
                        UpdateEscTarget()
                    end
                end)
            end
        end
        UpdateEscTarget()
    end
end
