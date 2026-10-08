local addonName, pluginNs = ...

-- ====================================================
-- Travail du cuir — Battle for Azeroth
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
pluginNs.RECIPE_DEFINITIONS["Travail du cuir"] = pluginNs.RECIPE_DEFINITIONS["Travail du cuir"] or {}
pluginNs.RECIPE_DEFINITIONS["Travail du cuir"]["Battle for Azeroth"] = {
    { name = "Tambour rituel zandalari", itemID = 245412, spellID = 1260485, decorID = 1241 },
    { name = "Bannière de diplomate furie-des-sables", itemID = 258558, spellID = 1263859, decorID = 12162 },
}
