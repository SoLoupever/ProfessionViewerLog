local addonName, pluginNs = ...

-- ====================================================
-- Travail du cuir — Cataclysm
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
pluginNs.RECIPE_DEFINITIONS["Travail du cuir"]["Cataclysm"] = {
    { name = "Mosaïque du Crépuscule en écailles", itemID = 257806, spellID = 1269550, decorID = 11779 },
    { name = "Tapis scarabée roulé", itemID = 264677, spellID = 1272588, decorID = 16013 },
    { name = "Selle de rechange gilnéenne", itemID = 264712, spellID = 1272580, decorID = 16089 },
}
