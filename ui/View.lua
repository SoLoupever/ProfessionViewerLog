local addonName, ns = ...
local pluginNs = ns
local core     = ns.core

-- Cache globals fréquents
local pairs, ipairs, next, math_min, math_max = pairs, ipairs, next, math.min, math.max
local string_format, table_concat, table_sort = string.format, table.concat, table.sort

local function GetProfDisplayName(name)
    if not name then return name end
    local lang = ProfessionViewerLogDB and ProfessionViewerLogDB.lang
    if lang == "enUS" and pluginNs.PROF_EN_NAME then
        local en = pluginNs.PROF_EN_NAME[name]
        if en then return en end
        local key = pluginNs.PROF_RECIPE_KEY and pluginNs.PROF_RECIPE_KEY[name]
        if key then return pluginNs.PROF_EN_NAME[key] or name end
    elseif lang == "frFR" and pluginNs.PROF_FR_NAME then
        local fr = pluginNs.PROF_FR_NAME[name]
        if fr then return fr end
    end
    return name
end

pluginNs.isViewActive  = false
pluginNs.recipeExpanded = pluginNs.recipeExpanded or {}

local function recipeKey(realm, char, prof)
    return realm .. "||" .. char .. "||" .. prof
end

-- ====================================================
-- POPUP FILTRE DES EXTENSIONS (GetOrCreate — déjà optimisé)
-- ====================================================
local expansionFilterPopup = nil

-- Échap ferme automatiquement toute frame listée ici, par son nom global.
-- _G["PVLExpansionFilterPopup"] est résolu dynamiquement à chaque pression
-- d'Échap, donc l'enregistrement n'a besoin d'être fait qu'une seule fois.
tinsert(UISpecialFrames, "PVLExpansionFilterPopup")

local function GetOrCreateExpansionFilterPopup()
    if expansionFilterPopup then return expansionFilterPopup end

    local pop = CreateFrame("Frame", "PVLExpansionFilterPopup", UIParent, "BackdropTemplate")
    pop:SetFrameStrata("DIALOG")
    pop:SetMovable(true); pop:EnableMouse(true)
    pop:RegisterForDrag("LeftButton")
    pop:SetScript("OnDragStart", pop.StartMoving)
    pop:SetScript("OnDragStop",  pop.StopMovingOrSizing)
    core.Skin.Frame(pop, "window")
    pop:Hide()

    local titleFS = pop:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFS:SetPoint("TOP", 0, -12)
    titleFS:SetText(core.L("FILTER_POPUP_TITLE"))
    titleFS:SetTextColor(1, 0.85, 0.20)

    local sep = pop:CreateTexture(nil, "ARTWORK")
    sep:SetSize(220, 1); sep:SetPoint("TOP", 0, -32)
    sep:SetColorTexture(1, 0.82, 0, 0.25)

    local ITEM_H = 22
    local rows   = {}

    for i, exp in ipairs(pluginNs.EXPANSION_LIST) do
        local color = pluginNs.GetTierColor(exp.name)
        local row   = CreateFrame("Frame", nil, pop)
        row:SetSize(230, ITEM_H)
        row:SetPoint("TOPLEFT", 14, -40 - (i - 1) * ITEM_H)

        local dot = row:CreateTexture(nil, "ARTWORK")
        dot:SetSize(8, 8); dot:SetPoint("LEFT", 0, 0)
        dot:SetColorTexture(color.r, color.g, color.b, 1)

        local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameFS:SetPoint("LEFT", 16, 0); nameFS:SetWidth(150); nameFS:SetJustifyH("LEFT")
        nameFS:SetTextColor(color.r * 0.9, color.g * 0.9, color.b * 0.9)
        nameFS:SetText(exp.name)

        local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
        btn:SetSize(38, 16); btn:SetPoint("RIGHT", 0, 0)
        btn:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8",
                          edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })

        local btnLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnLabel:SetPoint("CENTER", 0, 0)

        local cN, cC, cD, cL = exp.name, color, dot, nameFS

        local function RefreshRow()
            ProfessionViewerLogDB.hiddenExpansions = ProfessionViewerLogDB.hiddenExpansions or {}
            local hidden = ProfessionViewerLogDB.hiddenExpansions[cN]
            if hidden then
                btn:SetBackdropColor(0.25, 0.06, 0.06, 1); btn:SetBackdropBorderColor(0.55, 0.10, 0.10, 1)
                btnLabel:SetText("|cffff6666OFF|r")
                cD:SetColorTexture(cC.r*0.3, cC.g*0.3, cC.b*0.3, 0.5); cL:SetTextColor(0.30, 0.30, 0.30)
            else
                btn:SetBackdropColor(0.06, 0.22, 0.06, 1); btn:SetBackdropBorderColor(0.15, 0.50, 0.15, 1)
                btnLabel:SetText("|cff55ff55ON |r")
                cD:SetColorTexture(cC.r, cC.g, cC.b, 1)
                cL:SetTextColor(cC.r * 0.9, cC.g * 0.9, cC.b * 0.9)
            end
        end
        row.RefreshRow = RefreshRow; rows[#rows+1] = row

        btn:SetScript("OnClick", function()
            ProfessionViewerLogDB.hiddenExpansions = ProfessionViewerLogDB.hiddenExpansions or {}
            local hidden = ProfessionViewerLogDB.hiddenExpansions[cN]
            ProfessionViewerLogDB.hiddenExpansions[cN] = (not hidden) or nil
            RefreshRow()
            if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
                pluginNs.ShowProfessions()
            end
        end)
        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 1) end)
        btn:SetScript("OnLeave", function() RefreshRow() end)
    end

    local showAllBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    showAllBtn:SetSize(100, 20); showAllBtn:SetPoint("BOTTOMLEFT", 14, 12)
    core.Skin.Button(showAllBtn, "button")
    local showAllLbl = showAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    showAllLbl:SetPoint("CENTER"); showAllLbl:SetText(core.L("PROF_FILTER_SHOW_ALL"))
    showAllBtn:SetScript("OnClick", function()
        ProfessionViewerLogDB.hiddenExpansions = {}
        for _, row in ipairs(rows) do row.RefreshRow() end
        if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
            pluginNs.ShowProfessions()
        end
    end)

    local closeBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    closeBtn:SetSize(60, 20); closeBtn:SetPoint("BOTTOMRIGHT", -14, 12)
    core.Skin.Button(closeBtn, "button")
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeLbl:SetPoint("CENTER"); closeLbl:SetText(core.L("BTN_CLOSE"))
    closeBtn:SetScript("OnClick", function() pop:Hide() end)

    pop:SetSize(260, 50 + #pluginNs.EXPANSION_LIST * ITEM_H + 40)
    pop.rows = rows
    expansionFilterPopup = pop
    ns.expansionFilterPopup = pop
    return pop
end

local function ToggleExpansionFilterPopup(anchorFrame)
    local pop = GetOrCreateExpansionFilterPopup()
    if pop:IsShown() then pop:Hide()
    else
        ProfessionViewerLogDB.hiddenExpansions = ProfessionViewerLogDB.hiddenExpansions or {}
        for _, row in ipairs(pop.rows) do row.RefreshRow() end
        pop:ClearAllPoints()
        pop:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -4)
        pop:Show()
    end
end

local function IsExpansionHidden(tierName)
    if not ProfessionViewerLogDB or not ProfessionViewerLogDB.hiddenExpansions then return false end
    for expName, hidden in pairs(ProfessionViewerLogDB.hiddenExpansions) do
        if hidden and tierName and tierName:find(expName, 1, true) then return true end
    end
    return false
end

-- ====================================================
-- POOL DE WIDGETS — réutilisation complète entre rebuilds
-- ====================================================
local _pool    = {}   -- poolType → { Frame, … }
local _active  = {}   -- { f=Frame, k=string }
local _trashV  = CreateFrame("Frame", nil, UIParent); _trashV:Hide()

local function Acquire(kind, parent, createFn)
    local b = _pool[kind]
    local f
    if b and b[1] then
        f = b[#b]; b[#b] = nil
        f:SetParent(parent); f:ClearAllPoints(); f:Show()
    else
        f = createFn(parent)
    end
    _active[#_active+1] = { f=f, k=kind }
    return f
end

local function ReleaseAll()
    for i = #_active, 1, -1 do
        local e = _active[i]
        e.f:ClearAllPoints(); e.f:SetParent(_trashV); e.f:Hide()
        local b = _pool[e.k]; if not b then b={}; _pool[e.k]=b end
        b[#b+1] = e.f; _active[i] = nil
    end
end

-- Fonctions de création (appelées uniquement quand le pool est vide)
local function NewWoodTitle(p)
    local f = CreateFrame("Frame", nil, p)
    f.titleFS = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.titleFS:SetPoint("TOPLEFT"); return f
end

local function NewWoodBtn(p)
    local b = CreateFrame("Button", nil, p, "BackdropTemplate")
    b.nameFs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.nameFs:SetPoint("TOPLEFT", 4,-6); b.nameFs:SetPoint("TOPRIGHT", -4,-6)
    b.nameFs:SetJustifyH("CENTER"); b.nameFs:SetWordWrap(false)
    b.qtyFs  = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.qtyFs:SetPoint("BOTTOM", 0, 5); return b
end

local function NewSepLine(p)
    local f = CreateFrame("Frame", nil, p)
    f.line = f:CreateTexture(nil, "ARTWORK"); f.line:SetAllPoints(); return f
end

local function NewCharBlock(p)
    local f = CreateFrame("Frame", nil, p, "BackdropTemplate")
    f:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8" })
    f.charLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.charLabel:SetPoint("LEFT", 14, 0)
    f.lvlFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.lvlFS:SetPoint("RIGHT", -14, 0); return f
end

local CARD_PAD = 12

local function NewProfCard(p)
    local f = CreateFrame("Frame", nil, p, "BackdropTemplate")
    core.Skin.Frame(f, "card")
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(34, 34); f.icon:SetPoint("TOPLEFT", CARD_PAD, -CARD_PAD)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.nameFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.nameFS:SetPoint("LEFT", f.icon, "RIGHT", 10, 0)
    return f
end

local function NewTierBar(p)
    local f = CreateFrame("Frame", nil, p, "BackdropTemplate")
    core.Skin.Frame(f, "input")
    f.fill = f:CreateTexture(nil, "ARTWORK")
    f.fill:SetPoint("TOPLEFT", 1,-1); f.fill:SetPoint("BOTTOMLEFT", 1, 1)
    f.nameFS = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.nameFS:SetPoint("LEFT", 8, 0); f.nameFS:SetPoint("RIGHT", -56, 0)
    f.nameFS:SetJustifyH("LEFT"); f.nameFS:SetWordWrap(false)
    f.rankFS = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rankFS:SetPoint("RIGHT", -8, 0); f.rankFS:SetJustifyH("RIGHT"); return f
end

local function NewRecipeToggle(p)
    local b = CreateFrame("Button", nil, p, "BackdropTemplate")
    core.Skin.Button(b, "bar")
    b.arrowTex = b:CreateTexture(nil, "OVERLAY"); b.arrowTex:SetSize(14,14); b.arrowTex:SetPoint("LEFT", 6, 0)
    b.recipeFS = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.recipeFS:SetPoint("LEFT", 24, 0)
    b.miniBarBg = b:CreateTexture(nil, "BACKGROUND")
    b.miniBarBg:SetSize(50,4); b.miniBarBg:SetPoint("RIGHT", -8, 0)
    b.miniBarFill = b:CreateTexture(nil, "ARTWORK")
    b.miniBarFill:SetPoint("LEFT", b.miniBarBg, "LEFT"); return b
end

-- ====================================================
-- HASH — détermine si un rebuild est nécessaire
-- ====================================================
local _profsHash       = nil
local _profsScrollChild = nil

-- Expose pour invalidation externe (ProfFilterPopup, etc.)
function pluginNs.InvalidateProfsHash()
    _profsHash = nil
    _profsScrollChild = nil
end

local function ComputeHash(contentW)
    if not ProfessionViewerLogDB then return "0" end
    local p = { tostring(contentW), core.Theme.key }
    local _, wd = pluginNs.GetWoodCounts()
    local wh = 0
    for id, qty in pairs(wd) do wh = wh + id * 31 + qty end
    p[#p+1] = tostring(wh)
    local hx = ProfessionViewerLogDB.hiddenExpansions
    if hx then for k, v in pairs(hx) do if v then p[#p+1] = k end end end
    local hp = ProfessionViewerLogDB.hiddenProfessions
    if hp then for k, v in pairs(hp) do if v then p[#p+1] = "hp:"..k end end end
    for realm, rd in pairs(ProfessionViewerLogDB) do
        if type(rd) == "table" then
            for char, cd in pairs(rd) do
                if type(cd) == "table" and cd.class and cd.professions then
                    p[#p+1] = char..realm..(cd.class or "")
                    for _, pr in ipairs(cd.professions) do
                        p[#p+1] = pr.name
                        for _, t in ipairs(pr.tiers or {}) do
                            p[#p+1] = tostring((t.level or 0) + (t.max or 0) * 10000)
                        end
                    end
                end
            end
        end
    end
    return table_concat(p, "|")
end

-- ====================================================
-- AFFICHAGE PRINCIPAL
-- ====================================================
function pluginNs.ShowProfessions()
    pluginNs.isViewActive = true

    -- ── Hash check : skip si données et taille identiques ──
    local contentW = core.GetContentWidth()
    local newHash  = ComputeHash(contentW)
    if newHash == _profsHash and core.scrollChild == _profsScrollChild and _profsScrollChild ~= nil then
        return
    end
    _profsHash = newHash

    -- ── Reset pool + clear ──────────────────────────────
    ReleaseAll()
    core.ClearContent()
    _profsScrollChild = core.scrollChild

    local sc = core.scrollChild
    if not ProfessionViewerLogDB then return end

    -- ── Header (titre + scan + filtre) — 3 objets, pas de pool ──
    local PADX = 16
    local title = sc:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", PADX, -14)
    title:SetText(core.L("BTN_PROFESSIONS")); title:SetTextColor(unpack(core.Theme.heading))

    local scanBtn = CreateFrame("Button", nil, sc, "BackdropTemplate")
    scanBtn:SetSize(150, 22); scanBtn:SetPoint("LEFT", title, "RIGHT", 15, 0)
    scanBtn:SetText(core.L("SCAN_BTN")); scanBtn:SetNormalFontObject("GameFontNormalSmall")
    core.Skin.Button(scanBtn, "button")
    scanBtn:SetScript("OnClick", pluginNs.ScanAllProfessions)

    local filterBtn = CreateFrame("Button", nil, sc, "BackdropTemplate")
    filterBtn:SetSize(22, 22); filterBtn:SetPoint("LEFT", scanBtn, "RIGHT", 6, 0)
    core.Skin.Button(filterBtn, "button")
    local gearTex = filterBtn:CreateTexture(nil, "ARTWORK")
    gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearTex:SetSize(16, 16); gearTex:SetPoint("CENTER"); gearTex:SetVertexColor(0.95, 0.82, 0.40)
    filterBtn:HookScript("OnEnter", function(self)
        gearTex:SetVertexColor(1, 1, 0.7)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(core.L("FILTER_TOOLTIP"), 1, 0.85, 0.20); GameTooltip:Show()
    end)
    filterBtn:HookScript("OnLeave", function(self)
        gearTex:SetVertexColor(0.95, 0.82, 0.40); GameTooltip:Hide()
    end)
    filterBtn:SetScript("OnClick", function(self)
        -- Fermer l'autre popup si ouverte
        if ns.profFilterPopup and ns.profFilterPopup:IsShown() then
            ns.profFilterPopup:Hide()
        end
        ToggleExpansionFilterPopup(self)
    end)

    -- ── Bouton filtre métiers (à droite du filtre extensions) ──
    local profFilterBtn = CreateFrame("Button", nil, sc, "BackdropTemplate")
    profFilterBtn:SetSize(22, 22); profFilterBtn:SetPoint("LEFT", filterBtn, "RIGHT", 6, 0)
    core.Skin.Button(profFilterBtn, "button")
    local profFilterTex = profFilterBtn:CreateTexture(nil, "ARTWORK")
    profFilterTex:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
    profFilterTex:SetSize(16, 16); profFilterTex:SetPoint("CENTER")
    profFilterTex:SetVertexColor(0.95, 0.82, 0.40)
    profFilterBtn:HookScript("OnEnter", function(self)
        profFilterTex:SetVertexColor(0.80, 1.0, 1.0)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(core.L("PROF_FILTER_TOOLTIP"), 1, 0.85, 0.20); GameTooltip:Show()
    end)
    profFilterBtn:HookScript("OnLeave", function(self)
        profFilterTex:SetVertexColor(0.95, 0.82, 0.40); GameTooltip:Hide()
    end)
    profFilterBtn:SetScript("OnClick", function(self)
        -- Fermer l'autre popup si ouverte
        if ns.expansionFilterPopup and ns.expansionFilterPopup:IsShown() then
            ns.expansionFilterPopup:Hide()
        end
        pluginNs.ToggleProfFilterPopup(self)
    end)
    -- Indiquer visuellement si des métiers sont filtrés
    local function RefreshProfFilterBtnState()
        local hasHidden = false
        if ProfessionViewerLogDB and ProfessionViewerLogDB.hiddenProfessions then
            for _, v in pairs(ProfessionViewerLogDB.hiddenProfessions) do
                if v then hasHidden = true; break end
            end
        end
        if hasHidden then
            profFilterTex:SetVertexColor(1.0, 0.75, 0.35)
        else
            profFilterTex:SetVertexColor(0.95, 0.82, 0.40)
        end
    end
    RefreshProfFilterBtnState()

    -- ── Section bois — pool ──────────────────────────────
    local _, woodDetail = pluginNs.GetWoodCounts()
    local BTN_GAP = 4; local BTN_H_W = 44; local AREA_LEFT = PADX; local AREA_RIGHT = contentW - PADX
    local usableW = AREA_RIGHT - AREA_LEFT
    local N_PER_ROW = 1
    for n = 7, 2, -1 do
        if math_max(math.floor((usableW-(n-1)*BTN_GAP)/n), 0) >= 65 then N_PER_ROW = n; break end
    end
    local BTN_W = math.floor((usableW - (N_PER_ROW-1)*BTN_GAP) / N_PER_ROW)
    local START_Y = -52

    local wt = Acquire("woodTitle", sc, NewWoodTitle)
    wt:SetSize(300, 16); wt:SetPoint("TOPLEFT", AREA_LEFT, START_Y)
    wt.titleFS:SetText("|cffcca060" .. core.L("WOOD_SECTION_TITLE") .. "|r")

    local curX = AREA_LEFT; local curY = START_Y - 18; local colIdx = 0

    for _, expBlock in ipairs(pluginNs.WOOD_BY_EXPANSION) do
        if colIdx > 0 and colIdx % N_PER_ROW == 0 then curX = AREA_LEFT; curY = curY - BTN_H_W - BTN_GAP end
        local expQty = 0
        for _, item in ipairs(expBlock.items) do expQty = expQty + (woodDetail[item.id] or 0) end
        local cr, cg, cb = expBlock.color[1], expBlock.color[2], expBlock.color[3]
        local hasStock = expQty > 0

        local btn = Acquire("woodBtn", sc, NewWoodBtn)
        btn:SetSize(BTN_W, BTN_H_W); btn:SetPoint("TOPLEFT", curX, curY)
        btn:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8",
                          edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
        if hasStock then
            btn:SetBackdropColor(cr*0.28, cg*0.28, cb*0.28, 1)
            btn:SetBackdropBorderColor(cr*0.85, cg*0.85, cb*0.85, 1)
            btn.nameFs:SetTextColor(math_min(cr*0.70+0.38,1), math_min(cg*0.70+0.38,1), math_min(cb*0.70+0.38,1))
            local col = expQty>=200 and "|cff55ff55" or expQty>=50 and "|cffffff55" or "|cffff8855"
            btn.qtyFs:SetText(col..expQty.."|r")
        else
            btn:SetBackdropColor(0.09, 0.09, 0.09, 1); btn:SetBackdropBorderColor(0.22, 0.22, 0.22, 1)
            btn.nameFs:SetTextColor(0.30, 0.30, 0.30); btn.qtyFs:SetText("|cff252525".."0".."|r")
        end
        btn.nameFs:SetText(core.L(expBlock.expansionKey))

        local cEB, cWD, cHS = expBlock, woodDetail, hasStock
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(cHS and cr*0.42 or 0.16, cHS and cg*0.42 or 0.16, cHS and cb*0.42 or 0.16, 1)
            self:SetBackdropBorderColor(cHS and math_min(cr,1) or 0.35, cHS and math_min(cg,1) or 0.35, cHS and math_min(cb,1) or 0.35, 1)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:ClearLines()
            GameTooltip:AddLine("|cffffd700"..core.L(cEB.expansionKey).."|r"); GameTooltip:AddLine(" ")
            for _, item in ipairs(cEB.items) do
                local qty = cWD[item.id] or 0
                GameTooltip:AddDoubleLine("|cffccaa60"..item.name.."|r",
                    (qty>0 and "|cffffffff" or "|cff555555")..qty.."|r", 1,1,1,1,1,1)
            end
            if not cHS then GameTooltip:AddLine(" "); GameTooltip:AddLine(core.L("WOOD_OPEN_WARBAND")) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(cHS and cr*0.28 or 0.09, cHS and cg*0.28 or 0.09, cHS and cb*0.28 or 0.09, 1)
            self:SetBackdropBorderColor(cHS and cr*0.85 or 0.22, cHS and cg*0.85 or 0.22, cHS and cb*0.85 or 0.22, 1)
            GameTooltip:Hide()
        end)
        curX = curX + BTN_W + BTN_GAP; colIdx = colIdx + 1
    end

    local woodSectionBottomY = curY - BTN_H_W - 10

    local mainSep = Acquire("sepLine", sc, NewSepLine)
    mainSep:SetSize(contentW - PADX * 2, 1); mainSep:SetPoint("TOPLEFT", PADX, woodSectionBottomY)
    mainSep.line:SetColorTexture(core.Theme.heading[1], core.Theme.heading[2], core.Theme.heading[3], 0.3)

    -- ── Collecte et tri des personnages ──────────────────
    local charList = {}
    for realmName, realmData in pairs(ProfessionViewerLogDB) do
        if type(realmData) == "table" then
            for charName, charData in pairs(realmData) do
                if type(charData) == "table" and charData.class and charData.professions and #charData.professions > 0 then
                    charList[#charList+1] = { realm=realmName, name=charName, data=charData }
                end
            end
        end
    end
    table.sort(charList, function(a, b)
        local ai = (a.name==core.player and a.realm==core.realm)
        local bi = (b.name==core.player and b.realm==core.realm)
        if ai ~= bi then return ai end
        if a.realm == b.realm then return a.name < b.name end
        return a.realm < b.realm
    end)

    if #charList == 0 then
        local hint = sc:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        hint:SetPoint("TOP", 0, -120); hint:SetText(core.L("NO_CHARS")); hint:SetJustifyH("CENTER")
        sc:SetHeight(200); return
    end

    -- ── Grille de cartes métier (2 colonnes, 1 si l'espace manque) ──
    local GAP, BAR_H = 14, 22
    local ncols = 2
    local cardW = math.floor((contentW - PADX * 2 - GAP) / 2)
    if cardW < 300 then ncols = 1; cardW = contentW - PADX * 2 end
    local innerW = cardW - CARD_PAD * 2
    local T = core.Theme

    local offsetY = woodSectionBottomY - 16

    for _, entry in ipairs(charList) do
        local charName = entry.name; local realmName = entry.realm; local charData = entry.data
        local isCurrent = (charName == core.player and realmName == core.realm)
        local c = RAID_CLASS_COLORS[charData.class] or { r=1, g=1, b=1 }

        -- Métiers visibles : principaux puis secondaires
        local visibleProfs = {}
        for _, p in ipairs(charData.professions) do
            if not p.secondary and not pluginNs.IsProfessionHidden(p.name) then visibleProfs[#visibleProfs+1] = p end
        end
        for _, p in ipairs(charData.professions) do
            if p.secondary and not pluginNs.IsProfessionHidden(p.name) then visibleProfs[#visibleProfs+1] = p end
        end

        if #visibleProfs > 0 then

        -- Bandeau personnage (poolé)
        local cb = Acquire("charBlock", sc, NewCharBlock)
        cb:SetSize(contentW - PADX * 2, 32); cb:SetPoint("TOPLEFT", PADX, offsetY)
        cb:SetBackdropColor(c.r*0.22 + 0.05, c.g*0.22 + 0.05, c.b*0.22 + 0.05, 1)
        cb.charLabel:SetTextColor(c.r + (1-c.r)*0.35, c.g + (1-c.g)*0.35, c.b + (1-c.b)*0.35)
        cb.charLabel:SetText(string_format("%s |cff%02x%02x%02x%s|r", charName,
            c.r*255, c.g*255, c.b*255, realmName))
        cb.lvlFS:SetTextColor(unpack(T.text))
        cb.lvlFS:SetText(charData.level and (core.L("LEVEL_SHORT")..charData.level) or "")
        offsetY = offsetY - 32 - 12

        local rowTop, rowH, deferred = offsetY, 0, {}

        for idx, profData in ipairs(visibleProfs) do
            local col = (idx - 1) % ncols
            if col == 0 then rowTop, rowH, deferred = offsetY, 0, {} end

            -- Paliers visibles (filtre extensions)
            local tiers = {}
            for _, tier in ipairs(profData.tiers or {}) do
                if not IsExpansionHidden(tier.name) then tiers[#tiers+1] = tier end
            end

            local rDefKey = (pluginNs.PROF_RECIPE_KEY and pluginNs.PROF_RECIPE_KEY[profData.name]) or profData.name
            local hasRecipes = pluginNs.RenderRecipeGrid and pluginNs.RECIPE_DEFINITIONS
                and pluginNs.RECIPE_DEFINITIONS[rDefKey] and true or false

            local cardH = 58 + #tiers * (BAR_H + 3) + (#tiers > 0 and 8 or 0) + (hasRecipes and 24 or 0) + CARD_PAD

            local card = Acquire("profCard", sc, NewProfCard)
            card:SetSize(cardW, cardH)
            card:SetPoint("TOPLEFT", sc, "TOPLEFT", PADX + col * (cardW + GAP), rowTop)
            card.icon:SetTexture(profData.icon)
            card.nameFS:SetText(GetProfDisplayName(profData.name))
            card.nameFS:SetTextColor(unpack(T.text))

            -- Barres de paliers (poolées)
            local y = -58
            for _, tier in ipairs(tiers) do
                local safeMax = (tier.max and tier.max > 0) and tier.max or 1
                local safeCur = tier.level or 0
                local pct     = math_min(safeCur / safeMax, 1)
                local isFull  = (safeCur >= safeMax)

                local tb = Acquire("tierBar", card, NewTierBar)
                tb:SetSize(innerW, BAR_H); tb:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, y)
                if pct > 0 then
                    tb.fill:SetWidth(math_max((innerW - 2) * pct, 2))
                    if isFull then tb.fill:SetColorTexture(0.10, 0.58, 0.28, 1)
                    else           tb.fill:SetColorTexture(0.18, 0.42, 0.80, 1) end
                    tb.fill:Show()
                else
                    tb.fill:Hide()
                end
                tb.nameFS:SetText(tier.name or ""); tb.nameFS:SetTextColor(1, 1, 1, 1)
                tb.rankFS:SetTextColor(1, 1, 1, 1)
                tb.rankFS:SetText(isFull and "MAX" or (safeCur.." / "..safeMax))
                y = y - (BAR_H + 3)
            end
            if #tiers > 0 then y = y - 8 end

            -- Bouton dépliage recettes (poolé) ; grille rendue sous la ligne
            if hasRecipes then
                local rKey       = recipeKey(realmName, charName, profData.name)
                local isExpanded = pluginNs.recipeExpanded[rKey] or false
                if isCurrent and pluginNs.DetectKnownRecipes then pluginNs.DetectKnownRecipes(profData) end

                local totalR, knownR = 0, 0
                local knownMap = profData.knownRecipes or {}
                for _, recipes in pairs(pluginNs.RECIPE_DEFINITIONS[rDefKey]) do
                    totalR = totalR + #recipes
                    for _, recipe in ipairs(recipes) do if knownMap[recipe.itemID] then knownR = knownR + 1 end end
                end

                local rt = Acquire("recipeToggle", card, NewRecipeToggle)
                rt:SetSize(innerW, 24); rt:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, y)
                rt.arrowTex:SetAtlas(isExpanded and "housing-floor-arrow-down-default" or "housing-floor-arrow-up-default")
                rt.recipeFS:SetTextColor(unpack(T.text))
                rt.recipeFS:SetText(string_format(core.L("RECIPES_LABEL"), knownR, totalR))
                rt.miniBarBg:SetColorTexture(unpack(T.roles.input[1]))
                if totalR > 0 then
                    local pctR = knownR/totalR
                    rt.miniBarFill:SetSize(math_max(math.floor(pctR*50), 1), 4)
                    rt.miniBarFill:SetColorTexture(pctR>=1 and 0 or 0.45, pctR>=1 and 0.85 or 0.55, pctR>=1 and 0.35 or 1.00, 0.9)
                    rt.miniBarFill:Show(); rt.miniBarBg:Show()
                else
                    rt.miniBarFill:Hide(); rt.miniBarBg:Hide()
                end

                rt:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(isExpanded and core.L("RECIPES_FOLD") or core.L("RECIPES_UNFOLD"), 0.8, 0.8, 1)
                    GameTooltip:AddLine(string_format(core.L("RECIPES_KNOWN"), knownR, totalR), 1, 1, 1)
                    GameTooltip:Show()
                end)
                rt:SetScript("OnLeave", function() GameTooltip:Hide() end)
                local cKey = rKey
                rt:SetScript("OnClick", function()
                    pluginNs.recipeExpanded[cKey] = not pluginNs.recipeExpanded[cKey]
                    pluginNs.InvalidateProfsHash()   -- force rebuild après toggle recette
                    pluginNs.ShowProfessions()
                end)

                if isExpanded then
                    deferred[#deferred+1] = function(parent, yy)
                        return pluginNs.RenderRecipeGrid(parent, profData, realmName, charName, isCurrent, PADX, yy)
                    end
                end
            end

            rowH = math_max(rowH, cardH)

            -- Fin de ligne : on avance, puis grilles dépliées sous la ligne
            if col == ncols - 1 or idx == #visibleProfs then
                offsetY = rowTop - rowH - 12
                for _, fn in ipairs(deferred) do offsetY = fn(sc, offsetY) end
            end
        end

        offsetY = offsetY - 10
        end -- #visibleProfs
    end

    sc:SetHeight(math_max(math.abs(offsetY) + 60, 200))
end
