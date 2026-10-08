local addonName, pluginNs = ...

-- ====================================================
-- Calligraphie — Burning Crusade
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
pluginNs.RECIPE_DEFINITIONS["Calligraphie"]["Burning Crusade"] = {
    { itemID = 258198, spellID = 1263811, decorID = 11886 },
    { itemID = 258197, spellID = 1263813, decorID = 11885 },
    { itemID = 258215, spellID = 1263812, decorID = 11903 },
    { itemID = 258192, spellID = 1263814, decorID = 11880 },
    { itemID = 258199, spellID = 1263810, decorID = 11887 },
}
