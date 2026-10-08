local addonName, ns = ...
local core = ns.core

-- ====================================================
-- GEOMETRIE
-- ====================================================
local FRAME_W = core.DEFAULT_FRAME_W
local FRAME_H = core.DEFAULT_FRAME_H

local LAYOUT = { pad = 8, titleH = 40, sideW = 190 }
LAYOUT.contentLeft = LAYOUT.pad + LAYOUT.sideW + LAYOUT.pad
core.LAYOUT = LAYOUT

-- ====================================================
-- FENÊTRE PRINCIPALE
-- ====================================================
local mainFrame = CreateFrame("Frame", "ProfessionViewerLogFrame", UIParent, "BackdropTemplate")
mainFrame:SetSize(FRAME_W, FRAME_H)
mainFrame:SetPoint("CENTER")
core.Skin.Frame(mainFrame, "window")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(false)   -- drag géré par titleBar
mainFrame:SetFrameStrata("HIGH")
mainFrame:SetClampedToScreen(true)
mainFrame:Hide()
mainFrame:SetResizable(true)
mainFrame:SetResizeBounds(560, 380, 1800, 1000)
tinsert(UISpecialFrames, "ProfessionViewerLogFrame")
core.mainFrame = mainFrame

-- ── BARRE DE TITRE ───────────────────────────────────────────────
local titleBar = CreateFrame("Frame", nil, mainFrame)
titleBar:SetHeight(LAYOUT.titleH)
titleBar:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  0, 0)
titleBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
titleBar:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() mainFrame:StartMoving() end)
titleBar:SetScript("OnDragStop", function()
    mainFrame:StopMovingOrSizing()
    local x, y = mainFrame:GetLeft(), mainFrame:GetTop()
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end)

-- texte posé par core.RefreshSidebarStyle (thème + langue)
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("LEFT", 18, 0)
core.titleText = titleText

local closeBtn = core.Skin.CloseButton(titleBar, function() mainFrame:Hide() end)
closeBtn:SetPoint("RIGHT", -12, 0)

-- ── SIDEBAR ──────────────────────────────────────────────────────
local sideBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
sideBar:SetWidth(LAYOUT.sideW)
sideBar:SetPoint("TOPLEFT",    mainFrame, "TOPLEFT",    LAYOUT.pad, -LAYOUT.titleH)
sideBar:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", LAYOUT.pad,  LAYOUT.pad)
core.Skin.Frame(sideBar, "panel")
core.sideBar = sideBar

-- ── PANNEAU CONTENU ──────────────────────────────────────────────
local mainBG = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
mainBG:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     LAYOUT.contentLeft, -LAYOUT.titleH)
mainBG:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -LAYOUT.pad,         LAYOUT.pad)
core.Skin.Frame(mainBG, "panel")
core.mainBG = mainBG

-- ── POUBELLE (parent de reparenting pour libérer les widgets) ────
local trashBin = CreateFrame("Frame", nil, UIParent)
trashBin:Hide()
core.trashBin = trashBin

-- settingsChild : frame persistante pour le cache des paramètres
core.settingsChild = nil

-- ====================================================
-- LARGEUR UTILISABLE DU CONTENU
-- ====================================================
function core.GetContentWidth()
    return math.max(300, mainFrame:GetWidth() - LAYOUT.contentLeft - LAYOUT.pad - 26)
end

-- ====================================================
-- ZONE DE DÉFILEMENT
-- ====================================================
local scrollFrame = CreateFrame("ScrollFrame", "ProfessionViewerLogScroll", mainFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",     mainBG, "TOPLEFT",      6, -6)
scrollFrame:SetPoint("BOTTOMRIGHT", mainBG, "BOTTOMRIGHT", -20,  6)
core.scrollFrame = scrollFrame

-- ── Scrollbar fine : piste + pouce coloré par le thème ──────────
-- Le scroll reste natif (SetVerticalScroll / GetVerticalScrollRange)
local BAR_W = 8
core.scrollBarThumbs = core.scrollBarThumbs or {}

local function SkinScrollBar(sf)
    -- masque la scrollbar native (la logique de scroll est conservée)
    local nativeBar = sf.ScrollBar or (sf:GetName() and _G[sf:GetName() .. "ScrollBar"])
    if nativeBar then
        nativeBar:Hide(); nativeBar:EnableMouse(false); nativeBar.Show = function() end
    end
    local name = sf:GetName()
    if name then
        for _, suffix in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
            local btn = _G[name .. suffix]
            if btn then btn:Hide(); btn:EnableMouse(false); btn.Show = function() end end
        end
    end

    local track = CreateFrame("Frame", nil, sf)
    track:SetWidth(BAR_W)
    track:SetPoint("TOPRIGHT",    sf, "TOPRIGHT",    BAR_W - 2, -2)
    track:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", BAR_W - 2,  2)
    local trackTex = track:CreateTexture(nil, "BACKGROUND")
    trackTex:SetAllPoints()
    trackTex:SetColorTexture(0, 0, 0, 0.25)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(BAR_W)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    if thumbTex.SetMask then
        pcall(thumbTex.SetMask, thumbTex, "Interface\\Masks\\CircleMaskScalable")
    end

    local function ThumbColor(alpha)
        local b = core.Theme.thumb
        thumbTex:SetColorTexture(b[1], b[2], b[3], alpha)
    end
    ThumbColor(0.55)
    core.scrollBarThumbs[#core.scrollBarThumbs + 1] = thumbTex

    local function Update()
        local range  = sf:GetVerticalScrollRange() or 0
        local trackH = track:GetHeight() or 1
        if range <= 0 then track:Hide(); return end
        track:Show()
        local visH   = sf:GetHeight() or 1
        local thumbH = math.max(24, trackH * (visH / (visH + range)))
        thumb:SetHeight(thumbH)
        local scroll    = sf:GetVerticalScroll() or 0
        local maxOffset = math.max(0, trackH - thumbH)
        local pos       = (range > 0) and (scroll / range) * maxOffset or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -pos)
    end

    sf:HookScript("OnScrollRangeChanged", Update)
    sf:HookScript("OnVerticalScroll", Update)
    sf:HookScript("OnSizeChanged", Update)

    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        if range <= 0 then return end
        local cur = self:GetVerticalScroll() or 0
        self:SetVerticalScroll(math.min(range, math.max(0, cur - delta * 45)))
    end)

    local function OnEnterArea()
        if thumb.dragging then return end
        ThumbColor(0.8); trackTex:SetColorTexture(0, 0, 0, 0.35)
    end
    local function OnLeaveArea()
        if thumb.dragging then return end
        ThumbColor(0.55); trackTex:SetColorTexture(0, 0, 0, 0.25)
    end
    sf:HookScript("OnEnter", OnEnterArea)
    sf:HookScript("OnLeave", OnLeaveArea)
    thumb:SetScript("OnEnter", OnEnterArea)
    thumb:SetScript("OnLeave", OnLeaveArea)

    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self) self.dragging = true; ThumbColor(0.95) end)
    thumb:SetScript("OnDragStop",  function(self) self.dragging = false; OnLeaveArea() end)
    thumb:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local range = sf:GetVerticalScrollRange() or 0
        if range <= 0 then return end
        local trackH = track:GetHeight() or 1
        local thumbH = self:GetHeight() or 1
        local maxOffset = trackH - thumbH
        if maxOffset <= 0 then return end
        local scale = track:GetEffectiveScale()
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / scale
        local offset = (track:GetTop() or 0) - cursorY - (thumbH / 2)
        offset = math.max(0, math.min(maxOffset, offset))
        sf:SetVerticalScroll((offset / maxOffset) * range)
    end)

    Update()
end
core.SkinScrollBar = SkinScrollBar

SkinScrollBar(scrollFrame)

-- ====================================================
-- SCROLL CHILD + CLEAR CONTENT
-- ====================================================
local function MakeScrollChild()
    local f = CreateFrame("Frame", nil, scrollFrame)
    f:SetSize(core.GetContentWidth(), 2000)
    scrollFrame:SetScrollChild(f)
    core.scrollChild = f
end

function core.ClearContent()
    if core.scrollChild then
        if core.scrollChild == core.settingsChild then
            -- Ne pas détruire le cache settings : juste le cacher.
            core.scrollChild:Hide()
        else
            local children = { core.scrollChild:GetChildren() }
            for i = 1, #children do
                children[i]:SetParent(trashBin)
                children[i]:Hide()
            end
            core.scrollChild:SetParent(trashBin)
            core.scrollChild:Hide()
        end
    end
    MakeScrollChild()
end

MakeScrollChild()

-- ====================================================
-- REDIMENSIONNEMENT
-- ====================================================
mainFrame:SetScript("OnSizeChanged", function()
    if core.scrollChild then
        core.scrollChild:SetWidth(core.GetContentWidth())
    end
end)

mainFrame.resizeGrip = CreateFrame("Button", nil, mainFrame)
mainFrame.resizeGrip:SetSize(16, 16)
mainFrame.resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
mainFrame.resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
mainFrame.resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
mainFrame.resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
mainFrame.resizeGrip:SetFrameLevel(mainFrame:GetFrameLevel() + 10)

mainFrame.resizeGrip:SetScript("OnMouseDown", function()
    mainFrame:StartSizing("BOTTOMRIGHT")
end)
mainFrame.resizeGrip:SetScript("OnMouseUp", function()
    mainFrame:StopMovingOrSizing()
    if ProfessionViewerLogDB and ProfessionViewerLogDB.settings then
        ProfessionViewerLogDB.settings.frameWidth  = mainFrame:GetWidth()
        ProfessionViewerLogDB.settings.frameHeight = mainFrame:GetHeight()
    end
    core.scrollChild:SetWidth(core.GetContentWidth())
    if ns.isViewActive then
        ns.ShowProfessions()
    else
        ns.ShowSettings()
    end
end)

-- ====================================================
-- BOUTONS SIDEBAR
-- ====================================================
local BTN_W, BTN_H, BTN_GAP = LAYOUT.sideW - 24, 34, 8

-- key = clé de locale ; le texte est posé par core.RefreshSidebarStyle
local function CreateMenuButton(key, anchor, point, offsetY)
    local btn = CreateFrame("Button", nil, sideBar, "BackdropTemplate")
    btn:SetSize(BTN_W, BTN_H)
    btn:SetPoint("TOP", anchor, point, 0, offsetY)
    btn._key = key
    core.Skin.SideButton(btn)
    return btn
end

local btnProfessions = CreateMenuButton("BTN_PROFESSIONS", sideBar,       "TOP",    -12)
local btnDiscord     = CreateMenuButton("BTN_DISCORD",     btnProfessions, "BOTTOM", -BTN_GAP)
local btnSettings    = CreateMenuButton("BTN_SETTINGS",    btnDiscord,     "BOTTOM", -BTN_GAP)

-- ── Scripts des boutons (closures runtime → ns.Show* définis dans ui/) ───────
local function CloseExpansionPopup()
    if ns.expansionFilterPopup and ns.expansionFilterPopup:IsShown() then
        ns.expansionFilterPopup:Hide()
    end
end

local function CloseAllFilterPopups()
    CloseExpansionPopup()
    if ns.profFilterPopup and ns.profFilterPopup:IsShown() then
        ns.profFilterPopup:Hide()
    end
end

-- Ferme les popups de filtre quelle que soit la cause de fermeture de la
-- fenêtre principale (croix, Échap via UISpecialFrames, /pvl, etc.)
mainFrame:HookScript("OnHide", CloseAllFilterPopups)

btnProfessions:SetScript("OnClick", function(self)
    CloseAllFilterPopups()
    core.Skin.SetActive(self)
    ns.isViewActive = true
    ns.ShowProfessions()
end)

btnDiscord:SetScript("OnClick", function()
    CloseAllFilterPopups()
    if ns.ShowDiscordDialog then ns.ShowDiscordDialog() end
end)

btnSettings:SetScript("OnClick", function(self)
    CloseAllFilterPopups()
    core.Skin.SetActive(self)
    ns.isViewActive = false
    ns.ShowSettings()
end)

-- surligne la vue courante à l'ouverture
mainFrame:HookScript("OnShow", function()
    core.Skin.SetActive(ns.isViewActive and btnProfessions or btnSettings)
end)
