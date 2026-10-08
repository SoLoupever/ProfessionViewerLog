local addonName, ns = ...
local pluginNs = ns
local core = ns.core

-- Cache globals fréquents
local ipairs, pairs, math_max, math_abs = ipairs, pairs, math.max, math.abs
local C_Timer_After = C_Timer.After

-- ====================================================
-- PANNEAU BOIS — collé à droite de ProfessionsFrame
-- ====================================================

local PANEL_W = 175
local BTN_H   = 36
local BTN_GAP = 4
local BTN_PAD = 8
local TOP_PAD = 38

local trashBin = CreateFrame("Frame", nil, UIParent)
trashBin:Hide()

local panel = CreateFrame("Frame", "PVLBlizzWoodPanel", UIParent, "BackdropTemplate")
panel:SetWidth(PANEL_W)
core.Skin.Frame(panel, "window")
panel:SetFrameStrata("HIGH")
panel:Hide()

local panelTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
panelTitle:SetPoint("TOPLEFT", 8, -10)

local titleSep = panel:CreateTexture(nil, "ARTWORK")
titleSep:SetSize(PANEL_W - 10, 1)
titleSep:SetPoint("TOPLEFT", 5, -26)
titleSep:SetColorTexture(0.50, 0.42, 0.12, 0.6)

-- ====================================================
-- POOL DE BOUTONS — réutilisation au lieu de recréation
-- ====================================================
local btnPool = {}    -- boutons disponibles (cachés)
local activeBtns = {} -- boutons actuellement affichés

local function AcquireButton(parent)
    local btn = next(btnPool)
    if btn then
        btnPool[btn] = nil
        btn:SetParent(parent)
        btn:Show()
        return btn
    end
    btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn._nameFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn._nameFs:SetPoint("TOPLEFT", 5, -9)
    btn._nameFs:SetPoint("TOPRIGHT", -38, -9)
    btn._nameFs:SetJustifyH("LEFT")
    btn._nameFs:SetWordWrap(false)
    btn._qtyFs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn._qtyFs:SetPoint("BOTTOM", 0, 5)
    btn._qtyFs:SetJustifyH("CENTER")
    return btn
end

local function ReleaseButton(btn)
    btn:SetScript("OnEnter", nil)
    btn:SetScript("OnLeave", nil)
    btn:SetScript("OnClick", nil)
    btn:ClearAllPoints()
    btn:SetParent(trashBin)
    btn:Hide()
    btnPool[btn] = true
end

-- ====================================================
-- CONTENU DYNAMIQUE — reconstruction optimisée
-- ====================================================
local contentFrame = nil
local _lastWoodHash = nil   -- hash des quantités pour éviter redraws inutiles

local function BuildHash(woodDetail)
    local h = 0
    for id, qty in pairs(woodDetail) do h = h + id * qty end
    return h
end

local function RebuildContent(force)
    panelTitle:SetText("|cffcca060" .. core.L("WOOD_PANEL_TITLE") .. "|r")

    local _, woodDetail = pluginNs.GetWoodCounts()

    -- Skip rebuild si les données n'ont pas changé (économise des allocations)
    local newHash = BuildHash(woodDetail)
    if not force and newHash == _lastWoodHash then return end
    _lastWoodHash = newHash

    -- Relâche tous les boutons actifs dans le pool (réutilisation)
    for i = #activeBtns, 1, -1 do
        ReleaseButton(activeBtns[i])
        activeBtns[i] = nil
    end

    if not contentFrame or contentFrame:GetParent() == trashBin then
        contentFrame = CreateFrame("Frame", nil, panel)
        contentFrame:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, 0)
        contentFrame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    end

    local curY = -(TOP_PAD)

    for _, expBlock in ipairs(pluginNs.WOOD_BY_EXPANSION) do
        local expQty = 0
        for _, item in ipairs(expBlock.items) do
            expQty = expQty + (woodDetail[item.id] or 0)
        end

        local cr, cg, cb = expBlock.color[1], expBlock.color[2], expBlock.color[3]
        local hasStock    = expQty > 0

        local btn = AcquireButton(contentFrame)
        btn:SetHeight(BTN_H)
        btn:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  BTN_PAD, curY)
        btn:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -BTN_PAD, curY)
        btn:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })

        if hasStock then
            btn:SetBackdropColor(cr*0.18, cg*0.18, cb*0.18, 1)
            btn:SetBackdropBorderColor(cr*0.65, cg*0.65, cb*0.65, 1)
            btn._nameFs:SetTextColor(cr*0.80+0.20, cg*0.80+0.20, cb*0.80+0.20)
            local col = expQty >= 200 and "|cff00ff00" or expQty >= 50 and "|cffffff00" or "|cffff8060"
            btn._qtyFs:SetText(col .. expQty .. "|r")
        else
            btn:SetBackdropColor(0.08, 0.08, 0.08, 1)
            btn:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
            btn._nameFs:SetTextColor(0.30, 0.30, 0.30)
            btn._qtyFs:SetText("|cff2a2a2a0|r")
        end
        btn._nameFs:SetText(core.L(expBlock.expansionKey))

        local capBlock, capDetail, capStock = expBlock, woodDetail, hasStock
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(capStock and cr*0.28 or 0.14, capStock and cg*0.28 or 0.14, capStock and cb*0.28 or 0.14, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
            GameTooltip:AddLine("|cffffd700"..core.L(capBlock.expansionKey).."|r"); GameTooltip:AddLine(" ")
            for _, item in ipairs(capBlock.items) do
                local qty = capDetail[item.id] or 0
                GameTooltip:AddDoubleLine("|cffccaa60"..item.name.."|r", (qty>0 and "|cffffffff" or "|cff555555")..qty.."|r", 1,1,1,1,1,1)
            end
            if not capStock then GameTooltip:AddLine(" "); GameTooltip:AddLine(core.L("WOOD_OPEN_WARBAND")) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(capStock and cr*0.18 or 0.08, capStock and cg*0.18 or 0.08, capStock and cb*0.18 or 0.08, 1)
            GameTooltip:Hide()
        end)

        activeBtns[#activeBtns + 1] = btn
        curY = curY - BTN_H - BTN_GAP
    end

    local totalH = math_abs(curY) + 14
    panel:SetHeight(math_max(totalH, 80))
    contentFrame:SetHeight(totalH)
end


-- ====================================================
-- POSITIONNEMENT — collé à droite de ProfessionsFrame
-- La hauteur est déterminée par le contenu (boutons)
-- ====================================================
local function RepositionPanel()
    if not ProfessionsFrame then return end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 4, 0)
    panel:SetWidth(PANEL_W)
end

local function IsWoodPanelEnabled()
    return ProfessionViewerLogDB.woodPanelEnabled ~= false  -- true par défaut
end

local function ShowPanel()
    if not ProfessionsFrame or not ProfessionsFrame:IsShown() then return end
    if not IsWoodPanelEnabled() then return end
    RepositionPanel()
    RebuildContent(true)  -- rebuild complet : langue / données fraîches
    panel:Show()
end

local function HidePanel()
    panel:Hide()
end

-- ====================================================
-- BOUTON TOGGLE DANS ProfessionsFrame (UI Blizzard)
-- ====================================================
local toggleBtn = nil

local function UpdateToggleBtn()
    if not toggleBtn then return end
    -- Actif : logo pleine opacité ; masqué : logo semi-transparent
    if IsWoodPanelEnabled() then
        toggleBtn.logoTex:SetVertexColor(1, 1, 1, 1)
    else
        toggleBtn.logoTex:SetVertexColor(0.4, 0.4, 0.4, 0.55)
    end
end

local function CreateToggleButton()
    if toggleBtn then return end
    if not ProfessionsFrame then return end

    toggleBtn = CreateFrame("Button", "PVLWoodToggleBtn", ProfessionsFrame)
    toggleBtn:SetSize(22, 22)
    -- Ancré à gauche du bouton MaximizeMinimize, dans la barre de titre (comme BagViewerLog)
    if ProfessionsFrame.MaximizeMinimize then
        toggleBtn:SetPoint("RIGHT", ProfessionsFrame.MaximizeMinimize, "LEFT", -4, 0)
    else
        toggleBtn:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPRIGHT", -115, -4)
    end
    -- IMPORTANT : FrameStrata + FrameLevel élevés pour passer au-dessus des éléments Blizzard
    toggleBtn:SetFrameStrata("HIGH")
    toggleBtn:SetFrameLevel(ProfessionsFrame:GetFrameLevel() + 20)

    -- Logo de l'addon comme icône du bouton
    local logoTex = toggleBtn:CreateTexture(nil, "ARTWORK")
    logoTex:SetAllPoints()
    logoTex:SetTexture("Interface\\AddOns\\ProfessionViewerLog\\PVL.blp")
    toggleBtn.logoTex = logoTex

    toggleBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffd700ProfessionViewerLog|r")
        if IsWoodPanelEnabled() then
            GameTooltip:AddLine("|cffaaaaaaCliquez pour masquer la barre de bois|r")
        else
            GameTooltip:AddLine("|cffaaaaaaCliquez pour afficher la barre de bois|r")
        end
        GameTooltip:Show()
    end)
    toggleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    toggleBtn:SetScript("OnClick", function()
        ProfessionViewerLogDB.woodPanelEnabled = not IsWoodPanelEnabled()
        UpdateToggleBtn()
        if IsWoodPanelEnabled() then
            ShowPanel()
        else
            HidePanel()
        end
    end)

    UpdateToggleBtn()
end

-- ====================================================
-- HOOKS SUR ProfessionsFrame (chargé à la demande)
-- ====================================================
local function HookProfessionsFrame()
    if not ProfessionsFrame then return false end

    CreateToggleButton()

    ProfessionsFrame:HookScript("OnShow", function()
        UpdateToggleBtn()
        C_Timer.After(0.05, ShowPanel)
    end)
    ProfessionsFrame:HookScript("OnHide", HidePanel)

    -- Si la fenêtre est déjà ouverte au chargement de l'addon
    if ProfessionsFrame:IsShown() then
        C_Timer.After(0.1, ShowPanel)
    end
    return true
end

-- L'addon Blizzard_Professions est chargé à la demande (quand on ouvre la fenêtre).
-- ProfessionsFrame est nil jusqu'à ce chargement → on écoute ADDON_LOADED avec arg1 exact.
local hookDone = false
local hookWatcher = CreateFrame("Frame")
hookWatcher:RegisterEvent("ADDON_LOADED")
hookWatcher:SetScript("OnEvent", function(self, event, arg1)
    if hookDone then return end
    -- Cas 1 : Blizzard_Professions vient de se charger
    if arg1 == "Blizzard_Professions" then
        C_Timer.After(0.2, function()
            if HookProfessionsFrame() then
                hookDone = true
                self:UnregisterAllEvents()
            end
        end)
        return
    end
    -- Cas 2 : déjà chargé au moment du login (rare)
    if ProfessionsFrame and HookProfessionsFrame() then
        hookDone = true
        self:UnregisterAllEvents()
    end
end)
