local addonName, pluginNs = ...

-- ====================================================
-- Calligraphie — Warlords of Draenor
-- data/professions/<Métier>/<Extension>.lua
-- Un dossier par métier, un fichier par extension — même rangement
-- que ViewerLog_Housing. Ce fichier se contente d'enregistrer ses
-- recettes dans pluginNs.RECIPE_DEFINITIONS, sans dépendance directe
-- vers un autre module (aucun effet domino).
--
-- name    : repli d'affichage si GetItemInfo(itemID) n'est pas en cache
-- itemID  : ID de l'objet fabriqué (clé de stockage + icône)
-- spellID : ID du sort — détection auto via IsPlayerSpell (blizz/Scanner.lua)
-- decorID : (optionnel) ID décoration logement, fallback 2D (blizz/ModelViewer.lua)
-- ====================================================

pluginNs.RECIPE_DEFINITIONS = pluginNs.RECIPE_DEFINITIONS or {}
pluginNs.RECIPE_DEFINITIONS["Calligraphie"] = pluginNs.RECIPE_DEFINITIONS["Calligraphie"] or {}
pluginNs.RECIPE_DEFINITIONS["Calligraphie"]["Warlords of Draenor"] = {
    { itemID = 245441, spellID = 1269501, decorID = 1351 },
    { itemID = 245534, spellID = 1261032, decorID = 1725 },
    { itemID = 244313, spellID = 1269500, decorID = 1405 },
    { itemID = 244317, spellID = 1261066, decorID = 1409 },
    { itemID = 244319, spellID = 1261045, decorID = 1411 },
}
