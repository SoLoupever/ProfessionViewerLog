local addonName, pluginNs = ...

-- ====================================================
-- Calligraphie — Shadowlands
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
pluginNs.RECIPE_DEFINITIONS["Calligraphie"]["Shadowlands"] = {
    { itemID = 258250, spellID = 1263243, decorID = 11927 },
    { itemID = 258244, spellID = 1263241, decorID = 11923 },
    { itemID = 258239, spellID = 1263285, decorID = 11920 },
    { itemID = 258247, spellID = 1263278, decorID = 11925 },
    { itemID = 258245, spellID = 1263247, decorID = 11924 },
    { itemID = 258235, spellID = 1263272, decorID = 11917 },
    { itemID = 258242, spellID = 1263293, decorID = 11922 },
}
