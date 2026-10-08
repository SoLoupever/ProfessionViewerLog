local addonName, pluginNs = ...

-- ====================================================
-- Travail du cuir — Midnight
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
pluginNs.RECIPE_DEFINITIONS["Travail du cuir"]["Midnight"] = {
    { name = "Lit à baldaquin haranir", itemID = 265791, spellID = 1246939, decorID = 17515 },
    { name = "Tapis en fourrure sin’dorei estampé", itemID = 262449, spellID = 1246937, decorID = 14579 },
    { name = "Oreiller luxueux haranir en cuir", itemID = 264244, spellID = 1246943, decorID = 15479 },
    { name = "Tapis raccommodé haranir", itemID = 262600, spellID = 1246941, decorID = 14625 },
    { name = "Chaise robuste haranir", itemID = 243090, spellID = 1246942, decorID = 1157 },
    { name = "Table haranir simple", itemID = 262589, spellID = 1246940, decorID = 14615 },
    { name = "Étagère murale haranir en cuir", itemID = 253457, spellID = 1246938, decorID = 1142 },
    { itemID = 275332, spellID = 1296509, decorID = 17800 },
    { itemID = 279348, spellID = 1296511, decorID = 26363 },
    { itemID = 279346, spellID = 1296510, decorID = 26378 },
}
