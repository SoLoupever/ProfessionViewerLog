local addonName, ns = ...
local core = ns.core
local vl   = _G.ViewerLogAPI

-- ====================================================
-- COMMANDES SLASH
-- ====================================================
SLASH_PVLOG1 = "/pvl"
SLASH_PVLOG2 = "/professionviewerlog"
SlashCmdList["PVLOG"] = function(msg)
    local mainFrame = core.mainFrame
    msg = msg and strtrim(msg:lower()) or ""

    if msg == "scan" then
        if vl.ScanAllProfessions then vl.ScanAllProfessions() end
    elseif msg == "settings" then
        ns.isViewActive = false
        ns.ShowSettings()
        mainFrame:Show()
    elseif msg == "minimap" then
        local minimap = core.Prefs().minimap
        if minimap then minimap.hide = false end
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
-- RAFRAÎCHISSEMENT : ViewerLog_Professions notifie après chaque scan.
-- ====================================================
if vl.RegisterProfessionsCallback then
    vl.RegisterProfessionsCallback(function()
        if ns.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
            ns.ShowProfessions()
        end
    end)
end

-- ====================================================
-- PLAYER_LOGIN
-- ====================================================
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    local mainFrame = core.mainFrame
    local prefs     = core.Prefs()

    core.player = UnitName("player")
    core.realm  = GetRealmName()

    -- Reprise unique de l'ancienne base ProfessionViewerLogDB.
    ns.MigrateLegacy()

    -- Langue sauvegardée (prioritaire sur la locale client)
    if prefs.lang then
        core.SetLang(prefs.lang)
    end

    -- Restaure la taille de fenêtre sauvegardée
    prefs.settings = prefs.settings or {}
    local w = prefs.settings.frameWidth  or core.DEFAULT_FRAME_W
    local h = prefs.settings.frameHeight or core.DEFAULT_FRAME_H
    mainFrame:SetSize(w, h)

    -- Applique le thème (migre les anciens thèmes vers "profession")
    core.ApplyTheme(core.GetThemeKey())

    -- Initialise la minimap
    core.InitMinimap()

    if prefs.debugVerbose then
        print("|cffffd700[ProfessionViewerLog]|r Chargé — |cffffff00/pvl|r pour ouvrir.")
    end
end)
