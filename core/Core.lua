local addonName, ns = ...

-- ====================================================
-- BASE DE DONNÉES
-- ====================================================
ProfessionViewerLogDB = ProfessionViewerLogDB or {}

-- ====================================================
-- NAMESPACE PRINCIPAL
-- ====================================================
local core = {}
ns.core = core

core.player = nil
core.realm  = nil

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
    SETTINGS_TITLE         = "Gestion des personnages",
    SETTINGS_DESC          = "Supprime un personnage et toutes ses données.",
    SETTINGS_DELETE        = "Supprimer",
    SETTINGS_CONFIRM       = "Confirmer la suppression de :",
    SETTINGS_YES           = "Oui, supprimer",
    SETTINGS_NO            = "Annuler",
    SETTINGS_EMPTY         = "Aucun personnage enregistré.",
    SETTINGS_RESET_BTN     = "Réinitialiser toutes les données",
    SETTINGS_RESET_CONFIRM = "Réinitialiser TOUTES les données ?",
    SETTINGS_RESET_YES     = "Oui, tout effacer",
    AUTOSCAN_MSG           = "|cffffd700[ProfessionViewerLog]|r Premier scan des métiers...",
    SETTINGS_2D_ON         = "Aperçu 2D : Activé",
    SETTINGS_2D_OFF        = "Aperçu 2D : Désactivé",
    FILTER_POPUP_TITLE     = "Filtrer les extensions",
    FILTER_TOOLTIP         = "Filtrer par extension",
    WOOD_SECTION_TITLE     = "Bois (Warband)",
    WOOD_PANEL_TITLE       = "Bois",
    WOOD_OPEN_WARBAND      = "Ouvrez votre Banque de Clan pour lire le stock.",
}

function core.L(key)
    -- Les fichiers locales/Locales_*.lua injectent core.L_override après chargement
    local ov = core.L_override
    if ov and ov[key] then return ov[key] end
    return L_strings[key] or key
end

-- ── Changement de langue manuel ───────────────────────────────────────────────
function core.SetLang(lang)
    ProfessionViewerLogDB.lang = lang
    if lang == "enUS" and ns.L_enUS then
        core.L_override = ns.L_enUS
    elseif lang == "frFR" and ns.L_frFR then
        core.L_override = ns.L_frFR
    end
    -- Retraduit les boutons sidebar dans la nouvelle langue
    C_Timer.After(0, core.RefreshSidebarStyle)
    core.InvalidateSettings()
end
