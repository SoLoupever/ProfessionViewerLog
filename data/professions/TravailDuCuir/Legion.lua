local addonName, pluginNs = ...

-- ====================================================
-- Travail du cuir — Legion
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
pluginNs.RECIPE_DEFINITIONS["Travail du cuir"]["Legion"] = {
    { name = "Clôture taurène en cuir", itemID = 245406, spellID = 1260762, decorID = 1242 },
    { name = "Piquet tauren", itemID = 245407, spellID = 1260765, decorID = 1243 },
    { name = "Cadre de tannerie de Haut-Roc", itemID = 257400, spellID = 1262273, decorID = 11490 },
}
