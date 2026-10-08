local addonName, pluginNs = ...

-- ====================================================
-- Calligraphie — Classic
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
pluginNs.RECIPE_DEFINITIONS["Calligraphie"]["Classic"] = {
    { itemID = 246420, spellID = 1261587, decorID = 2237 },
    { itemID = 246423, spellID = 1261644, decorID = 2240 },
    { itemID = 258289, spellID = 1269495, decorID = 11935 },
    { itemID = 245502, spellID = 1261572, decorID = 854 },
    { itemID = 245503, spellID = 1261549, decorID = 922 },
}
