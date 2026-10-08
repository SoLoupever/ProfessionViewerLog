local addonName, pluginNs = ...

-- ====================================================
-- Joaillerie — Midnight
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
pluginNs.RECIPE_DEFINITIONS["Joaillerie"]["Midnight"] = {
    { name = "Statue bien-née resplendissante", itemID = 248965, spellID = 1246892, decorID = 5133 },
    { name = "Lyre sin’dorei ornée de joyaux", itemID = 262471, spellID = 1246891, decorID = 14601 },
    { name = "Harpe de phénix brillante", itemID = 262469, spellID = 1246895, decorID = 14599 },
    { name = "Sphère armillaire ren’dorei ténébreuse", itemID = 262461, spellID = 1246889, decorID = 14591 },
    { name = "Réplique de fresque haranir", itemID = 262613, spellID = 1246893, decorID = 14638 },
    { name = "Sablier sin’dorei brillant", itemID = 262454, spellID = 1246894, decorID = 14584 },
    { itemID = 279356, spellID = 1297679, decorID = 26488 },
    { itemID = 279343, spellID = 1297680, decorID = 26489 },
    { itemID = 280762, spellID = 1297681, decorID = 26490 },
}
