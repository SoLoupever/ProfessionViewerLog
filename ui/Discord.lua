local addonName, ns = ...
local core = ns.core

-- Popup du lien Discord : expose uniquement ns.ShowDiscordDialog().
-- Pas d'API WoW pour ouvrir une URL : lien pré-sélectionné, prêt pour Ctrl+C.

local LINK = "https://discord.gg/2gfEKGAT46"

local dlg

local function EnsureDialog()
    if dlg then return dlg end

    dlg = CreateFrame("Frame", "PVL_DiscordDialog", UIParent, "BackdropTemplate")
    dlg:SetSize(360, 112)
    dlg:SetPoint("CENTER")
    dlg:SetFrameStrata("DIALOG")
    dlg:SetToplevel(true)
    dlg:EnableMouse(true)
    dlg:SetMovable(true)
    dlg:RegisterForDrag("LeftButton")
    dlg:SetScript("OnDragStart", dlg.StartMoving)
    dlg:SetScript("OnDragStop", dlg.StopMovingOrSizing)
    core.Skin.Frame(dlg, "window")
    tinsert(UISpecialFrames, "PVL_DiscordDialog")

    dlg.title = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dlg.title:SetPoint("TOP", 0, -14)

    local close = core.Skin.CloseButton(dlg, function() dlg:Hide() end)
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -8, -8)

    dlg.hint = dlg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dlg.hint:SetPoint("TOP", 0, -38)

    local box = CreateFrame("Frame", nil, dlg, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 16, -58)
    box:SetPoint("TOPRIGHT", -16, -58)
    box:SetHeight(22)
    core.Skin.Frame(box, "input")

    local edit = CreateFrame("EditBox", nil, box)
    edit:SetPoint("TOPLEFT", 6, 0)
    edit:SetPoint("BOTTOMRIGHT", -6, 0)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnEditFocusGained", edit.HighlightText)
    -- lien en lecture seule : on rétablit le texte si modifié
    edit:SetScript("OnTextChanged", function(self, user)
        if user then self:SetText(LINK); self:HighlightText() end
    end)
    dlg.edit = edit

    return dlg
end

function ns.ShowDiscordDialog()
    EnsureDialog()
    dlg.title:SetTextColor(unpack(core.Theme.heading))
    dlg.title:SetText(core.L("BTN_DISCORD"))
    dlg.hint:SetText(core.L("DISCORD_HINT"))
    dlg.edit:SetText(LINK)
    dlg:Show()
    dlg:Raise()
    dlg.edit:SetFocus()
    dlg.edit:HighlightText()
end
