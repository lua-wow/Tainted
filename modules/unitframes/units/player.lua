local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Player
--------------------------------------------------
function UnitFrames:CreatePlayerFrame(frame)
    frame.__class = E.class

    self:CreateUnitFrame(frame)

    if (frame.Castbar) then
        frame.Castbar:ClearAllPoints()
        frame.Castbar:SetSize(350, 20)
        frame.Castbar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
    end

    frame.AdditionalPower = self:CreateAdditionalPower(frame)
    frame.AlternativePower = self:CreateAlternativePower(frame)
    frame.PowerPrediction = self:CreatePowerPrediction(frame)

    -- indicators
    frame.AssistantIndicator = self:CreateAssistantIndicator(frame)
    frame.CombatIndicator = self:CreateCombatIndicator(frame)
    frame.LeaderIndicator = self:CreateLeaderIndicator(frame)
    frame.PhaseIndicator = self:CreatePhaseIndicator(frame)
    frame.PvPClassificationIndicator = self:CreatePvPClassificationIndicator(frame)
    -- frame.PvPIndicator = self:CreatePvPIndicator(frame)
    frame.RaidRoleIndicator = self:CreateRaidRoleIndicator(frame)
    frame.ReadyCheckIndicator = self:CreateReadyCheckIndicator(frame)
    frame.RestingIndicator = self:CreateRestingIndicator(frame)
    frame.ResurrectIndicator = self:CreateResurrectIndicator(frame)
    frame.SummonIndicator = self:CreateSummonIndicator(frame)

    -- classes elements
    -- COMBO POINTS     (all classes)
    -- ESSENSES         (EVOKER)
    -- ARCANE CHARGES   (MAGE)
    -- CHI ORB          (MONK)
    -- HOLY POWER       (PALADIN)
    -- SOUL SHARDS      (WARLOCK)
    frame.ClassPower = self:CreateClassPower(frame)

    -- SHAMAN -> TOTEMS
    -- MONK -> STATUES
    -- PALADIN -> CONSACRATION
    -- PRIEST -> MIND BINDER
    if E.isRetail then
        frame.Totems = self:CreateTotems(frame)
    end

    -- RUNES (DEATHKNIGHT)
    -- STAGGER (MONK)
    self[frame.__class](self, frame)
end
