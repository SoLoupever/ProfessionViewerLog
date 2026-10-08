local addonName, pluginNs = ...

-- ====================================================
-- Ingénierie — Midnight
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
pluginNs.RECIPE_DEFINITIONS["Ingénierie"] = pluginNs.RECIPE_DEFINITIONS["Ingénierie"] or {}
pluginNs.RECIPE_DEFINITIONS["Ingénierie"]["Midnight"] = {
    { itemID = 262602, spellID = 1248616, decorID = 14627 },
    { itemID = 262618, spellID = 1248610, decorID = 14643 },
    { itemID = 262465, spellID = 1248613, decorID = 14595 },
    { itemID = 262789, spellID = 1248614, decorID = 14730 },
    { itemID = 263049, spellID = 1248611, decorID = 14835 },
    { itemID = 262617, spellID = 1248615, decorID = 14642 },
    { itemID = 246460, spellID = 1248612, decorID = 2301 },
    { itemID = 279341, spellID = 1296503, decorID = 26372 },
    { itemID = 279337, spellID = 1296501, decorID = 26383 },
    { itemID = 279339, spellID = 1296502, decorID = 26485 },
}
