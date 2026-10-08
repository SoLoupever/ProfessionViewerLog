local addonName, pluginNs = ...

-- ====================================================
-- Joaillerie — Mists of Pandaria
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
pluginNs.RECIPE_DEFINITIONS["Joaillerie"] = pluginNs.RECIPE_DEFINITIONS["Joaillerie"] or {}
pluginNs.RECIPE_DEFINITIONS["Joaillerie"]["Mists of Pandaria"] = {
    { name = "Mur pandaren en pierre", itemID = 245509, spellID = 1261243, decorID = 1194 },
    { name = "Fontaine draconique du temple de Jade", itemID = 247736, spellID = 1261242, decorID = 3876 },
    { name = "Poteau pandaren en pierre", itemID = 247728, spellID = 1261244, decorID = 3868 },
}
