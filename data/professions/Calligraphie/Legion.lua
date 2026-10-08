local addonName, pluginNs = ...

-- ====================================================
-- Calligraphie — Legion
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
pluginNs.RECIPE_DEFINITIONS["Calligraphie"]["Legion"] = {
    { itemID = 245396, spellID = 1260737, decorID = 1219 },
    { itemID = 258224, spellID = 1263344, decorID = 11910 },
    { itemID = 247916, spellID = 1260711, decorID = 4030 },
    { itemID = 247925, spellID = 1260730, decorID = 4039 },
    { itemID = 247918, spellID = 1260719, decorID = 4032 },
    { itemID = 245459, spellID = 1260704, decorID = 1308 },
}
