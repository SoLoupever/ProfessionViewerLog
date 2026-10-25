local addonName, ns = ...
local core = ns.core

-- Reprise unique de l'ancienne ProfessionViewerLogDB vers ViewerLog :
--   · préférences → stockage du module "pvl"
--   · personnages → ViewerLog (professions, paliers manuels, recettes connues)
-- La base héritée est ensuite vidée (marqueur migrated).

local PREF_KEYS = {
    "settings", "lang", "hiddenExpansions", "hiddenProfessions", "minimap",
    "debugVerbose", "disable2DPreview", "woodPanelEnabled",
}
local NOT_REALM = { warbandBank = true, migrated = true }
for _, k in ipairs(PREF_KEYS) do NOT_REALM[k] = true end

local function CopyTable(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = CopyTable(v) end
    return out
end

local function FindByName(list, name)
    for _, e in ipairs(list) do
        if e.name == name then return e end
    end
end

local function MergeProfession(target, legacy)
    if legacy.scanned and not target.scanned then
        target.tiers    = CopyTable(legacy.tiers or {})
        target.scanned  = true
        target.lastScan = legacy.lastScan
    else
        target.tiers = target.tiers or {}
        for _, t in ipairs(legacy.tiers or {}) do
            if t.manual and not FindByName(target.tiers, t.name) then
                target.tiers[#target.tiers + 1] = CopyTable(t)
            end
        end
    end
    if next(legacy.knownRecipes or {}) and not next(target.knownRecipes or {}) then
        target.knownRecipes = CopyTable(legacy.knownRecipes)
    end
end

local function MergeCharacter(target, legacy)
    target.professions = target.professions or {}
    for _, lp in ipairs(legacy.professions) do
        local tp = FindByName(target.professions, lp.name)
        if tp then
            MergeProfession(tp, lp)
        else
            target.professions[#target.professions + 1] = CopyTable(lp)
        end
    end
end

function ns.MigrateLegacy()
    local old = _G.ProfessionViewerLogDB
    if type(old) ~= "table" or old.migrated then return end

    local vl = _G.ViewerLogAPI
    if not (vl and vl.EnsureCharacter) then return end

    local prefs = core.Prefs()
    for _, key in ipairs(PREF_KEYS) do
        if old[key] ~= nil and prefs[key] == nil then prefs[key] = old[key] end
    end

    for realm, realmData in pairs(old) do
        if type(realmData) == "table" and not NOT_REALM[realm] then
            for char, data in pairs(realmData) do
                if type(data) == "table" and data.professions then
                    local target = vl.GetCharacter(char, realm)
                    if not target then
                        target       = vl.EnsureCharacter(char, realm)
                        target.class = data.class
                        target.level = data.level
                    end
                    MergeCharacter(target, data)
                end
            end
        end
    end

    wipe(old)
    old.migrated = true
end
