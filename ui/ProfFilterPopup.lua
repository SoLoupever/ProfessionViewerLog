local addonName, ns = ...
local pluginNs = ns
local core     = ns.core

-- ====================================================
-- FILTRE MÉTIERS — popup "show / hide professions"
-- S'ancre à droite du bouton filterBtn (extensions)
-- et se ferme automatiquement comme lui.
-- ====================================================

local profFilterPopup = nil

-- Échap ferme automatiquement toute frame listée ici, par son nom global.
-- _G["PVLProfFilterPopup"] est résolu dynamiquement à chaque pression d'Échap,
-- ce qui reste valide même si BuildProfFilterPopup recrée la frame plus tard.
tinsert(UISpecialFrames, "PVLProfFilterPopup")

-- ────────────────────────────────────────────────────
-- Retourne la liste canonique de tous les métiers
-- connus dans la DB (union de tous les personnages).
-- ────────────────────────────────────────────────────
local function CollectKnownProfessionNames()
    local seen  = {}
    local names = {}
    if not ProfessionViewerLogDB then return names end
    for realmName, realmData in pairs(ProfessionViewerLogDB) do
        if type(realmData) == "table"
        and realmName ~= "minimap"
        and realmName ~= "warbandBank"
        and realmName ~= "settings"
        and realmName ~= "hiddenExpansions"
        and realmName ~= "hiddenProfessions"
        and realmName ~= "lang"
        and realmName ~= "disable2DPreview"
        and realmName ~= "debugVerbose" then
            for _, charData in pairs(realmData) do
                if type(charData) == "table" and charData.professions then
                    for _, p in ipairs(charData.professions) do
                        if p.name and not seen[p.name] then
                            seen[p.name] = true
                            names[#names + 1] = p.name
                        end
                    end
                end
            end
        end
    end
    table.sort(names)
    return names
end

-- ────────────────────────────────────────────────────
-- Crée (ou recrée) la popup
-- ────────────────────────────────────────────────────
local function BuildProfFilterPopup()
    -- Détruire l'ancienne instance si elle existe
    -- (la liste de métiers peut avoir changé)
    if profFilterPopup then
        profFilterPopup:Hide()
        profFilterPopup = nil
        ns.profFilterPopup = nil
    end

    local names  = CollectKnownProfessionNames()
    local ITEM_H = 22
    local popH   = 50 + #names * ITEM_H + 40

    local pop = CreateFrame("Frame", "PVLProfFilterPopup", UIParent, "BackdropTemplate")
    pop:SetFrameStrata("DIALOG")
    pop:SetMovable(true); pop:EnableMouse(true)
    pop:RegisterForDrag("LeftButton")
    pop:SetScript("OnDragStart", pop.StartMoving)
    pop:SetScript("OnDragStop",  pop.StopMovingOrSizing)
    core.Skin.Frame(pop, "window")
    pop:SetSize(260, math.max(popH, 90))
    pop:Hide()

    -- Titre
    local titleFS = pop:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFS:SetPoint("TOP", 0, -12)
    titleFS:SetText(core.L("PROF_FILTER_POPUP_TITLE"))
    titleFS:SetTextColor(unpack(core.Theme.heading))

    local sep = pop:CreateTexture(nil, "ARTWORK")
    sep:SetSize(220, 1); sep:SetPoint("TOP", 0, -32)
    sep:SetColorTexture(core.Theme.heading[1], core.Theme.heading[2], core.Theme.heading[3], 0.25)

    -- Message vide
    if #names == 0 then
        local emptyFS = pop:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        emptyFS:SetPoint("CENTER", 0, 0)
        emptyFS:SetText(core.L("NO_CHARS"))
        emptyFS:SetTextColor(0.4, 0.4, 0.4)
        profFilterPopup = pop
        ns.profFilterPopup = pop
        return pop
    end

    -- Lignes une par métier
    local rows = {}
    for i, profName in ipairs(names) do
        local baseID = pluginNs.PROFESSION_BASE_IDS and pluginNs.PROFESSION_BASE_IDS[profName]
        -- Couleur neutre (bleu clair) — les métiers n'ont pas de couleur par extension
        local cr, cg, cb = 0.70, 0.85, 1.0

        local row = CreateFrame("Frame", nil, pop)
        row:SetSize(230, ITEM_H)
        row:SetPoint("TOPLEFT", 14, -40 - (i - 1) * ITEM_H)

        local dot = row:CreateTexture(nil, "ARTWORK")
        dot:SetSize(8, 8); dot:SetPoint("LEFT", 0, 0)
        dot:SetColorTexture(cr, cg, cb, 1)

        local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameFS:SetPoint("LEFT", 16, 0); nameFS:SetWidth(155); nameFS:SetJustifyH("LEFT")
        nameFS:SetTextColor(cr * 0.9, cg * 0.9, cb * 0.9)
        nameFS:SetText(profName)

        local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
        btn:SetSize(38, 16); btn:SetPoint("RIGHT", 0, 0)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })

        local btnLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnLabel:SetPoint("CENTER", 0, 0)

        local cName = profName
        local cDot  = dot
        local cFS   = nameFS

        local function RefreshRow()
            ProfessionViewerLogDB.hiddenProfessions = ProfessionViewerLogDB.hiddenProfessions or {}
            local hidden = ProfessionViewerLogDB.hiddenProfessions[cName]
            if hidden then
                btn:SetBackdropColor(0.25, 0.06, 0.06, 1)
                btn:SetBackdropBorderColor(0.55, 0.10, 0.10, 1)
                btnLabel:SetText("|cffff6666OFF|r")
                cDot:SetColorTexture(0.30, 0.30, 0.35, 0.5)
                cFS:SetTextColor(0.30, 0.30, 0.30)
            else
                btn:SetBackdropColor(0.06, 0.22, 0.06, 1)
                btn:SetBackdropBorderColor(0.15, 0.50, 0.15, 1)
                btnLabel:SetText("|cff55ff55ON |r")
                cDot:SetColorTexture(cr, cg, cb, 1)
                cFS:SetTextColor(cr * 0.9, cg * 0.9, cb * 0.9)
            end
        end
        row.RefreshRow = RefreshRow
        rows[#rows + 1] = row

        btn:SetScript("OnClick", function()
            ProfessionViewerLogDB.hiddenProfessions = ProfessionViewerLogDB.hiddenProfessions or {}
            local hidden = ProfessionViewerLogDB.hiddenProfessions[cName]
            ProfessionViewerLogDB.hiddenProfessions[cName] = (not hidden) or nil
            RefreshRow()
            if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
                pluginNs.InvalidateProfsHash()   -- force rebuild immédiat
                pluginNs.ShowProfessions()
            end
        end)
        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 1) end)
        btn:SetScript("OnLeave", function() RefreshRow() end)
    end
    pop.rows = rows

    -- Bouton "Tout afficher"
    local showAllBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    showAllBtn:SetSize(100, 20); showAllBtn:SetPoint("BOTTOMLEFT", 14, 12)
    core.Skin.Button(showAllBtn, "button")
    local showAllLbl = showAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    showAllLbl:SetPoint("CENTER"); showAllLbl:SetText(core.L("PROF_FILTER_SHOW_ALL"))
    showAllBtn:SetScript("OnClick", function()
        ProfessionViewerLogDB.hiddenProfessions = {}
        for _, row in ipairs(rows) do row.RefreshRow() end
        if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
            pluginNs.InvalidateProfsHash()
            pluginNs.ShowProfessions()
        end
    end)

    -- Bouton "Tout masquer"
    local hideAllBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    hideAllBtn:SetSize(100, 20); hideAllBtn:SetPoint("BOTTOMRIGHT", -14, 12)
    core.Skin.Button(hideAllBtn, "button")
    local hideAllLbl = hideAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hideAllLbl:SetPoint("CENTER"); hideAllLbl:SetText(core.L("PROF_FILTER_HIDE_ALL"))
    hideAllBtn:SetScript("OnClick", function()
        ProfessionViewerLogDB.hiddenProfessions = ProfessionViewerLogDB.hiddenProfessions or {}
        for _, name in ipairs(names) do
            ProfessionViewerLogDB.hiddenProfessions[name] = true
        end
        for _, row in ipairs(rows) do row.RefreshRow() end
        if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
            pluginNs.InvalidateProfsHash()
            pluginNs.ShowProfessions()
        end
    end)

    profFilterPopup = pop
    ns.profFilterPopup = pop
    return pop
end

-- ────────────────────────────────────────────────────
-- Toggle public — appelé par le bouton dans View.lua
-- ────────────────────────────────────────────────────
function pluginNs.ToggleProfFilterPopup(anchorFrame)
    -- Toujours reconstruire pour refléter les métiers actuels
    if profFilterPopup and profFilterPopup:IsShown() then
        profFilterPopup:Hide()
        return
    end

    local pop = BuildProfFilterPopup()
    ProfessionViewerLogDB.hiddenProfessions = ProfessionViewerLogDB.hiddenProfessions or {}
    if pop.rows then
        for _, row in ipairs(pop.rows) do row.RefreshRow() end
    end
    pop:ClearAllPoints()
    pop:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -4)
    pop:Show()
end

-- ────────────────────────────────────────────────────
-- Helper utilisé par View.lua pour masquer un métier
-- ────────────────────────────────────────────────────
function pluginNs.IsProfessionHidden(profName)
    if not ProfessionViewerLogDB or not ProfessionViewerLogDB.hiddenProfessions then return false end
    return ProfessionViewerLogDB.hiddenProfessions[profName] == true
end
