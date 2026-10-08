local addonName, ns = ...
local core = ns.core

-- ====================================================
-- MINIMAP
-- ====================================================
function core.InitMinimap()
    local mainFrame = core.mainFrame
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LibDBIcon then
        -- Fallback : bouton natif minimal si LibDBIcon absent
        local btn = CreateFrame("Button", "PVLMinimapBtn", Minimap)
        btn:SetSize(31, 31)
        btn:SetFrameStrata("MEDIUM")
        btn:SetFrameLevel(8)
        local angle = math.rad(225)
        btn:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(angle) * 80,
            math.sin(angle) * 80)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetSize(20, 20)
        bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
        bg:SetPoint("TOPLEFT", 7, -5)

        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetSize(53, 53)
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        border:SetPoint("TOPLEFT")

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(17, 17)
        icon:SetPoint("CENTER", 0, 1)
        icon:SetTexture("Interface\\AddOns\\ProfessionViewerLog\\PVL.blp")
        icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("|cffffd700ProfessionViewerLog|r")
            GameTooltip:AddLine("|cffffffffSuivi des métiers|r")
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff808080Clic gauche : Ouvrir / Fermer|r")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(_, button)
            if button == "LeftButton" then
                if mainFrame:IsShown() then
                    mainFrame:Hide()
                else
                    ns.isViewActive = true
                    ns.ShowProfessions()
                    mainFrame:Show()
                end
            end
        end)
        btn:Show()
        return
    end

    -- Évite une double registration
    if LibDBIcon:IsRegistered("ProfessionViewerLog") then return end

    ProfessionViewerLogDB.minimap = ProfessionViewerLogDB.minimap or {}
    if type(ProfessionViewerLogDB.minimap) ~= "table" then
        ProfessionViewerLogDB.minimap = {}
    end
    ProfessionViewerLogDB.minimap.hide = ProfessionViewerLogDB.minimap.hide or false

    local ldbObj = {
        icon = "Interface\\AddOns\\ProfessionViewerLog\\PVL.blp",

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cffffd700ProfessionViewerLog|r")
            tooltip:AddLine("|cffffffffSuivi des métiers|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cff808080Clic gauche : Ouvrir / Fermer|r")
        end,

        OnClick = function(_, button)
            if button == "LeftButton" then
                if mainFrame:IsShown() then
                    mainFrame:Hide()
                else
                    ns.isViewActive = true
                    ns.ShowProfessions()
                    mainFrame:Show()
                end
            end
        end,
    }

    LibDBIcon:Register("ProfessionViewerLog", ldbObj, ProfessionViewerLogDB.minimap)
end
