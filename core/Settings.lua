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
-- POPUP DE CONFIRMATION (reset)
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

    pop.yesBtn = MakeButton(pop, 130, 28, core.L("SETTINGS_RESET_YES"))
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

    local lang = core.Prefs().lang or (GetLocale() == "frFR" and "frFR" or "enUS")
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

    local is2DOff = core.Prefs().disable2DPreview
    local btn2D = MakeChoice(card, is2DOff and core.L("SETTINGS_2D_OFF") or core.L("SETTINGS_2D_ON"),
        not is2DOff, function()
            core.Prefs().disable2DPreview = not core.Prefs().disable2DPreview
            Rebuild()
        end, 220)
    btn2D:SetPoint("TOPLEFT", PAD, cy)
    cy = cy - 36

    cy = MakeCheckbox(card, cy,
        function(on) return core.L(on and "SETTINGS_DEBUG_BTN" or "SETTINGS_DEBUG_BTN_OFF") end,
        function() return core.Prefs().debugVerbose and true or false end,
        function(v) core.Prefs().debugVerbose = v end)

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
                local prefs        = core.Prefs()
                local savedMinimap = prefs.minimap
                wipe(prefs)
                prefs.minimap = savedMinimap
                Rebuild()
                print(core.L("SETTINGS_RESET_DONE"))
            end)
    end)
    cy = cy - 34

    card:SetHeight(-cy + PAD - 6)
    y = y - card:GetHeight() - 12

    sc:SetHeight(math.abs(y) + 20)
end
