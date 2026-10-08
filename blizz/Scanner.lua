local addonName, ns = ...
local pluginNs = ns
local core     = ns.core

-- Cache globals en locaux — évite lookup _G à chaque appel
local pairs, ipairs, next, type   = pairs, ipairs, next, type
local table_insert, table_remove  = table.insert, table.remove
local table_concat, string_format = table.concat, string.format
local C_TradeSkillUI              = C_TradeSkillUI
local C_Timer_After               = C_Timer.After

-- ====================================================
-- HELPER DEBUG — n'affiche que si debugVerbose activé
-- ====================================================
local function PVLDebug(msg)
    if ProfessionViewerLogDB and ProfessionViewerLogDB.debugVerbose then
        print(msg)
    end
end
-- C_SpellBook.IsSpellKnown remplace IsPlayerSpell (déprécié depuis 11.x)
local IsSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown
    or function(id) return IsPlayerSpell and IsPlayerSpell(id) or false end
local time                        = time

-- ====================================================
-- ETAT INTERNE DU SCAN SÉQUENTIEL
-- ====================================================
local scanQueue        = {}
local scanQueueIndex   = 0
local scanInProgress   = false
local AdvanceScanQueue  -- forward declaration

local function RefreshIfVisible()
    if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
        pluginNs.ShowProfessions()
    end
end

local function GetBaseSkillLineID(profName, fallbackSkillLine)
    if pluginNs.PROFESSION_BASE_IDS and pluginNs.PROFESSION_BASE_IDS[profName] then
        return pluginNs.PROFESSION_BASE_IDS[profName]
    end
    return fallbackSkillLine
end

-- ====================================================
-- HELPER : GetProfessions() une seule fois, itération
-- explicite sans table temporaire (évite ipairs({ ... }))
-- ====================================================
local function ForEachProfessionIdx(fn)
    local prof1, prof2, archeo, fishing, cooking, firstAid = GetProfessions()
    if prof1   then fn(prof1)   end
    if prof2   then fn(prof2)   end
    if archeo  then fn(archeo)  end
    if fishing then fn(fishing) end
    if cooking then fn(cooking) end
    if firstAid then fn(firstAid) end
end

local function ForEachMainIdx(fn)
    local prof1, prof2 = GetProfessions()
    if prof1 then fn(prof1) end
    if prof2 then fn(prof2) end
end

-- ====================================================
-- COLLECTE DES SLOTS
-- ====================================================
local function CollectAllProfessionSlots()
    local slots = {}
    local prof1, prof2, archeo, fishing, cooking, firstAid = GetProfessions()

    local function addSlot(idx, isSecondary)
        if not idx then return end
        local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(idx)
        if name and skillLine then
            slots[#slots + 1] = {
                name         = name,
                icon         = icon,
                rank         = rank,
                maxRank      = maxRank,
                skillLine    = GetBaseSkillLineID(name, skillLine),
                rawSkillLine = skillLine,
                isSecondary  = isSecondary,
            }
        end
    end

    addSlot(prof1,    false)
    addSlot(prof2,    false)
    addSlot(archeo,   true)
    addSlot(fishing,  true)
    addSlot(cooking,  true)
    addSlot(firstAid, true)

    return slots
end

local function PurgeRemovedProfessions(charData, currentSlots)
    if not charData.professions then return end
    local currentNames = {}
    for _, slot in ipairs(currentSlots) do currentNames[slot.name] = true end

    local removed = {}
    for i = #charData.professions, 1, -1 do
        local p = charData.professions[i]
        if not currentNames[p.name] then
            removed[#removed + 1] = p.name
            table_remove(charData.professions, i)
        end
    end
    if #removed > 0 then
        PVLDebug(string_format("|cffff8800[ProfessionViewerLog]|r Métier(s) retiré(s) : %s",
            table_concat(removed, ", ")))
    end
end

local function SaveFallbackEntry(cd, slot)
    if not slot or not slot.rank or not slot.maxRank or slot.maxRank <= 0 then return end
    cd.professions = cd.professions or {}

    -- Récupère skillLineName (11ème retour) = nom du palier actuel
    local tierName = slot.name
    local prof1, prof2, archeo, fishing, cooking = GetProfessions()
    local function findTierName(idx)
        if not idx then return end
        local n, _, _, _, _, _, _, _, _, _, skillLineName = GetProfessionInfo(idx)
        if n == slot.name and skillLineName and skillLineName ~= "" then
            tierName = skillLineName
        end
    end
    findTierName(prof1); findTierName(prof2)
    findTierName(archeo); findTierName(fishing); findTierName(cooking)

    local found = false
    for _, p in ipairs(cd.professions) do
        if p.name == slot.name then
            if not p.scanned then
                p.tiers   = {{ name = tierName, level = slot.rank, max = slot.maxRank, manual = false }}
                p.scanned  = true
                p.lastScan = time()
            end
            found = true
            break
        end
    end
    if not found then
        cd.professions[#cd.professions + 1] = {
            name         = slot.name,
            icon         = slot.icon,
            skillLine    = slot.skillLine,
            rawSkillLine = slot.rawSkillLine,
            secondary    = slot.isSecondary,
            tiers        = {{ name = tierName, level = slot.rank, max = slot.maxRank, manual = false }},
            knownRecipes = {},
            scanned      = true,
            lastScan     = time(),
        }
    end
    PVLDebug(string_format("|cff00ff00[ProfessionViewerLog]|r %s sauvegardé (basique) : %d/%d",
        slot.name, slot.rank, slot.maxRank))
end

local function SaveBasicProfessionData()
    if not ProfessionViewerLogDB or not core.realm or not core.player then return end
    ProfessionViewerLogDB[core.realm] = ProfessionViewerLogDB[core.realm] or {}
    ProfessionViewerLogDB[core.realm][core.player] = ProfessionViewerLogDB[core.realm][core.player] or {}
    local charData = ProfessionViewerLogDB[core.realm][core.player]
    charData.professions = charData.professions or {}

    local slots = CollectAllProfessionSlots()
    if #slots == 0 then return end

    PurgeRemovedProfessions(charData, slots)

    for _, slot in ipairs(slots) do
        local existing = nil
        for _, p in ipairs(charData.professions) do
            if p.name == slot.name then existing = p; break end
        end
        if not existing then
            charData.professions[#charData.professions + 1] = {
                name         = slot.name,
                icon         = slot.icon,
                skillLine    = slot.skillLine,
                rawSkillLine = slot.rawSkillLine,
                secondary    = slot.isSecondary,
                tiers        = {},
                knownRecipes = {},
                basicRank    = slot.rank,
                basicMax     = slot.maxRank,
                scanned      = false,
            }
        else
            existing.icon         = slot.icon         or existing.icon
            existing.skillLine    = slot.skillLine    or existing.skillLine
            existing.rawSkillLine = slot.rawSkillLine or existing.rawSkillLine
            existing.secondary    = slot.isSecondary
            existing.basicRank    = slot.rank
            existing.basicMax     = slot.maxRank
        end
    end
end

-- ====================================================
-- SCAN COMPLET D'UNE PROFESSION OUVERTE
-- ====================================================
function pluginNs.ScanOpenProfession(optionalProfName, optionalSlot)
    if not ProfessionViewerLogDB or not core.realm or not core.player then return end

    ProfessionViewerLogDB[core.realm][core.player] = ProfessionViewerLogDB[core.realm][core.player] or {}
    local charData = ProfessionViewerLogDB[core.realm][core.player]
    charData.professions = charData.professions or {}

    local profName = optionalProfName

    if not profName and C_TradeSkillUI.GetTradeSkillDisplayName then
        profName = C_TradeSkillUI.GetTradeSkillDisplayName()
    end

    if not profName then
        local currentLine = C_TradeSkillUI.GetTradeSkillLine and C_TradeSkillUI.GetTradeSkillLine()
        if currentLine then
            local prof1, prof2, archeo, fishing, cooking = GetProfessions()
            local function findName(idx)
                if not idx or profName then return end
                local name, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
                if skillLine == currentLine
                or (name and pluginNs.PROFESSION_BASE_IDS[name] == currentLine) then
                    profName = name
                end
            end
            findName(prof1); findName(prof2); findName(archeo)
            findName(fishing); findName(cooking)
        end
    end

    if not profName then
        if scanInProgress then AdvanceScanQueue() end
        return
    end

    -- Récupère icône/skillLine en une seule passe GetProfessions()
    local profIcon, profSkillLine, profRawSkillLine, profSecondary
    if optionalSlot and optionalSlot.name == profName then
        profIcon         = optionalSlot.icon
        profSkillLine    = optionalSlot.skillLine
        profRawSkillLine = optionalSlot.rawSkillLine
        profSecondary    = optionalSlot.isSecondary
    else
        local prof1, prof2, archeo, fishing, cooking = GetProfessions()
        local function findMeta(idx)
            if not idx or profIcon then return end
            local name, icon, _, _, _, _, skillLine = GetProfessionInfo(idx)
            if name == profName then
                profIcon         = icon
                profSkillLine    = GetBaseSkillLineID(name, skillLine)
                profRawSkillLine = skillLine
                profSecondary    = (idx ~= prof1 and idx ~= prof2)
            end
        end
        findMeta(prof1); findMeta(prof2); findMeta(archeo)
        findMeta(fishing); findMeta(cooking)
    end

    -- Collecte des paliers (une seule passe GetProfessions() pour le fallback)
    local autoTiers = {}

    local childInfos = C_TradeSkillUI.GetChildProfessionInfos and C_TradeSkillUI.GetChildProfessionInfos()
    if childInfos and #childInfos > 0 then
        for _, info in ipairs(childInfos) do
            if (info.maxSkillLevel or 0) > 0 then
                autoTiers[#autoTiers + 1] = {
                    name   = info.professionName or profName,
                    level  = info.skillLevel   or 0,
                    max    = info.maxSkillLevel or 1,
                    manual = false,
                }
            end
        end
    end

    if #autoTiers == 0 then
        local ok, tiers = pcall(C_TradeSkillUI.GetProfessionTiers)
        if ok and tiers and #tiers > 0 then
            for _, tierID in ipairs(tiers) do
                local ok2, info = pcall(C_TradeSkillUI.GetProfessionTierInfo, tierID)
                if ok2 and info and (info.maxSkillLevel or 0) > 0 then
                    autoTiers[#autoTiers + 1] = {
                        name   = info.name or profName,
                        level  = info.skillLevel   or 0,
                        max    = info.maxSkillLevel or 1,
                        tierID = tierID,
                        manual = false,
                    }
                end
            end
        end
    end

    -- Fallback GetProfessionInfo — une seule passe GetProfessions()
    if #autoTiers == 0 then
        local prof1, prof2, archeo, fishing, cooking = GetProfessions()
        local function findTier(idx)
            if not idx or #autoTiers > 0 then return end
            local name, _, rank, maxRank, _, _, _, _, _, _, skillLineName = GetProfessionInfo(idx)
            if name == profName and maxRank and maxRank > 0 then
                autoTiers[#autoTiers + 1] = {
                    name   = (skillLineName and skillLineName ~= "") and skillLineName or profName,
                    level  = rank or 0,
                    max    = maxRank,
                    manual = false,
                }
            end
        end
        findTier(prof1); findTier(prof2); findTier(archeo)
        findTier(fishing); findTier(cooking)
    end

    if #autoTiers == 0 then
        if scanInProgress then AdvanceScanQueue() end
        return
    end

    local existingEntry = nil
    for _, p in ipairs(charData.professions) do
        if p.name == profName then existingEntry = p; break end
    end

    local manualTiers, knownRecipes = {}, {}
    if existingEntry then
        for _, t in ipairs(existingEntry.tiers or {}) do
            if t.manual then manualTiers[#manualTiers + 1] = t end
        end
        knownRecipes = existingEntry.knownRecipes or {}
    end

    -- Lookup batch des recettes connues
    if pluginNs.RECIPE_DEFINITIONS then
        local defKey = (pluginNs.PROF_RECIPE_KEY and pluginNs.PROF_RECIPE_KEY[profName]) or profName
        if pluginNs.RECIPE_DEFINITIONS[defKey] then
            local learnedSpellIDs = {}
            local allIDs = C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetAllRecipeIDs()
            if allIDs then
                for _, spellID in ipairs(allIDs) do
                    local rInfo = C_TradeSkillUI.GetRecipeInfo(spellID)
                    if rInfo and rInfo.learned then learnedSpellIDs[spellID] = true end
                end
            end
            local hasLearnedData = next(learnedSpellIDs) ~= nil

            for _, recipes in pairs(pluginNs.RECIPE_DEFINITIONS[defKey]) do
                for _, recipe in ipairs(recipes) do
                    if recipe.spellID and recipe.spellID > 0 then
                        knownRecipes[recipe.itemID] = hasLearnedData
                            and (learnedSpellIDs[recipe.spellID] or false)
                            or  IsSpellKnown(recipe.spellID) or false
                    end
                end
            end
        end
    end

    local finalTiers, seenNames = {}, {}
    for _, t in ipairs(autoTiers) do
        if not seenNames[t.name] then
            seenNames[t.name] = true
            finalTiers[#finalTiers + 1] = t
        end
    end
    for _, t in ipairs(manualTiers) do
        if not seenNames[t.name] then finalTiers[#finalTiers + 1] = t end
    end

    -- basicRank/basicMax en une seule passe GetProfessions()
    local basicRank, basicMax = (existingEntry and existingEntry.basicRank or 0),
                                (existingEntry and existingEntry.basicMax  or 1)
    do
        local p1, p2, ar, fi, co = GetProfessions()
        local function findRank(idx)
            if not idx then return end
            local n, _, r, mx = GetProfessionInfo(idx)
            if n == profName and mx and mx > 0 then
                basicRank = r or 0
                basicMax  = mx
            end
        end
        findRank(p1); findRank(p2); findRank(ar); findRank(fi); findRank(co)
    end

    local newEntry = {
        name         = profName,
        icon         = profIcon         or (existingEntry and existingEntry.icon),
        skillLine    = profSkillLine    or (existingEntry and existingEntry.skillLine),
        rawSkillLine = profRawSkillLine or (existingEntry and existingEntry.rawSkillLine),
        secondary    = profSecondary,
        tiers        = finalTiers,
        knownRecipes = knownRecipes,
        scanned      = true,
        lastScan     = time(),
        basicRank    = basicRank,
        basicMax     = basicMax,
    }

    local found = false
    for i, p in ipairs(charData.professions) do
        if p.name == profName then charData.professions[i] = newEntry; found = true; break end
    end
    if not found then charData.professions[#charData.professions + 1] = newEntry end

    local tierNames = {}
    for _, t in ipairs(autoTiers) do
        tierNames[#tierNames + 1] = string_format("%s %d/%d", t.name, t.level, t.max)
    end
    PVLDebug(string_format("|cff00ff00[ProfessionViewerLog]|r %s scanné : %s",
        profName, table_concat(tierNames, " | ")))

    RefreshIfVisible()
    if scanInProgress then AdvanceScanQueue() end
end

-- ====================================================
-- FILE DE SCAN SÉQUENTIELLE
-- ====================================================
AdvanceScanQueue = function()
    scanQueueIndex = scanQueueIndex + 1
    if scanQueueIndex > #scanQueue then
        scanInProgress = false
        scanQueue      = {}
        scanQueueIndex = 0
        PVLDebug("|cff00ff00[ProfessionViewerLog]|r Scan complet terminé.")
        RefreshIfVisible()
        return
    end

    local entry        = scanQueue[scanQueueIndex]
    local currentIndex = scanQueueIndex
    PVLDebug(string_format("|cff00aaff[ProfessionViewerLog]|r En attente d'ouverture : %s...", entry.name))

    local alreadyOpen = C_TradeSkillUI.IsTradeSkillReady and C_TradeSkillUI.IsTradeSkillReady()
    if alreadyOpen then
        C_Timer_After(0.3, function()
            if not scanInProgress or scanQueueIndex ~= currentIndex then return end
            pluginNs.ScanOpenProfession(entry.name, entry)
        end)
    else
        -- Une seule passe GetProfessions() pour le fallback
        local prof1, prof2, archeo, fishing, cooking = GetProfessions()
        local function tryFallback(idx)
            if not idx then return end
            local name, _, rank, maxRank = GetProfessionInfo(idx)
            if name == entry.name and maxRank and maxRank > 0 then
                if ProfessionViewerLogDB and core.realm and core.player then
                    local cd = ProfessionViewerLogDB[core.realm][core.player]
                    entry.rank    = rank or 0
                    entry.maxRank = maxRank
                    SaveFallbackEntry(cd, entry)
                end
            end
        end
        tryFallback(prof1); tryFallback(prof2); tryFallback(archeo)
        tryFallback(fishing); tryFallback(cooking)
        AdvanceScanQueue()
    end
end

-- ====================================================
-- DÉTECTION DES RECETTES CONNUES
-- ====================================================
function pluginNs.DetectKnownRecipes(profData)
    if not pluginNs.RECIPE_DEFINITIONS then return end
    local defKey  = (pluginNs.PROF_RECIPE_KEY and pluginNs.PROF_RECIPE_KEY[profData.name]) or profData.name
    local profDef = pluginNs.RECIPE_DEFINITIONS[defKey]
    if not profDef then return end
    profData.knownRecipes = profData.knownRecipes or {}
    local knownMap = profData.knownRecipes

    local learnedSpellIDs = {}
    local tradeSkillOpen  = C_TradeSkillUI.IsTradeSkillReady and C_TradeSkillUI.IsTradeSkillReady()
    if tradeSkillOpen then
        local allIDs = C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetAllRecipeIDs()
        if allIDs then
            for _, spellID in ipairs(allIDs) do
                local rInfo = C_TradeSkillUI.GetRecipeInfo(spellID)
                if rInfo and rInfo.learned then learnedSpellIDs[spellID] = true end
            end
        end
    end
    local hasLearnedData = next(learnedSpellIDs) ~= nil

    for _, recipes in pairs(profDef) do
        for _, recipe in ipairs(recipes) do
            if recipe.spellID and recipe.spellID > 0 then
                knownMap[recipe.itemID] = hasLearnedData
                    and (learnedSpellIDs[recipe.spellID] or false)
                    or  IsSpellKnown(recipe.spellID) or false
            end
        end
    end
end

-- ====================================================
-- SCAN DE TOUS LES MÉTIERS
-- ====================================================
function pluginNs.ScanAllProfessions()
    if scanInProgress then
        PVLDebug("|cffff8800[ProfessionViewerLog]|r Scan déjà en cours...")
        return
    end

    local slots = CollectAllProfessionSlots()
    if #slots == 0 then
        PVLDebug("|cffff8800[ProfessionViewerLog]|r Aucun métier trouvé.")
        return
    end

    PVLDebug(string_format("|cff00aaff[ProfessionViewerLog]|r Début du scan (%d métier(s))...", #slots))
    for _, slot in ipairs(slots) do
        PVLDebug(string_format("  |cff888888%s|r -> skillLine |cffffff00%d|r%s",
            slot.name, slot.skillLine,
            slot.skillLine ~= slot.rawSkillLine
                and string_format(" |cff555555(brut: %d)|r", slot.rawSkillLine) or ""))
    end

    if ProfessionViewerLogDB and core.realm and core.player then
        local cd = ProfessionViewerLogDB[core.realm] and ProfessionViewerLogDB[core.realm][core.player]
        if cd then PurgeRemovedProfessions(cd, slots) end
    end

    scanQueue      = slots
    scanQueueIndex = 0
    scanInProgress = true
    AdvanceScanQueue()
end

-- ====================================================
-- SCAN AU PREMIER INSTALL
-- ====================================================
local firstInstallFrame = CreateFrame("Frame")
firstInstallFrame:RegisterEvent("PLAYER_LOGIN")
firstInstallFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()   -- ne doit s'exécuter qu'une seule fois par session
    C_Timer_After(8, function()
        if not ProfessionViewerLogDB or not core.realm or not core.player then return end
        SaveBasicProfessionData()

        local cd = ProfessionViewerLogDB[core.realm] and ProfessionViewerLogDB[core.realm][core.player]
        if not cd or not cd.professions then return end

        local needsFirstScan = false
        for _, p in ipairs(cd.professions) do
            if not p.scanned then needsFirstScan = true; break end
        end
        if not needsFirstScan then return end

        PVLDebug(core.L("AUTOSCAN_MSG"))
        pluginNs.ScanAllProfessions()
    end)
end)

-- Détection progression — debounce 3s intégré
local skillUpdatePending = false
local skillUpdateFrame = CreateFrame("Frame")
skillUpdateFrame:RegisterEvent("SKILL_LINES_CHANGED")
skillUpdateFrame:SetScript("OnEvent", function()
    if not ProfessionViewerLogDB or not core.realm or not core.player then return end
    if skillUpdatePending then return end
    skillUpdatePending = true

    C_Timer_After(3, function()
        skillUpdatePending = false
        if scanInProgress then return end

        local slots = CollectAllProfessionSlots()
        local cd = ProfessionViewerLogDB[core.realm] and ProfessionViewerLogDB[core.realm][core.player]
        if not cd then return end

        local toRescan = {}
        for _, slot in ipairs(slots) do
            for _, p in ipairs(cd.professions or {}) do
                if p.name == slot.name and p.basicRank ~= slot.rank then
                    p.basicRank = slot.rank
                    p.basicMax  = slot.maxRank
                    toRescan[#toRescan + 1] = slot
                    break
                end
            end
        end
        if #toRescan == 0 then return end

        PVLDebug(string_format(
            "|cff00aaff[ProfessionViewerLog]|r Progression détectée — rescan de %d métier(s)...",
            #toRescan))
        scanQueue      = toRescan
        scanQueueIndex = 0
        scanInProgress = true
        AdvanceScanQueue()
    end)
end)

-- Scan passif à l'ouverture d'un métier (TRADE_SKILL_SHOW)
local tradeSkillFrame = CreateFrame("Frame")
tradeSkillFrame:RegisterEvent("TRADE_SKILL_SHOW")
tradeSkillFrame:SetScript("OnEvent", function()
    if not ProfessionViewerLogDB or not core.realm or not core.player then return end

    local profName
    local baseInfo = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
    if baseInfo and baseInfo.professionName and baseInfo.professionName ~= "" then
        profName = baseInfo.professionName
    else
        local skillLineID = C_TradeSkillUI.GetTradeSkillLine and C_TradeSkillUI.GetTradeSkillLine()
        if not skillLineID or skillLineID == 0 then return end
        profName = C_TradeSkillUI.GetTradeSkillDisplayName and C_TradeSkillUI.GetTradeSkillDisplayName(skillLineID)
    end
    if not profName then return end

    local cd = ProfessionViewerLogDB[core.realm] and ProfessionViewerLogDB[core.realm][core.player]
    if not cd or not cd.professions then return end

    local entry = nil
    for _, p in ipairs(cd.professions) do
        if p.name == profName then entry = p; break end
    end
    if not entry then return end

    C_Timer_After(0.5, function()
        if not C_TradeSkillUI.IsTradeSkillReady or not C_TradeSkillUI.IsTradeSkillReady() then return end
        PVLDebug(string_format("|cff00aaff[ProfessionViewerLog]|r Scan passif : %s", profName))
        pluginNs.ScanOpenProfession(profName, entry)
    end)
end)
