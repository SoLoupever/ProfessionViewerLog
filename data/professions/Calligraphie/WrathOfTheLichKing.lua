local addonName, pluginNs = ...

-- ====================================================
-- Calligraphie — Wrath of the Lich King
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
pluginNs.RECIPE_DEFINITIONS["Calligraphie"]["Wrath of the Lich King"] = {
    { itemID = 258209, spellID = 1263574, decorID = 11897 },
    { itemID = 258204, spellID = 1263575, decorID = 11892 },
    { itemID = 258207, spellID = 1263570, decorID = 11895 },
    { itemID = 258210, spellID = 1263564, decorID = 11898 },
    { itemID = 258203, spellID = 1263562, decorID = 11891 },
}
