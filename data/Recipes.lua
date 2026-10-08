local addonName, ns = ...
local pluginNs = ns

-- ====================================================
-- RENDU DE LA GRILLE DE RECETTES
--
-- Les DONNÉES de recettes ne sont plus dans ce fichier : elles sont
-- désormais rangées dans data/professions/<Métier>/<Extension>.lua
-- (un dossier par métier, un fichier par extension) — même rangement
-- que ViewerLog_Housing. Chaque fichier enregistre ses recettes dans
-- pluginNs.RECIPE_DEFINITIONS, chargé AVANT ce fichier par le .toc.
--
-- Ce module ne fait plus que dessiner la grille à partir de cette table.
-- Clé de stockage = itemID (toujours unique, même si spellID = 0).
-- spellID sert uniquement à IsPlayerSpell pour la détection auto.
-- ====================================================

pluginNs.RECIPE_DEFINITIONS = pluginNs.RECIPE_DEFINITIONS or {}

-- ====================================================
-- CONSTANTES D'AFFICHAGE
-- ====================================================
local ICON_SIZE     = 30
local ICON_GAP      = 4
local ICONS_PER_ROW = 8

-- Ordre d'affichage des extensions (du plus récent au plus ancien)
local EXPANSION_ORDER = {
    "Midnight", "Khaz Algar", "Dragon Isles", "Shadowlands", "Battle for Azeroth",
    "Legion", "Warlords of Draenor", "Mists of Pandaria", "Cataclysm",
    "Wrath of the Lich King", "Burning Crusade", "Classic",
}

-- ====================================================
-- RENDU DE LA GRILLE DE RECETTES
-- Clé de stockage = itemID (toujours unique, même si spellID = 0)
-- spellID sert uniquement à IsPlayerSpell pour la détection auto
-- ====================================================
function pluginNs.RenderRecipeGrid(parent, profData, realmName, charName, isCurrent, LEFT_PAD, offsetY)
    local defKey = (pluginNs.PROF_RECIPE_KEY and pluginNs.PROF_RECIPE_KEY[profData.name]) or profData.name
    local profDef = pluginNs.RECIPE_DEFINITIONS[defKey]
    if not profDef then return offsetY end

    -- Lit uniquement depuis la DB — la detection IsPlayerSpell est faite par Scanner
    local knownMap = profData.knownRecipes or {}

    local hasAnySection = false

    for _, expName in ipairs(EXPANSION_ORDER) do
        local recipes = profDef[expName]
        if recipes and #recipes > 0 then
            hasAnySection = true

            local color = pluginNs.GetTierColor(expName)

            -- Trait de séparation
            local sepLine = parent:CreateTexture(nil, "ARTWORK")
            sepLine:SetSize(260, 1)
            sepLine:SetPoint("TOPLEFT", LEFT_PAD + 14, offsetY - 4)
            sepLine:SetColorTexture(color.r, color.g, color.b, 0.15)
            offsetY = offsetY - 14

            -- Label extension + compteur appris/total
            local knownCount = 0
            for _, recipe in ipairs(recipes) do
                if knownMap[recipe.itemID] then knownCount = knownCount + 1 end
            end

            local secLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            secLabel:SetPoint("TOPLEFT", LEFT_PAD + 14, offsetY)
            secLabel:SetTextColor(color.r * 0.8, color.g * 0.8, color.b * 0.8)
            secLabel:SetText(string.format("Recettes %s  |cff555555%d/%d|r", expName, knownCount, #recipes))
            offsetY = offsetY - 20

            -- Grille d'icônes
            local col = 0
            local row = 0

            for _, recipe in ipairs(recipes) do
                local capturedRecipe = recipe
                local isKnown = knownMap[recipe.itemID] or false

                local iconFrame = CreateFrame("Button", nil, parent, "BackdropTemplate")
                iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
                iconFrame:SetPoint(
                    "TOPLEFT",
                    LEFT_PAD + 14 + col * (ICON_SIZE + ICON_GAP),
                    offsetY - row * (ICON_SIZE + ICON_GAP)
                )
                iconFrame:SetBackdrop({
                    bgFile   = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 2,
                })

                -- Texture de l'objet
                local tex = iconFrame:CreateTexture(nil, "ARTWORK")
                tex:SetPoint("TOPLEFT", 2, -2)
                tex:SetPoint("BOTTOMRIGHT", -2, 2)
                tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                local itemIcon = (C_Item.GetItemIconByID and C_Item.GetItemIconByID(recipe.itemID))
                    or (GetItemIcon and GetItemIcon(recipe.itemID))
                tex:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")

                -- Applique l'état visuel (bordure + fond + teinte icône)
                local function ApplyState(frame, texture, known)
                    if known then
                        frame:SetBackdropBorderColor(0.10, 0.85, 0.20, 1)
                        frame:SetBackdropColor(0.04, 0.14, 0.04, 1)
                        texture:SetVertexColor(1, 1, 1)
                    else
                        frame:SetBackdropBorderColor(0.70, 0.10, 0.10, 0.9)
                        frame:SetBackdropColor(0.14, 0.04, 0.04, 1)
                        texture:SetVertexColor(0.35, 0.35, 0.35)
                    end
                end

                ApplyState(iconFrame, tex, isKnown)

                -- Survol -> ouvre la visionneuse 3D
                iconFrame:SetScript("OnEnter", function(self)
                    if pluginNs.OpenModelViewer then
                        pluginNs.OpenModelViewer(capturedRecipe, self)
                    end
                end)
                iconFrame:SetScript("OnLeave", function(self)
                    if pluginNs.HideModelViewer then
                        pluginNs.HideModelViewer()
                    end
                end)

                col = col + 1
                if col >= ICONS_PER_ROW then
                    col = 0
                    row = row + 1
                end
            end

            local totalRows = math.ceil(#recipes / ICONS_PER_ROW)
            offsetY = offsetY - totalRows * (ICON_SIZE + ICON_GAP) - 8
        end
    end

    if hasAnySection then
        offsetY = offsetY - 4
    end

    return offsetY
end
