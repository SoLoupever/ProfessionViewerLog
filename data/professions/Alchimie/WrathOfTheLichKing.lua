local addonName, pluginNs = ...

-- ====================================================
-- Alchimie — Wrath of the Lich King
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
pluginNs.RECIPE_DEFINITIONS["Alchimie"] = pluginNs.RECIPE_DEFINITIONS["Alchimie"] or {}
pluginNs.RECIPE_DEFINITIONS["Alchimie"]["Wrath of the Lich King"] = {
    { name = "Peste en boîte de la Couronne de glace", itemID = 258213, spellID = 1263559, decorID = 11901 },
    { name = "Bougeoir solaire de Dalaran", itemID = 264710, spellID = 1272614, decorID = 16087 },
    { name = "Orbe de sang san'lay", itemID = 258212, spellID = 1263558, decorID = 11900 },
}
