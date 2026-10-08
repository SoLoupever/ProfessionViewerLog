local addonName, ns = ...
local core = ns.core

local MARGIN = 12   -- marge des cartes dans le scrollChild
local PAD    = 14   -- marge interne des cartes

-- Reconstruit le panneau (le cache est invalidé d'abord)
local function Rebuild()
    core.InvalidateSettings()
    ns.ShowSettings()
end

-- ====================================================
-- WIDGETS
-- ====================================================
local function MakeButton(parent, w, h, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetNormalFontObject("GameFontNormalSmall")
    btn:SetText(text)
    core.Skin.Button(btn)
    return btn
end

local function MakeCard(parent, y)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT",  parent, "TOPLEFT",  MARGIN, y)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -MARGIN, y)
    core.Skin.Frame(card, "card")
    return card
end

local function MakeCheckbox(parent, y, labelText, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("TOPLEFT", PAD, y)
    core.Skin.Button(cb, "input")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb:SetChecked(get())

    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 10, 0)
    fs:SetTextColor(unpack(core.Theme.text))
    fs:SetText(type(labelText) == "function" and labelText(get()) or labelText)

    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        set(v)
        if type(labelText) == "function" then fs:SetText(labelText(v)) end
    end)
    return y - 28
end

-- Bouton de choix (langue / thème / bascule) : doré quand actif
local function MakeChoice(parent, label, active, onClick, w)
    local btn = MakeButton(parent, w or 110, 26, label)
    btn._active = active
    core.Skin.Paint(btn)
    local c = active and core.Theme.gold or core.Theme.text
    btn:GetFontString():SetTextColor(c[1], c[2], c[3])
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Ligne « libellé : [choix] [choix] »
local function MakeChoiceRow(parent, y, labelText, choices)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", PAD, y - 5)
    lbl:SetText(labelText)
    lbl:SetTextColor(unpack(core.Theme.textDim))

    local prev
    for _, c in ipairs(choices) do
        local b = MakeChoice(parent, c.label, c.active, c.onClick)
        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", 8, 0)
        else
            b:SetPoint("TOPLEFT", PAD + 170, y)
        end
        prev = b
    end
    return y - 34
end

-- ====================================================
-- POPUP DE CONFIRMATION (partagée entre Delete et Reset)
-- ====================================================
local confirmPopup = nil

local function GetOrCreateConfirmPopup()
    if confirmPopup then return confirmPopup end

    local pop = CreateFrame("Frame", nil, core.mainFrame, "BackdropTemplate")
    pop:SetSize(340, 140)
    pop:SetPoint("CENTER")
    pop:SetFrameStrata("DIALOG")
    core.Skin.Frame(pop, "window")
    pop:Hide()

    local msg = pop:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    msg:SetPoint("TOP", 0, -20)
    msg:SetWidth(300)
    msg:SetJustifyH("CENTER")
    pop.msg = msg

    pop.yesBtn = MakeButton(pop, 130, 28, core.L("SETTINGS_YES"))
    pop.yesBtn:SetPoint("BOTTOMLEFT", 18, 16)

    local noBtn = MakeButton(pop, 130, 28, core.L("SETTINGS_NO"))
    noBtn:SetPoint("BOTTOMRIGHT", -18, 16)
    noBtn:SetScript("OnClick", function() pop:Hide() end)
    pop.noBtn = noBtn

    confirmPopup = pop
    return pop
end

-- Libellés relus à chaque ouverture (changement de langue)
local function OpenConfirm(msgText, yesText, onYes)
    local pop = GetOrCreateConfirmPopup()
    pop.msg:SetText(msgText)
    pop.yesBtn:SetText(yesText)
    pop.noBtn:SetText(core.L("SETTINGS_NO"))
    pop.yesBtn:SetScript("OnClick", function() pop:Hide(); onYes() end)
    pop:Show()
end

local function MakeCharacterRow(sc, entry, offsetY)
    local charName  = entry.name
    local realmName = entry.realm
    local charData  = entry.data
    local c = (charData.class and RAID_CLASS_COLORS[charData.class]) or { r = 0.7, g = 0.7, b = 0.7 }

    local row = CreateFrame("Frame", nil, sc, "BackdropTemplate")
    row:SetHeight(38)
    row:SetPoint("TOPLEFT",  PAD, offsetY)
    row:SetPoint("TOPRIGHT", -PAD, offsetY)
    core.Skin.Frame(row, "bar")

    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetPoint("TOPLEFT", 8, -7)
    nameFS:SetTextColor(c.r, c.g, c.b)
    nameFS:SetText(charName)

    local realmFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    realmFS:SetPoint("TOPLEFT", 8, -21)
    realmFS:SetTextColor(c.r * 0.65, c.g * 0.65, c.b * 0.65)
    realmFS:SetText(realmName)

    local profCount = charData.professions and #charData.professions or 0
    local lvlTxt    = charData.level and (core.L("LEVEL_SHORT") .. charData.level) or "?"
    local infoFS    = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoFS:SetPoint("LEFT", 210, 0)
    infoFS:SetTextColor(c.r * 0.85, c.g * 0.85, c.b * 0.85)
    infoFS:SetText(string.format(core.L("SETTINGS_CHAR_INFO"), lvlTxt, profCount))

    local delBtn = MakeButton(row, 90, 26, core.L("SETTINGS_DELETE"))
    delBtn:SetPoint("RIGHT", -10, 0)

    delBtn:SetScript("OnClick", function()
        local msg = string.format("%s\n|cffffd700%s|r  |cff666666(%s)|r",
            core.L("SETTINGS_CONFIRM"), charName, realmName)
        OpenConfirm(msg, core.L("SETTINGS_YES"), function()
            if ProfessionViewerLogDB[realmName] then
                ProfessionViewerLogDB[realmName][charName] = nil
                if next(ProfessionViewerLogDB[realmName]) == nil then
                    ProfessionViewerLogDB[realmName] = nil
                end
            end
            Rebuild()
        end)
    end)
end

-- ====================================================
-- ns.ShowSettings
-- ====================================================
function ns.ShowSettings()
    local trashBin = core.trashBin

    -- ── Chemin rapide : cache valide ─────────────────
    if not core.IsSettingsDirty() and core.settingsChild then
        if core.scrollChild ~= core.settingsChild then
            if core.scrollChild then
                local ch = { core.scrollChild:GetChildren() }
                for i = 1, #ch do ch[i]:SetParent(trashBin); ch[i]:Hide() end
                core.scrollChild:SetParent(trashBin)
                core.scrollChild:Hide()
            end
            core.settingsChild:SetParent(core.scrollFrame)
            core.settingsChild:Show()
            core.scrollFrame:SetScrollChild(core.settingsChild)
            core.scrollChild = core.settingsChild
        end
        return
    end

    -- ── Reconstruction complète ──────────────────────
    if core.settingsChild and core.settingsChild ~= core.scrollChild then
        local ch = { core.settingsChild:GetChildren() }
        for i = 1, #ch do ch[i]:SetParent(trashBin); ch[i]:Hide() end
        core.settingsChild:SetParent(trashBin)
        core.settingsChild:Hide()
        core.settingsChild = nil
    end

    core.ClearContent()
    core.settingsChild = core.scrollChild
    core.MarkSettingsClean()

    local sc       = core.scrollChild

    local t = core.Theme
    local y = -10

    -- ── Titre + filet ────────────────────────────────
    local title = sc:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", MARGIN + 4, y)
    title:SetText(core.L("BTN_SETTINGS"))
    title:SetTextColor(unpack(t.heading))
    y = y - 34
    local rule = core.Skin.Rule(sc)
    rule:SetPoint("TOPLEFT",  sc, "TOPLEFT",  MARGIN, y)
    rule:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -MARGIN, y)
    y = y - 14

    -- ── Carte options ────────────────────────────────
    local card = MakeCard(sc, y)
    local cy = -PAD

    local lang = ProfessionViewerLogDB.lang or (GetLocale() == "frFR" and "frFR" or "enUS")
    cy = MakeChoiceRow(card, cy, core.L("LANG_TITLE"), {
        { label = core.L("LANG_NAME_FR"), active = (lang == "frFR"),
          onClick = function() core.SetLang("frFR"); Rebuild() end },
        { label = core.L("LANG_NAME_EN"), active = (lang == "enUS"),
          onClick = function() core.SetLang("enUS"); Rebuild() end },
    })

    local themeChoices = {}
    for _, key in ipairs(core.THEME_ORDER) do
        themeChoices[#themeChoices + 1] = {
            label   = core.L("THEME_NAME_" .. key:upper()),
            active  = (core.GetThemeKey() == key),
            onClick = function() core.ApplyTheme(key); ns.ShowSettings() end,
        }
    end
    cy = MakeChoiceRow(card, cy, core.L("THEME_TITLE"), themeChoices)

    local is2DOff = ProfessionViewerLogDB.disable2DPreview
    local btn2D = MakeChoice(card, is2DOff and core.L("SETTINGS_2D_OFF") or core.L("SETTINGS_2D_ON"),
        not is2DOff, function()
            ProfessionViewerLogDB.disable2DPreview = not ProfessionViewerLogDB.disable2DPreview
            Rebuild()
        end, 220)
    btn2D:SetPoint("TOPLEFT", PAD, cy)
    cy = cy - 36

    cy = MakeCheckbox(card, cy,
        function(on) return core.L(on and "SETTINGS_DEBUG_BTN" or "SETTINGS_DEBUG_BTN_OFF") end,
        function() return ProfessionViewerLogDB.debugVerbose and true or false end,
        function(v) ProfessionViewerLogDB.debugVerbose = v end)

    local debugDesc = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    debugDesc:SetPoint("TOPLEFT", PAD + 30, cy + 6)
    debugDesc:SetText(core.L("SETTINGS_DEBUG_DESC"))
    debugDesc:SetTextColor(unpack(t.textDim))
    cy = cy - 22

    local resetBtn = MakeButton(card, 220, 26, core.L("SETTINGS_RESET_BTN"))
    resetBtn:SetPoint("TOPLEFT", PAD, cy)
    resetBtn:GetFontString():SetTextColor(1, 0.35, 0.35)
    resetBtn:SetScript("OnClick", function()
        OpenConfirm("|cffff4444" .. core.L("SETTINGS_RESET_CONFIRM") .. "|r",
            core.L("SETTINGS_RESET_YES"), function()
                local savedMinimap = ProfessionViewerLogDB.minimap
                wipe(ProfessionViewerLogDB)
                ProfessionViewerLogDB.minimap = savedMinimap
                Rebuild()
                print(core.L("SETTINGS_RESET_DONE"))
            end)
    end)
    cy = cy - 34

    card:SetHeight(-cy + PAD - 6)
    y = y - card:GetHeight() - 12

    -- ── Carte personnages ────────────────────────────
    local charList = {}
    for realmName, realmData in pairs(ProfessionViewerLogDB) do
        if type(realmData) == "table"
        and realmName ~= "minimap"
        and realmName ~= "warbandBank"
        and realmName ~= "settings" then
            for charName, charData in pairs(realmData) do
                if type(charData) == "table" then
                    charList[#charList + 1] = { realm = realmName, name = charName, data = charData }
                end
            end
        end
    end
    table.sort(charList, function(a, b)
        if a.realm == b.realm then return a.name < b.name end
        return a.realm < b.realm
    end)

    local card2 = MakeCard(sc, y)
    local c2y = -PAD

    local sec = card2:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sec:SetPoint("TOPLEFT", PAD, c2y)
    sec:SetText(core.L("SETTINGS_TITLE"))
    sec:SetTextColor(unpack(t.heading))
    c2y = c2y - 24

    local desc = card2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", PAD, c2y)
    desc:SetText(core.L("SETTINGS_DESC"))
    desc:SetTextColor(unpack(t.textDim))
    c2y = c2y - 22

    if #charList == 0 then
        local empty = card2:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        empty:SetPoint("TOPLEFT", PAD, c2y)
        empty:SetText(core.L("SETTINGS_EMPTY"))
        c2y = c2y - 20
    else
        for _, entry in ipairs(charList) do
            MakeCharacterRow(card2, entry, c2y)
            c2y = c2y - 46
        end
    end

    card2:SetHeight(-c2y + PAD - 6)
    y = y - card2:GetHeight() - 12

    sc:SetHeight(math.abs(y) + 20)
end
