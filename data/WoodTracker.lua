local addonName, ns = ...
local pluginNs = ns
local core = ns.core

-- ====================================================
-- TRACKER DE BOIS — scan natif via C_Container
-- Banque de bataillon : onglets bags 12 et 13
-- Sacs du joueur       : bags 0 à 4
-- ====================================================

-- Cache des globals fréquemment appelés (évite lookup _G à chaque appel)
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local pairs, ipairs, wipe = pairs, ipairs, wipe
local Enum_BankType_Account = Enum.BankType.Account

-- ── Bois organisés par extension ─────────────────────
pluginNs.WOOD_BY_EXPANSION = {
    { expansionKey = "EXP_CLASSIC",  color = { 0.85, 0.75, 0.55 }, items = {{ id = 245586, name = "Bois de bois-de-fer" }}},
    { expansionKey = "EXP_BC",       color = { 1.00, 0.55, 0.10 }, items = {{ id = 242691, name = "Bois d'olemba" }}},
    { expansionKey = "EXP_WOTLK",    color = { 0.40, 0.75, 1.00 }, items = {{ id = 251762, name = "Bois de vent froid" }}},
    { expansionKey = "EXP_CATA",     color = { 1.00, 0.30, 0.10 }, items = {{ id = 251764, name = "Bois de frêne" }}},
    { expansionKey = "EXP_MOP",      color = { 0.20, 0.80, 0.30 }, items = {{ id = 251763, name = "Bois de bambou" }}},
    { expansionKey = "EXP_WOD",      color = { 1.00, 0.65, 0.20 }, items = {{ id = 251766, name = "Bois d'Ombrelune" }}},
    { expansionKey = "EXP_LEGION",   color = { 0.90, 0.50, 1.00 }, items = {{ id = 251767, name = "Bois touché par la corruption" }}},
    { expansionKey = "EXP_BFA",      color = { 0.20, 0.60, 1.00 }, items = {{ id = 251768, name = "Bois de sombrepin" }}},
    { expansionKey = "EXP_SL",       color = { 0.70, 0.50, 1.00 }, items = {{ id = 251772, name = "Bois d'Arden" }}},
    { expansionKey = "EXP_DF",       color = { 0.20, 0.90, 0.50 }, items = {{ id = 251773, name = "Bois de pin-des-dragons" }}},
    { expansionKey = "EXP_KA",       color = { 0.40, 0.85, 1.00 }, items = {{ id = 248012, name = "Bois d'épicéa de Dornic" }}},
    { expansionKey = "EXP_MIDNIGHT", color = { 0.55, 0.35, 1.00 }, items = {{ id = 256963, name = "Bois thalassien" }}},
}

-- Lookup plat id → nom (set O(1) pour les scans)
pluginNs.WOOD_ITEM_IDS = {}
for _, expBlock in ipairs(pluginNs.WOOD_BY_EXPANSION) do
    for _, item in ipairs(expBlock.items) do
        pluginNs.WOOD_ITEM_IDS[item.id] = item.name
    end
end

-- ====================================================
-- SCAN BANQUE DE BATAILLON (bags 12 et 13)
-- ====================================================
-- Table pré-allouée (évite { 12, 13 } temporaire à chaque scan)
local WARBAND_BAGS = { 12, 13 }

local function ScanWarbandBank()
    if not ProfessionViewerLogDB then return end
    local db = ProfessionViewerLogDB
    db.warbandBank = db.warbandBank or {}
    wipe(db.warbandBank)

    local found = false
    for _, bag in ipairs(WARBAND_BAGS) do
        local numSlots = C_Container_GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            found = true
            db.warbandBank[bag] = db.warbandBank[bag] or {}
            wipe(db.warbandBank[bag])
            for slot = 1, numSlots do
                local info = C_Container_GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    db.warbandBank[bag][slot] = { id = info.itemID, count = info.stackCount or 1 }
                end
            end
        end
    end

    if found then
        if ProfessionViewerLogDB and ProfessionViewerLogDB.debugVerbose then
            print("|cffffd700[ProfessionViewerLog]|r " .. core.L("WARBAND_SCANNED"))
        end
        if pluginNs.isViewActive and core.mainFrame and core.mainFrame:IsShown() then
            pluginNs.ShowProfessions()
        end
    end
end

-- ====================================================
-- SCAN DES SACS DU PERSONNAGE COURANT (bags 0-4)
-- ====================================================
local function ScanPlayerBags()
    if not ProfessionViewerLogDB or not core.realm or not core.player then return end
    local db = ProfessionViewerLogDB
    db[core.realm] = db[core.realm] or {}
    db[core.realm][core.player] = db[core.realm][core.player] or {}
    local charData = db[core.realm][core.player]
    charData.bags = charData.bags or {}
    -- Réinitialise les sacs sans réallouer la table parent
    wipe(charData.bags)

    for bag = 0, 4 do
        local numSlots = C_Container_GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            charData.bags[bag] = charData.bags[bag] or {}
            wipe(charData.bags[bag])
            for slot = 1, numSlots do
                local info = C_Container_GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    charData.bags[bag][slot] = { id = info.itemID, count = info.stackCount or 1 }
                end
            end
        end
    end
end

-- ====================================================
-- LECTURE DU STOCK — retourne total + detail (id → qty)
-- ====================================================
local _detailCache = {}   -- table réutilisée pour éviter les allocations répétées

function pluginNs.GetWoodCounts()
    local total   = 0
    local detail  = _detailCache
    wipe(detail)
    local woodSet = pluginNs.WOOD_ITEM_IDS

    local warbandBank = ProfessionViewerLogDB and ProfessionViewerLogDB.warbandBank
    if warbandBank then
        for _, bagData in pairs(warbandBank) do
            if type(bagData) == "table" then
                for _, slot in pairs(bagData) do
                    if slot and woodSet[slot.id] then
                        local qty = slot.count or 1
                        total = total + qty
                        detail[slot.id] = (detail[slot.id] or 0) + qty
                    end
                end
            end
        end
    end

    local charBags = ProfessionViewerLogDB
        and core.realm and core.player
        and ProfessionViewerLogDB[core.realm]
        and ProfessionViewerLogDB[core.realm][core.player]
        and ProfessionViewerLogDB[core.realm][core.player].bags

    if charBags then
        for _, bagData in pairs(charBags) do
            if type(bagData) == "table" then
                for _, slot in pairs(bagData) do
                    if slot and woodSet[slot.id] then
                        local qty = slot.count or 1
                        total = total + qty
                        detail[slot.id] = (detail[slot.id] or 0) + qty
                    end
                end
            end
        end
    end

    return total, detail
end

-- ====================================================
-- ÉVÉNEMENTS
-- ====================================================
local warbandBankWasViewable = false
-- Debounce pour BAG_UPDATE_DELAYED : évite les scans répétés lors de
-- manipulations en masse (craft, dépôt en banque, etc.)
local bagScanPending = false

local woodFrame = CreateFrame("Frame")
woodFrame:RegisterEvent("BANKFRAME_OPENED")
woodFrame:RegisterEvent("BANKFRAME_CLOSED")
woodFrame:RegisterEvent("BAG_UPDATE_DELAYED")
woodFrame:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
woodFrame:RegisterEvent("PLAYER_LOGIN")

woodFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "BANKFRAME_OPENED" then
        warbandBankWasViewable = C_Bank
            and C_Bank.CanViewBank
            and C_Bank.CanViewBank(Enum_BankType_Account)
            or false

    elseif event == "BANKFRAME_CLOSED" then
        if warbandBankWasViewable then
            ScanWarbandBank()
            warbandBankWasViewable = false
        end

    elseif event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" then
        if C_Bank and C_Bank.CanViewBank and C_Bank.CanViewBank(Enum_BankType_Account) then
            ScanWarbandBank()
        end

    elseif event == "BAG_UPDATE_DELAYED" then
        -- Debounce 0.4s : un seul scan après la fin des opérations groupées
        if bagScanPending then return end
        bagScanPending = true
        C_Timer.After(0.4, function()
            bagScanPending = false
            ScanPlayerBags()
        end)

    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2, ScanPlayerBags)
    end
end)
