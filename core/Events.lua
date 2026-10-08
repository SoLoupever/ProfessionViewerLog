local addonName, ns = ...
local core = ns.core

-- ====================================================
-- COMMANDES SLASH
-- ====================================================
SLASH_PVLOG1 = "/pvl"
SLASH_PVLOG2 = "/professionviewerlog"
SlashCmdList["PVLOG"] = function(msg)
    local mainFrame = core.mainFrame
    msg = msg and strtrim(msg:lower()) or ""

    if msg == "scan" then
        ns.ScanAllProfessions()
    elseif msg == "settings" then
        ns.isViewActive = false
        ns.ShowSettings()
        mainFrame:Show()
    elseif msg == "minimap" then
        if ProfessionViewerLogDB and ProfessionViewerLogDB.minimap then
            ProfessionViewerLogDB.minimap.hide = false
        end
        local LibDBIcon = LibStub("LibDBIcon-1.0", true)
        if LibDBIcon and LibDBIcon:IsRegistered("ProfessionViewerLog") then
            LibDBIcon:Show("ProfessionViewerLog")
            print("|cffffd700[ProfessionViewerLog]|r Bouton minimap affiché.")
        else
            print("|cffffd700[ProfessionViewerLog]|r Tapez /reload pour réafficher le bouton.")
        end
    else
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            ns.isViewActive = true
            ns.ShowProfessions()
            mainFrame:Show()
        end
    end
end

-- ====================================================
-- PLAYER_LOGIN
-- ====================================================
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    local mainFrame = core.mainFrame

    core.player = UnitName("player")
    core.realm  = GetRealmName()

    -- Initialise les données du personnage courant
    ProfessionViewerLogDB[core.realm] = ProfessionViewerLogDB[core.realm] or {}
    ProfessionViewerLogDB[core.realm][core.player] = ProfessionViewerLogDB[core.realm][core.player] or {}

    local cd = ProfessionViewerLogDB[core.realm][core.player]
    cd.class       = select(2, UnitClass("player"))
    cd.level       = UnitLevel("player")
    cd.professions = cd.professions or {}

    -- Langue sauvegardée (prioritaire sur la locale client)
    if ProfessionViewerLogDB.lang then
        core.SetLang(ProfessionViewerLogDB.lang)
    end

    -- Restaure la taille de fenêtre sauvegardée
    ProfessionViewerLogDB.settings = ProfessionViewerLogDB.settings or {}
    local w = ProfessionViewerLogDB.settings.frameWidth  or core.DEFAULT_FRAME_W
    local h = ProfessionViewerLogDB.settings.frameHeight or core.DEFAULT_FRAME_H
    mainFrame:SetSize(w, h)

    -- Applique le thème (migre les anciens thèmes vers "profession")
    core.ApplyTheme(core.GetThemeKey())

    -- Initialise la minimap
    core.InitMinimap()

    if ProfessionViewerLogDB.debugVerbose then
        print("|cffffd700[ProfessionViewerLog]|r Chargé — |cffffff00/pvl|r pour ouvrir.")
    end
end)

-- ====================================================
-- PLAYER_LEVEL_UP
-- ====================================================
local levelFrame = CreateFrame("Frame")
levelFrame:RegisterEvent("PLAYER_LEVEL_UP")
levelFrame:SetScript("OnEvent", function(_, _, newLevel)
    if core.realm and core.player
    and ProfessionViewerLogDB[core.realm]
    and ProfessionViewerLogDB[core.realm][core.player] then
        ProfessionViewerLogDB[core.realm][core.player].level = newLevel
    end
end)
