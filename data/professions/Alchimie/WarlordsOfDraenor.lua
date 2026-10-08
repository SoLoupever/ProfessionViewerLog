local addonName, pluginNs = ...

-- ====================================================
-- Alchimie — Warlords of Draenor
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
pluginNs.RECIPE_DEFINITIONS["Alchimie"] = pluginNs.RECIPE_DEFINITIONS["Alchimie"] or {}
pluginNs.RECIPE_DEFINITIONS["Alchimie"]["Warlords of Draenor"] = {
    { name = "Chaudron orc gangresang", itemID = 257044, spellID = 1262011, decorID = 11379 },
    { name = "Tonneau de vin", itemID = 244318, spellID = 1260985, decorID = 1410 },
}
