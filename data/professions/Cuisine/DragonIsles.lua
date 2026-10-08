local addonName, pluginNs = ...

-- ====================================================
-- Cuisine — Dragon Isles
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
pluginNs.RECIPE_DEFINITIONS["Cuisine"] = pluginNs.RECIPE_DEFINITIONS["Cuisine"] or {}
pluginNs.RECIPE_DEFINITIONS["Cuisine"]["Dragon Isles"] = {
    { name = "Côtes de bruffalon", itemID = 247225, spellID = 1260333, decorID = 2596 },
    { name = "Plat de brochettes de drake", itemID = 247222, spellID = 1266555, decorID = 2593 },
    { name = "Plat de fruits de fleurs de Valdrakken", itemID = 247224, spellID = 1260331, decorID = 2595 },
}
