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

local enemyNameplateDebuffFrames = setmetatable({}, { __mode = "k" })

local function IsEnemyNameplateDebuff(frame)
    return frame and enemyNameplateDebuffFrames[frame]
end

local function EnsurePoolHooked(nameplateAuras)
    if nameplateAuras._poolHooked or not nameplateAuras.auraItemFramePool then
        return
    end
    nameplateAuras._poolHooked = true

    hooksecurefunc(nameplateAuras.auraItemFramePool, "Release", function(pool, frame)
        if frame
            and frame.Cooldown
            and nameplateAuras.unitToken
            and not nameplateAuras:IsForbidden()
            and not nameplateAuras:IsFriend() then
            frame.Cooldown:SetHideCountdownNumbers(true)
        end
    end)
end

local function HideEnemyDebuffDurations(nameplateAuras, listFrame)
    EnsurePoolHooked(nameplateAuras)

    if listFrame:IsForbidden() then
        return
    end

    local isEnemyDebuffList = nameplateAuras.unitToken
        and not nameplateAuras:IsFriend()
        and listFrame == nameplateAuras.DebuffListFrame

    for _, auraItemFrame in ipairs({ listFrame:GetChildren() }) do
        enemyNameplateDebuffFrames[auraItemFrame] = isEnemyDebuffList or nil

        if isEnemyDebuffList and auraItemFrame.Cooldown then
            auraItemFrame.Cooldown:SetHideCountdownNumbers(true)
        end
    end
end

local function HookNameplateAuras()
    if not NamePlateAurasMixin then
        return
    end

    hooksecurefunc(NamePlateAurasMixin, "RefreshList", HideEnemyDebuffDurations)
end

f:SetScript("OnEvent", function()
    -- Adjust scale to counter 125% monitor scaling
    UIParent:SetScale(0.64)

    C_CVar.SetCVar("alwaysCompareItems", "0")
    C_CVar.SetCVar("AutoPushSpellToActionBar", "0")

    EventUtil.ContinueOnAddOnLoaded("Blizzard_NamePlates", HookNameplateAuras)

    -- Hide the player hit indicator on the player unit frame if it exists
    if PlayerFrame and
      PlayerFrame.PlayerFrameContent and
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain and
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator then
        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator:Hide()
        hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator, "Show", function(self)
            self:Hide()
        end)
    end

    -- Hide the pet hit indicator on the pet unit frame if it exists
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

    -- Anchor cooldown viewer tooltips to the cursor instead of the default position
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not tooltip then
            return
        end

        if tooltip.IsForbidden and tooltip:IsForbidden() then
            return
        end

        local owner = tooltip:GetOwner()
        if IsCooldownViewerOwner(owner) or IsEnemyNameplateDebuff(owner) then
            tooltip:SetOwner(owner or parent or UIParent, "ANCHOR_CURSOR")
        end
    end)

    -- Turn off combat animation in Trader's Tender vendor preview
    EventUtil.ContinueOnAddOnLoaded("Blizzard_PerksProgram", function()
        local toggle = PerksProgramFrame
            and PerksProgramFrame.FooterFrame
            and PerksProgramFrame.FooterFrame.ToggleAttackAnimation

        if toggle then
            hooksecurefunc(toggle, "SetChecked", function(self)
                if self:GetChecked() then
                    self:Click()
                end
            end)
        end
    end)

    -- Show the inspected player's average item level on the inspect frame
    EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI", function()
        if not InspectFrame then
            return
        end

        inspectIlvlHolder = CreateFrame("Frame", nil, InspectModelFrame)
        inspectIlvlHolder:SetFrameStrata("TOOLTIP")
        inspectIlvlHolder:SetAllPoints(InspectModelFrame)

        inspectIlvlLabel = inspectIlvlHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        inspectIlvlLabel:SetPoint("TOP", InspectModelFrame, "TOP", 0, -4)
        inspectIlvlLabel:Hide()
    end)

    local function GetAverageQuality(unit)
        local qSum, qCount = 0, 0

        for slotId = 1, 17 do
            if slotId ~= 4 then
                local link = GetInventoryItemLink(unit, slotId)
                if link then
                    local item = Item:CreateFromItemLink(link)
                    local quality = item:GetItemQuality()
                    if quality == Enum.ItemQuality.Heirloom then
                        quality = Enum.ItemQuality.Rare
                    end
                    qSum = qSum + (quality or 0)
                    qCount = qCount + 1
                end
            end
        end

        if qCount == 0 then
            return Enum.ItemQuality.Poor
        end

        return floor(qSum / qCount + 0.5)
    end

    inspectReadyFrame = CreateFrame("Frame")
    inspectReadyFrame:RegisterEvent("INSPECT_READY")
    inspectReadyFrame:SetScript("OnEvent", function()
        if not inspectIlvlLabel or not InspectFrame then
            return
        end

        local unit = InspectFrame.unit or "target"
        local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
        if not ilvl then
            return
        end

        local quality = GetAverageQuality(unit)
        inspectIlvlLabel:SetText(format("|cnIQ%d:%d|r", quality, ilvl))
        inspectIlvlLabel:Show()
    end)
end)
