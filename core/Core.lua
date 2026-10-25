local addonName, ns = ...

-- ====================================================
-- NAMESPACE PRINCIPAL
-- ====================================================
local core = {}
ns.core = core

core.player = nil
core.realm  = nil

-- ====================================================
-- DONNÉES — tout passe par ViewerLogAPI
-- Personnages et métiers : ViewerLog (+ ViewerLog_Professions).
-- Préférences d'affichage : stockage du module "pvl".
-- ====================================================
local vl = _G.ViewerLogAPI

-- Préférences (thème, filtres, taille, minimap…).
function core.Prefs()
    return vl.GetModuleData("pvl")
end

function core.GetChar(realm, char)
    return vl.GetCharacter(char, realm)
end

-- cb(realm, char, data) pour chaque personnage connu de ViewerLog.
function core.ForEachChar(cb)
    vl.ForEachCharacter(function(char, realm, data) cb(realm, char, data) end)
end

-- Bois : fournis par ViewerLog_Professions ; vides s'il est absent.
-- Ordre des clés = ordre de GetWoodExpansions (ancien → récent).
local WOOD_EXP_KEYS = {
    "EXP_CLASSIC", "EXP_BC", "EXP_WOTLK", "EXP_CATA", "EXP_MOP", "EXP_WOD",
    "EXP_LEGION", "EXP_BFA", "EXP_SL", "EXP_DF", "EXP_KA", "EXP_MIDNIGHT",
}

function core.WoodCounts()
    if vl.GetWoodCounts then return vl.GetWoodCounts() end
    return 0, {}
end

function core.WoodExpansions()
    return vl.GetWoodExpansions and vl.GetWoodExpansions() or {}
end

function core.WoodItemName(id)
    return vl.GetWoodItemName and vl.GetWoodItemName(id) or "?"
end

function core.WoodExpansionLabel(index, block)
    local key = WOOD_EXP_KEYS[index]
    return key and core.L(key) or block.expansion
end

-- Dimensions par défaut (utilisées aussi dans Events pour restaurer la taille)
core.DEFAULT_FRAME_W = 900
core.DEFAULT_FRAME_H = 600

-- ====================================================
-- FLAG DE RECONSTRUCTION DES SETTINGS
-- ====================================================
local _settingsDirty = true

function core.InvalidateSettings()
    _settingsDirty = true
end

function core.IsSettingsDirty()
    return _settingsDirty
end

function core.MarkSettingsClean()
    _settingsDirty = false
end

-- ====================================================
-- LOCALISATION
-- ====================================================
local L_strings = {
    BTN_PROFESSIONS        = "Métiers",
    BTN_SETTINGS           = "Paramètres",
    SCAN_BTN               = "Scanner mes métiers",
    NO_CHARS               = "Aucun personnage avec des métiers.\nConnectez-vous et attendez le scan,\nou tapez /pvl scan",
    LEVEL_SHORT            = "Nv. ",
    SECTION_MAIN           = "Métiers principaux",
    SECTION_SECONDARY      = "Métiers secondaires",
    ADD_TIER               = "Ajouter un palier",
    POPUP_ADD              = "Ajouter un palier",
    POPUP_EDIT             = "Modifier : %s",
    POPUP_ADD_PROF         = "Ajouter à : %s",
    POPUP_EXT_LABEL        = "Extension :",
    POPUP_LEVEL            = "Niveau actuel",
    POPUP_MAX              = "Maximum",
    POPUP_PREVIEW          = "Aperçu",
    POPUP_CONFIRM          = "Confirmer",
    POPUP_CANCEL           = "Annuler",
    RECIPES_LABEL          = "Recettes  %d / %d",
    RECIPES_FOLD           = "Replier les recettes",
    RECIPES_UNFOLD         = "Voir les recettes",
    RECIPES_KNOWN          = "Connues : %d/%d",
    RECIPE_KNOWN_TT        = "|cff00ff55Recette connue|r",
    RECIPE_UNKNOWN_TT      = "|cffff4444Recette inconnue|r",
    SETTINGS_NO            = "Annuler",
    SETTINGS_RESET_BTN     = "Réinitialiser les paramètres",
    SETTINGS_RESET_CONFIRM = "Réinitialiser les paramètres ?",
    SETTINGS_RESET_YES     = "Oui, réinitialiser",
    SETTINGS_2D_ON         = "Aperçu 2D : Activé",
    SETTINGS_2D_OFF        = "Aperçu 2D : Désactivé",
    FILTER_POPUP_TITLE     = "Filtrer les extensions",
    FILTER_TOOLTIP         = "Filtrer par extension",
    WOOD_SECTION_TITLE     = "Bois (Warband)",
    WOOD_PANEL_TITLE       = "Bois",
    WOOD_OPEN_WARBAND      = "Ouvrez votre Banque de Clan pour lire le stock.",
    HOUSING_SECTION_LABEL  = "Housing %s",
}

function core.L(key)
    -- Les fichiers locales/Locales_*.lua injectent core.L_override après chargement
    local ov = core.L_override
    if ov and ov[key] then return ov[key] end
    return L_strings[key] or key
end

-- ── Changement de langue manuel ───────────────────────────────────────────────
function core.SetLang(lang)
    core.Prefs().lang = lang
    if lang == "enUS" and ns.L_enUS then
        core.L_override = ns.L_enUS
    elseif lang == "frFR" and ns.L_frFR then
        core.L_override = ns.L_frFR
    end
    -- Retraduit les boutons sidebar dans la nouvelle langue
    C_Timer.After(0, core.RefreshSidebarStyle)
    core.InvalidateSettings()
end
