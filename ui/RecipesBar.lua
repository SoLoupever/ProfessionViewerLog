local addonName, ns = ...
local core = ns.core

-- Grille des recettes de métier (données : vl.GetRecipes).
-- Une seule grille dépliée à la fois (centaines d'icônes possibles).

local ICON_SIZE, ICON_GAP = 30, 4
local OTHER_KEY = "__other__"

-- ── Pool d'icônes et d'en-têtes ──────────────────────
local trash = CreateFrame("Frame", nil, UIParent); trash:Hide()
local iconPool, iconActive = {}, {}
local headPool, headActive = {}, {}

local function NewIcon(parent)
    local f = CreateFrame("Button", nil, parent, "BackdropTemplate")
    f:SetSize(ICON_SIZE, ICON_SIZE)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetPoint("TOPLEFT", 2, -2); f.tex:SetPoint("BOTTOMRIGHT", -2, 2)
    f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return f
end

local function NewHead(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(16)
    f.sep = f:CreateTexture(nil, "ARTWORK")
    f.sep:SetPoint("TOPLEFT"); f.sep:SetPoint("TOPRIGHT"); f.sep:SetHeight(1)
    f.fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.fs:SetPoint("TOPLEFT", 0, -2)
    return f
end

local function Acquire(pool, active, parent, create)
    local f = table.remove(pool) or create(parent)
    f:SetParent(parent); f:ClearAllPoints(); f:Show()
    active[#active + 1] = f
    return f
end

local function ReleaseAll(pool, active)
    for i = #active, 1, -1 do
        local f = active[i]
        f:Hide(); f:ClearAllPoints(); f:SetParent(trash)
        pool[#pool + 1] = f
        active[i] = nil
    end
end

-- Appelé avant chaque reconstruction de la vue
function ns.ReleaseRecipesGrid()
    ReleaseAll(iconPool, iconActive)
    ReleaseAll(headPool, headActive)
end

-- ── Rendu ────────────────────────────────────────────
-- entries : { [recipeID] = { name, icon, learned, tier } }
function ns.RenderRecipesGrid(parent, entries, LEFT_PAD, offsetY, contentW)
    contentW = contentW or 660
    local gridLeft   = LEFT_PAD + 14
    local gridAvailW = contentW - gridLeft - 10
    local perRow = math.max(4, math.min(16, math.floor((gridAvailW + ICON_GAP) / (ICON_SIZE + ICON_GAP))))

    local groups, order = { [OTHER_KEY] = {} }, {}
    for _, exp in ipairs(ns.EXPANSION_LIST) do
        groups[exp.name] = {}
        order[#order + 1] = exp.name
    end
    order[#order + 1] = OTHER_KEY

    local any = false
    for id, e in pairs(entries) do
        any = true
        local g = groups[ns.MatchExpansion(e.tier) or OTHER_KEY]
        g[#g + 1] = { id = id, name = e.name, icon = e.icon, learned = e.learned }
    end
    if not any then return offsetY end

    offsetY = offsetY - 6
    for _, key in ipairs(order) do
        local list = groups[key]
        if #list > 0 then
            table.sort(list, function(a, b)
                if a.learned ~= b.learned then return a.learned end
                return (a.name or "") < (b.name or "")
            end)
            local known = 0
            for _, r in ipairs(list) do if r.learned then known = known + 1 end end

            local isOther = (key == OTHER_KEY)
            local color = isOther and { r = 0.5, g = 0.5, b = 0.5 } or ns.GetTierColor(key)

            local head = Acquire(headPool, headActive, parent, NewHead)
            head:SetWidth(gridAvailW)
            head:SetPoint("TOPLEFT", parent, "TOPLEFT", gridLeft, offsetY)
            head.sep:SetColorTexture(color.r, color.g, color.b, 0.5)
            head.fs:SetTextColor(color.r, color.g, color.b)
            head.fs:SetText(string.format("%s  %d/%d", isOther and core.L("RECIPES_OTHER") or key, known, #list))
            offsetY = offsetY - 20

            for i, r in ipairs(list) do
                local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
                local icon = Acquire(iconPool, iconActive, parent, NewIcon)
                icon:SetPoint("TOPLEFT", parent, "TOPLEFT",
                    gridLeft + col * (ICON_SIZE + ICON_GAP),
                    offsetY - row * (ICON_SIZE + ICON_GAP))
                icon.tex:SetTexture(r.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

                if r.learned then
                    icon:SetBackdropBorderColor(0.10, 0.85, 0.20, 1)
                    icon:SetBackdropColor(0.04, 0.14, 0.04, 1)
                    icon.tex:SetVertexColor(1, 1, 1)
                else
                    icon:SetBackdropBorderColor(0.70, 0.10, 0.10, 0.9)
                    icon:SetBackdropColor(0.14, 0.04, 0.04, 1)
                    icon.tex:SetVertexColor(0.35, 0.35, 0.35)
                end

                local rName, rLearned = r.name or "?", r.learned
                icon:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(rName, 1, 1, 1)
                    GameTooltip:AddLine(core.L(rLearned and "RECIPE_KNOWN_TT" or "RECIPE_UNKNOWN_TT"))
                    GameTooltip:Show()
                end)
            end

            offsetY = offsetY - math.ceil(#list / perRow) * (ICON_SIZE + ICON_GAP) - 10
        end
    end
    return offsetY
end
