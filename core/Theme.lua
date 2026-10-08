local addonName, ns = ...
local core = ns.core

-- ====================================================
-- THEME : palettes, registre de skin, ApplyTheme
-- Shell statique : frames enregistrées via core.Skin.*
-- Vues dynamiques : lisent core.Theme à la construction
-- ====================================================

local WHITE  = "Interface\\Buttons\\WHITE8x8"
local floor  = math.floor
local unpack = unpack

local BACKDROP = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }

-- roles : { bg, edge, hoverBg, hoverEdge }
local THEMES = {
    profession = {
        key      = "profession",
        title    = "4da6ff",
        sub      = "ff40a0",
        accent   = { 0.55, 0.45, 0.18 },
        thumb    = { 0.65, 0.52, 0.18 },
        text     = { 0.92, 0.92, 0.92 },
        textDim  = { 0.60, 0.60, 0.62 },
        heading  = { 0.95, 0.76, 0.25 },
        gold     = { 1.00, 0.82, 0.00 },
        sideText = nil, -- couleur de classe
        roles = {
            window = { { 0.03, 0.03, 0.04, 1 }, { 0.30, 0.24, 0.10, 1 } },
            panel  = { { 0.04, 0.04, 0.05, 1 }, { 0.22, 0.19, 0.10, 1 } },
            bar    = { { 0.035, 0.035, 0.045, 1 }, { 0.22, 0.19, 0.10, 1 },
                       { 0.08, 0.08, 0.10, 1 }, { 0.60, 0.50, 0.20, 1 } },
            card   = { { 0.05, 0.05, 0.065, 1 }, { 0.16, 0.15, 0.12, 1 },
                       { 0.09, 0.09, 0.12, 1 }, { 0.35, 0.30, 0.15, 1 } },
            input  = { { 0.02, 0.02, 0.03, 1 }, { 0.30, 0.26, 0.12, 1 },
                       { 0.04, 0.04, 0.05, 1 }, { 1.00, 0.82, 0.00, 1 } },
            button = { { 0.02, 0.02, 0.03, 1 }, { 0.30, 0.26, 0.12, 1 },
                       { 0.07, 0.07, 0.09, 1 }, { 0.60, 0.50, 0.20, 1 } },
            active = { { 0.10, 0.08, 0.04, 1 }, { 1.00, 0.82, 0.00, 1 } },
        },
    },
    blizzard = {
        key      = "blizzard",
        title    = "4da6ff",
        sub      = "ff40a0",
        accent   = { 0.55, 0.44, 0.22 },
        thumb    = { 0.60, 0.48, 0.22 },
        text     = { 0.93, 0.88, 0.75 },
        textDim  = { 0.62, 0.57, 0.47 },
        heading  = { 0.98, 0.78, 0.30 },
        gold     = { 1.00, 0.82, 0.00 },
        sideText = { 0.89, 0.82, 0.65 },
        roles = {
            window = { { 0.075, 0.06, 0.045, 1 }, { 0.42, 0.33, 0.17, 1 } },
            panel  = { { 0.055, 0.045, 0.035, 1 }, { 0.30, 0.24, 0.13, 1 } },
            bar    = { { 0.08, 0.065, 0.05, 1 }, { 0.33, 0.27, 0.15, 1 },
                       { 0.12, 0.10, 0.07, 1 }, { 0.65, 0.52, 0.25, 1 } },
            card   = { { 0.09, 0.075, 0.06, 1 }, { 0.24, 0.19, 0.10, 1 },
                       { 0.13, 0.11, 0.08, 1 }, { 0.45, 0.36, 0.18, 1 } },
            input  = { { 0.04, 0.035, 0.03, 1 }, { 0.30, 0.24, 0.13, 1 },
                       { 0.06, 0.05, 0.04, 1 }, { 1.00, 0.82, 0.00, 1 } },
            button = { { 0.06, 0.05, 0.04, 1 }, { 0.30, 0.24, 0.13, 1 },
                       { 0.12, 0.10, 0.07, 1 }, { 0.65, 0.52, 0.25, 1 } },
            active = { { 0.14, 0.11, 0.05, 1 }, { 1.00, 0.82, 0.00, 1 } },
        },
    },
}

core.THEMES      = THEMES
core.THEME_ORDER = { "profession", "blizzard" }
core.Theme       = THEMES.profession

-- thème inconnu ou ancien → profession
local function Normalize(key)
    return THEMES[key] and key or "profession"
end

function core.GetThemeKey()
    local s = ProfessionViewerLogDB and ProfessionViewerLogDB.settings
    return Normalize(s and s.theme)
end

-- ── Couleur de classe du joueur ───────────────────────────────────
local function ClassColor()
    local _, classFile = UnitClass("player")
    local col = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if col then return { col.r, col.g, col.b } end
    return { 0.80, 0.53, 1.00 }
end

-- ── Listeners (modules qui réagissent à un changement) ────────────
local listeners = {}
function core.RegisterThemeListener(fn)
    if type(fn) == "function" then listeners[#listeners + 1] = fn end
end

-- ── Registre de skin ──────────────────────────────────────────────
local registry = setmetatable({}, { __mode = "k" })
local sideBtns = {}
local Skin = {}
core.Skin = Skin

local function Paint(f)
    local role = f._pvlRole
    local r    = core.Theme.roles[role]
    if not r then return end
    local bg, edge = r[1], r[2]
    if role == "button" and f._active then
        bg, edge = core.Theme.roles.active[1], core.Theme.roles.active[2]
    elseif f._hover and r[3] then
        bg, edge = r[3], r[4]
    end
    f:SetBackdropColor(unpack(bg))
    f:SetBackdropBorderColor(unpack(edge))
end
Skin.Paint = Paint

function Skin.Frame(f, role)
    f:SetBackdrop(BACKDROP)
    f._pvlRole = role
    registry[f] = true
    Paint(f)
    return f
end

function Skin.Button(f, role)
    Skin.Frame(f, role or "button")
    f:HookScript("OnEnter", function(self) self._hover = true;  Paint(self) end)
    f:HookScript("OnLeave", function(self) self._hover = false; Paint(self) end)
    return f
end

-- Libellé de sidebar : FontString propre au skin, couleur gérée ici
local function PaintSideText(btn)
    local fs = btn._pvlLabel
    if not fs then return end
    local t = core.Theme
    local c = btn._active and t.gold or t.sideText or ClassColor()
    fs:SetTextColor(c[1], c[2], c[3])
end

function Skin.SideButton(btn)
    if btn._pvlSide then return btn end
    btn._pvlSide = true
    Skin.Button(btn)

    local nfs = btn:GetFontString()
    if nfs then nfs:SetText(""); nfs:Hide() end

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER")
    btn._pvlLabel = fs

    btn.SetText = function(self, txt)
        txt = (txt or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        self._text = txt
        fs:SetText(txt)
        PaintSideText(self)
    end
    btn.GetText = function(self) return self._text or "" end

    sideBtns[#sideBtns + 1] = btn
    return btn
end

-- Filet horizontal 1px, à ancrer par l'appelant
function Skin.Rule(parent)
    local tx = parent:CreateTexture(nil, "ARTWORK")
    local h  = core.Theme.heading
    tx:SetHeight(1)
    tx:SetColorTexture(h[1], h[2], h[3], 0.35)
    return tx
end

-- Bouton fermer carré « X »
function Skin.CloseButton(parent, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(26, 26)
    Skin.Button(b)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER", 0, 1)
    fs:SetText("X")
    local function Tint(c) fs:SetTextColor(c[1], c[2], c[3]) end
    Tint(core.Theme.text)
    b:SetScript("OnClick", onClick)
    b:HookScript("OnEnter", function() Tint(core.Theme.gold) end)
    b:HookScript("OnLeave", function() Tint(core.Theme.text) end)
    core.RegisterThemeListener(function(t) Tint(t.text) end)
    return b
end

-- Bouton actif de la sidebar (un seul à la fois)
function Skin.SetActive(btn)
    for _, b in ipairs(sideBtns) do
        if b._active or b == btn then
            b._active = (b == btn)
            Paint(b)
            PaintSideText(b)
        end
    end
end

-- ── Titre + libellés de la sidebar (thème + langue) ───────────────
function core.RefreshSidebarStyle()
    local t = core.Theme
    if core.titleText then
        core.titleText:SetText("|cff" .. t.title .. core.L("UI_TITLE") .. "|r  |cff"
            .. t.sub .. core.L("UI_AUTHOR") .. "|r")
    end
    for _, b in ipairs(sideBtns) do
        if b._key then b:SetText(core.L(b._key)) end
        PaintSideText(b)
    end
end

-- ── ApplyTheme ────────────────────────────────────────────────────
function core.ApplyTheme(theme)
    local key = Normalize(theme)
    ProfessionViewerLogDB.settings = ProfessionViewerLogDB.settings or {}
    ProfessionViewerLogDB.settings.theme = key

    local t = THEMES[key]
    core.Theme = t

    for f in pairs(registry) do Paint(f) end
    core.RefreshSidebarStyle()

    for _, tex in ipairs(core.scrollBarThumbs or {}) do
        tex:SetColorTexture(t.thumb[1], t.thumb[2], t.thumb[3], 0.55)
    end

    for _, fn in ipairs(listeners) do fn(t) end
    core.InvalidateSettings()
end
