local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function()
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
end)