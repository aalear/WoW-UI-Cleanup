local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

local function IsCooldownViewerFrame(frame)
    return frame
        and (frame == _G.BuffIconCooldownViewer
            or frame == _G.BuffBarCooldownViewer
            or frame == _G.UtilityCooldownViewer)
end

local function IsCooldownViewerOwner(frame)
    local current = frame

    for _ = 1, 12 do
        if not current then
            return false
        end

        if IsCooldownViewerFrame(current) then
            return true
        end

        if IsCooldownViewerFrame(current.viewerFrame) then
            return true
        end

        current = current.GetParent and current:GetParent() or nil
    end

    return false
end

f:SetScript("OnEvent", function()
    C_CVar.SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", "1")
    C_CVar.SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", "1")

    if PlayerFrame and
      PlayerFrame.PlayerFrameContent and
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain and
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator then
        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator:Hide()
        hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator, "Show", function(self)
            self:Hide()
        end)
    end

    if PetHitIndicator then
        PetHitIndicator:Hide()
        hooksecurefunc(PetHitIndicator, "Show", function(self)
            self:Hide()
        end)
    end

    -- Hide the self-highlight if "Find Your Self Anywhere" is enabled
    hooksecurefunc("ToggleSelfHighlight", function() end)
    C_Timer.After(1, function()
        if GetCVarBool("findYourselfAnywhere") and ToggleSelfHighlight then
            ToggleSelfHighlight()
        end
    end)

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not tooltip then
            return
        end

        if tooltip.IsForbidden and tooltip:IsForbidden() then
            return
        end

        local owner = tooltip:GetOwner()
        if IsCooldownViewerOwner(owner) then
            tooltip:SetOwner(owner or parent or UIParent, "ANCHOR_CURSOR")
        end
    end)
end)
