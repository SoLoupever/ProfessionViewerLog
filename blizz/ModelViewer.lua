local addonName, ns = ...
local pluginNs = ns
local core = ns.core

-- ====================================================
-- VISIONNEUSE 3D — 
--

--

-- ====================================================

local viewer   = nil
local rotation = 0
local ROT_SPEED = 0.5   -- rad/s, 
-- Cache decorID → { fileID, displayID, iconTex }
-- Rempli au PLAYER_ENTERING_WORLD depuis C_HousingCatalog
local decorCache = {}
local cacheReady = false

-- Positions de caméra (GetModelFileID → posData),
local MODEL_POSITIONS = {
    [660974]  = { model_x=0.00, model_z=4.80,  camera_y=10.20, zoom=20.0 },
    [577102]  = { model_x=0.00, model_z=0.00,  camera_y=5.40,  zoom=14.8 },
    [1108752] = { model_x=0.00, model_z=0.00,  camera_y=4.40,  zoom=8.8  },
    [1402222] = { model_x=0.00, model_z=0.00,  camera_y=2.00,  zoom=4.4  },
    [1361683] = { model_x=0.00, model_z=0.74,  camera_y=7.20,  zoom=12.2 },
    [668138]  = { model_x=0.00, model_z=-0.04, camera_y=2.32,  zoom=6.4  },
    [2620664] = { model_x=0.00, model_z=0.40,  camera_y=7.20,  zoom=5.8  },
    [3883455] = { model_x=0.00, model_z=-0.22, camera_y=3.60,  zoom=6.2  },
    [3886996] = { model_x=0.00, model_z=-2.04, camera_y=5.60,  zoom=10.4 },
    [5389584] = { model_x=0.00, model_z=-0.08, camera_y=3.60,  zoom=7.8  },
    [5788117] = { model_x=0.00, model_z=1.24,  camera_y=12.00, zoom=20.6 },
    [2481224] = { model_x=0.00, model_z=1.44,  camera_y=15.20, zoom=29.2 },
    [2745098] = { model_x=0.00, model_z=4.00,  camera_y=11.20, zoom=18.2 },
    [1597477] = { model_x=0.00, model_z=0.10,  camera_y=3.20,  zoom=8.0  },
    [304027]  = { model_x=0.00, model_z=0.44,  camera_y=5.74,  zoom=12.4 },
    [200273]  = { model_x=0.00, model_z=-0.68, camera_y=7.80,  zoom=15.4 },
    [200281]  = { model_x=0.00, model_z=-0.52, camera_y=7.80,  zoom=13.2 },
    [200268]  = { model_x=0.00, model_z=-0.74, camera_y=6.40,  zoom=12.0 },
    [200276]  = { model_x=0.00, model_z=-0.74, camera_y=6.40,  zoom=12.0 },
    [414219]  = { model_x=0.00, model_z=0.40,  camera_y=10.00, zoom=30.2 },
    [1096777] = { model_x=0.00, model_z=2.86,  camera_y=9.28,  zoom=10.0 },
    [5278833] = { model_x=0.00, model_z=0.16,  camera_y=6.52,  zoom=15.6 },
    [1696757] = { model_x=0.00, model_z=0.74,  camera_y=8.72,  zoom=22.0 },
    [4896167] = { model_x=0.00, model_z=0.40,  camera_y=8.16,  zoom=24.0 },
    [2353835] = { model_x=0.00, model_z=7.12,  camera_y=8.42,  zoom=12.0 },
    [2353834] = { model_x=0.00, model_z=7.12,  camera_y=8.42,  zoom=12.0 },
    [199687]  = { model_x=0.00, model_z=7.12,  camera_y=12.00, zoom=10.4 },
    [5770750] = { model_x=0.00, model_z=1.20,  camera_y=5.20,  zoom=10.2 },
    [2432865] = { model_x=0.00, model_z=0.10,  camera_y=5.88,  zoom=12.8 },
    [5933736] = { model_x=0.00, model_z=0.60,  camera_y=9.80,  zoom=20.8 },
    [197430]  = { model_x=0.00, model_z=-3.92, camera_y=0.32,  zoom=22.6 },
    [321660]  = { model_x=0.00, model_z=0.18,  camera_y=5.24,  zoom=12.0 },
    [392127]  = { model_x=0.00, model_z=0.58,  camera_y=4.34,  zoom=10.2 },
    [464019]  = { model_x=0.00, model_z=0.40,  camera_y=4.98,  zoom=16.4 },
    [305584]  = { model_x=0.00, model_z=0.00,  camera_y=2.94,  zoom=9.2  },
    [1361709] = { model_x=0.00, model_z=0.40,  camera_y=7.02,  zoom=11.8 },
    [1255418] = { model_x=0.00, model_z=-0.22, camera_y=4.80,  zoom=18.0 },
}

-- ── Scanner du catalogue housing ──────────────────────────────────────────────
-- Appelé une fois au PLAYER_ENTERING_WORLD.
-- Parcourt tous les decorIDs de nos recettes, interroge C_HousingCatalog,
-- et extrait tout champ qui ressemble à un fileID / displayID de modèle.
local function ScanHousingCatalog()
    if cacheReady then return end
    if not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        cacheReady = true
        return
    end

    -- Collecte tous les decorIDs uniques depuis les définitions de recettes
    local decorIDs = {}
    if pluginNs.RECIPE_DEFINITIONS then
        for _, profData in pairs(pluginNs.RECIPE_DEFINITIONS) do
            for _, xpacData in pairs(profData) do
                for _, recipe in ipairs(xpacData) do
                    if recipe.decorID and not decorIDs[recipe.decorID] then
                        decorIDs[recipe.decorID] = true
                    end
                end
            end
        end
    end

    -- Charge les données sauvegardées
    if ProfessionViewerLogFileIDs then
        for did, data in pairs(ProfessionViewerLogFileIDs) do
            decorCache[did] = data
        end
    else
        ProfessionViewerLogFileIDs = {}
    end

    -- Pour chaque decorID non encore en cache, interroge Blizzard
    for decorID in pairs(decorIDs) do
        if not decorCache[decorID] then
            local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByRecordID, 1, decorID, true)
            if ok and info then
                local entry = { iconTex = info.iconTexture or info.iconFileID }

                -- Inspecte TOUS les champs numériques > 100 qui pourraient être un fileID
                -- (Blizzard peut retourner fileID, displayInfoID, modelID selon la version)
                for k, v in pairs(info) do
                    local vtype = type(v)
                    if vtype == "number" and v > 100 then
                        local kl = k:lower()
                        if kl:find("file") or kl:find("model") or kl:find("display") then
                            entry[k] = v
                            -- Heuristique : fileID de modèle est > 100000
                            if v > 100000 and (kl:find("file") or kl:find("model")) then
                                entry.fileID = v
                            elseif kl:find("display") then
                                entry.displayID = v
                            end
                        end
                    end
                end

                decorCache[decorID] = entry
                ProfessionViewerLogFileIDs[decorID] = entry
            end
        end
    end

    cacheReady = true
end

-- ── Création de la fenêtre (lazy) ─────────────────────────────────────────────
local function CreateModelViewer()
    if viewer then return viewer end

    local frame = CreateFrame("Frame", "PVLModelViewer", UIParent, "BackdropTemplate")
    frame:SetSize(260, 300)
    core.Skin.Frame(frame, "window")
    frame:SetFrameStrata("TOOLTIP")
    frame:EnableMouse(false)
    frame:Hide()

    -- Titre
    local titleSep = frame:CreateTexture(nil, "ARTWORK")
    titleSep:SetSize(250, 1)
    titleSep:SetPoint("TOPLEFT", 5, -30)
    titleSep:SetColorTexture(core.Theme.heading[1], core.Theme.heading[2], core.Theme.heading[3], 0.4)

    local itemIconTex = frame:CreateTexture(nil, "OVERLAY")
    itemIconTex:SetSize(20, 20)
    itemIconTex:SetPoint("TOPLEFT", 8, -5)
    itemIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.itemIconTex = itemIconTex

    local titleFS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    titleFS:SetPoint("LEFT", itemIconTex, "RIGHT", 6, 0)
    titleFS:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    titleFS:SetPoint("TOP", frame, "TOP", 0, -10)
    titleFS:SetJustifyH("LEFT")
    titleFS:SetTextColor(1, 0.85, 0.20)
    frame.titleFS = titleFS

    -- Zone d'affichage
    local viewBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    viewBg:SetPoint("TOPLEFT",  5, -35)
    viewBg:SetPoint("TOPRIGHT", -5, -35)
    viewBg:SetHeight(235)
    viewBg:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    viewBg:SetBackdropColor(0.02, 0.02, 0.05, 1)
    viewBg:SetBackdropBorderColor(0.28, 0.22, 0.08, 1)
    viewBg:EnableMouse(false)

    -- Texture 2D (fallback)
    local previewTex = viewBg:CreateTexture(nil, "ARTWORK")
    previewTex:SetPoint("TOPLEFT",     4, -4)
    previewTex:SetPoint("BOTTOMRIGHT", -4,  4)
    previewTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    previewTex:Hide()
    frame.previewTex = previewTex

    -- PlayerModel 3D (technique HomeBound)
    local model = CreateFrame("PlayerModel", "PVLModel3DFrame", viewBg)
    model:SetPoint("TOPLEFT",     2, -2)
    model:SetPoint("BOTTOMRIGHT", -2,  2)
    model:EnableMouse(false)
    model.currentModelID = nil
    model:Hide()

    -- OnModelLoaded : caméra automatique, copie exacte HomeBound
    model:SetScript("OnModelLoaded", function(self)
        self:MakeCurrentCameraCustom()
        local fileID  = self:GetModelFileID()
        local posData = fileID and MODEL_POSITIONS[fileID]
        if posData then
            self:SetPosition(posData.model_x, 0, posData.model_z)
            self:SetCameraPosition(0, 0, posData.camera_y)
            self:SetCameraDistance(posData.zoom)
        else
            self:SetPosition(0, 0, 0)
            self:SetCameraPosition(0, 0, 4)
            self:SetCameraDistance(10)
            -- Sauvegarde le fileID pour calibrage futur via /pvlmodel
            if fileID and fileID > 0 and ProfessionViewerLogFileIDs then
                if not ProfessionViewerLogFileIDs["pos_" .. fileID] then
                    ProfessionViewerLogFileIDs["pos_" .. fileID] = {
                        model_x=0, model_z=0, camera_y=4, zoom=10, _needsCalibration=true
                    }
                end
            end
        end
    end)

    frame.model = model

    -- Message si rien de dispo
    local noPreviewFS = viewBg:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    noPreviewFS:SetPoint("CENTER", 0, 0)
    noPreviewFS:SetText("|cff555555Aperçu non disponible|r")
    noPreviewFS:SetJustifyH("CENTER")
    noPreviewFS:Hide()
    frame.noPreviewFS = noPreviewFS

    -- Mode badge (3D / 2D)
    local modeFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeFS:SetPoint("BOTTOM", 0, 8)
    modeFS:SetTextColor(0.32, 0.32, 0.32)
    frame.modeFS = modeFS

    -- OnUpdate : rotation avec elapsed (HomeBound)
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self:IsShown() and self.model:IsShown() then
            rotation = rotation + (ROT_SPEED * elapsed)
            if rotation >= (math.pi * 2) then
                rotation = rotation - (math.pi * 2)
            end
            self.model:SetFacing(rotation)
        end
    end)

    viewer = frame
    return viewer
end

-- ── Réinitialise la zone d'affichage ─────────────────────────────────────────
local function ClearView()
    if not viewer then return end
    viewer.model:Hide()
    viewer.model.currentModelID = nil
    viewer.previewTex:Hide()
    viewer.previewTex:SetTexture(nil)
    viewer.noPreviewFS:Hide()
    viewer.modeFS:SetText("")
end

-- ── Chargement du modèle — cascade HomeBound ─────────────────────────────────
local function LoadRecipe(recipe)
    ClearView()
    rotation = 0

    local cacheEntry = recipe.decorID and decorCache[recipe.decorID]

    -- 1. fileID dispo → SetModel 
    local fid = cacheEntry and cacheEntry.fileID
    if fid and fid > 0 then
        if viewer.model.currentModelID ~= fid then
            viewer.model:SetModel(fid)
            viewer.model.currentModelID = fid
        end
        viewer.model:Show()
        viewer.modeFS:SetText("|cff4488ff3D|r")
        return
    end

    -- 2. displayID → SetDisplayInfo
    local did = cacheEntry and cacheEntry.displayID
    if did and did > 0 then
        if viewer.model.currentModelID ~= did then
            viewer.model:SetDisplayInfo(did)
            viewer.model.currentModelID = did
        end
        viewer.model:Show()
        viewer.modeFS:SetText("|cff88aaff3D (displayInfo)|r")
        return
    end

    -- 3. Texture 2D depuis le catalogue
    local tex = cacheEntry and cacheEntry.iconTex
    if tex then
        if ProfessionViewerLogDB and ProfessionViewerLogDB.disable2DPreview then
            viewer.noPreviewFS:Show()
            return
        end
        viewer.previewTex:SetTexture(tex)
        viewer.previewTex:Show()
        viewer.modeFS:SetText("|cff888888Rendu 2D du catalogue|r")
        return
    end

    -- 4. Dernier recours : icône de l'item
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(recipe.itemID))
                 or (GetItemIcon and GetItemIcon(recipe.itemID))
    if icon then
        if ProfessionViewerLogDB and ProfessionViewerLogDB.disable2DPreview then
            viewer.noPreviewFS:Show()
            return
        end
        viewer.previewTex:SetTexture(icon)
        viewer.previewTex:Show()
        viewer.modeFS:SetText("|cff555555Icône de l'item|r")
        return
    end

    viewer.noPreviewFS:Show()
end

-- ── Positionnement ancré ──────────────────────────────────────────────────────
local function PositionViewer(anchor)
    viewer:ClearAllPoints()
    if not anchor then
        viewer:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
        return
    end
    local screenW = GetScreenWidth()
    local anchorX = anchor:GetCenter()
    if anchorX + 40 + viewer:GetWidth() < screenW then
        viewer:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    else
        viewer:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
    end
end

-- ── Points d'entrée publics ───────────────────────────────────────────────────
function pluginNs.OpenModelViewer(recipe, anchor)
    local v = CreateModelViewer()
    v.titleFS:SetText(recipe.name or "Aperçu")
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(recipe.itemID))
                 or (GetItemIcon and GetItemIcon(recipe.itemID))
    v.itemIconTex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    PositionViewer(anchor)
    LoadRecipe(recipe)
    v:Show()
    v:Raise()
end

function pluginNs.HideModelViewer()
    if viewer then
        viewer:Hide()
        ClearView()
    end
end

-- ── Événements ────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, ScanHousingCatalog)  -- légère pause pour que le catalog soit chargé
    end
end)

-- ── /pvlscan : dump complet des infos catalog pour nos recettes ───────────────
-- Utile pour voir exactement ce que Blizzard retourne pour chaque decorID
SLASH_PVLSCAN1 = "/pvlscan"
SlashCmdList["PVLSCAN"] = function()
    if not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        print("|cffff4444PVL:|r C_HousingCatalog non disponible")
        return
    end
    print("|cffffff00PVL Scan du catalogue housing :|r")
    local count = 0
    if pluginNs.RECIPE_DEFINITIONS then
        for profName, profData in pairs(pluginNs.RECIPE_DEFINITIONS) do
            for xpac, xpacData in pairs(profData) do
                for _, recipe in ipairs(xpacData) do
                    if recipe.decorID then
                        local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByRecordID, 1, recipe.decorID, true)
                        if ok and info then
                            local fields = {}
                            for k, v in pairs(info) do
                                if type(v) == "number" and v > 0 then
                                    table.insert(fields, k .. "=" .. v)
                                end
                            end
                            print(string.format("  [%d] %s → %s", recipe.decorID, recipe.name or "?", table.concat(fields, ", ")))
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    print(string.format("|cffffff00%d entrées scannées|r", count))
end

-- ── /pvlmodel : debug d'un item précis ───────────────────────────────────────
SLASH_PVLMODEL1 = "/pvlmodel"
SlashCmdList["PVLMODEL"] = function(input)
    local decorID = tonumber(input)
    if not decorID then
        -- Si le viewer est ouvert, dump le modèle actuel
        if viewer and viewer.model and viewer.model:IsShown() then
            local fid = viewer.model:GetModelFileID()
            print("|cffffff00PVL:|r fileID du modèle affiché : " .. tostring(fid))
            if fid and ProfessionViewerLogFileIDs then
                print("  → Ajoutez fileID = " .. fid .. " dans MODEL_POSITIONS pour calibrer la caméra")
            end
        else
            print("|cffffff00/pvlmodel|r <decorID> — dump les infos d'un decorID")
        end
        return
    end
    if not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        print("C_HousingCatalog non disponible"); return
    end
    local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByRecordID, 1, decorID, true)
    print("|cffffff00PVL decorID " .. decorID .. " :|r")
    if ok and info then
        for k, v in pairs(info) do
            print("  " .. k .. " = " .. tostring(v))
        end
    else
        print("  Pas de données (decorID inconnu ou catalog non chargé)")
    end
end
