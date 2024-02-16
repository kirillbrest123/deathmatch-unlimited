AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.Flag = NULL
ENT.Disabled = false

function ENT:KeyValue(key, value)
	key = string.lower(key)
    if key == "team" and value != "" then
        self:SetTeam( tonumber(value) )
    end
end

function ENT:Initialize()

    if !DMU.Mode.FlagsEnabled then self:Remove() return end

    self:SetModel("models/hunter/tubes/circle2x2.mdl")
    self:SetMaterial("phoenix_storms/plastic")

    self:PhysicsInitBox(Vector(-64,-64,0), Vector(64,64,8))
    self:SetCollisionBounds(Vector(-64,-64,0), Vector(64,64,64))
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:DropToFloor()
    self:GetPhysicsObject():EnableMotion(false)

    self:SetEmpty(false)

    self:SetTrigger(true)
    self:UseTriggerBounds(true)
end

function ENT:StartTouch(entity)
    if entity:IsPlayer() and entity:Alive() then
        local flag = entity:GetWeapon("dmu_flag")

        if not IsValid(flag) then
            if self:GetTeam() != entity:Team() and !self:GetEmpty() then
                self.Flag = entity:Give("dmu_flag")
                --flag.Base = self
                timer.Simple(0, function()
                    self.Flag:SetTeam(self:GetTeam())
                end)

                self:SetEmpty(true)
            end

            return
        end

        if self:GetTeam() == entity:Team() and flag:GetTeam() != self:GetTeam() then
            hook.Run("DMU_FlagCaptured", flag, entity)
            -- entity:DropNamedWeapon("dmu_flag") -- makes you switch weapons
            flag:SelfDestruct()

            return
        end

    end
end

function ENT:Think()
    if !self.Disabled and self:GetEmpty() and !IsValid(self.Flag) then
        self:SetEmpty(false)
    end
end

function ENT:Enable()
    self.Disabled = false
    self:SetEmpty(false)
end

function ENT:Disable()
    self.Disabled = true
    self:SetEmpty(true)
    if IsValid(self.Flag) then
        self.Flag:SelfDestruct()
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:TeamChanged(name, old, new)
    self:SetColor(team.GetColor(new))

    for k,v in ipairs(DMU.Mode.Teams) do
        if k == new then continue end
        DMU.AddBotTeamObjective(k, self)
    end
end

function ENT:OnRemove()
    for k,v in ipairs(DMU.Mode.Teams) do
        if k == new then continue end
        DMU.RemoveBotTeamObjective(k, self)
    end
end

function ENT:EmptyChanged(name, old, new)
    local t = self:GetTeam()

    if t == 0 then return end
    if new then
        for k,v in ipairs(DMU.Mode.Teams) do
            if k == t then continue end
            DMU.RemoveBotTeamObjective(k, self)
        end
    else
        for k,v in ipairs(DMU.Mode.Teams) do
            if k == t then continue end
            DMU.AddBotTeamObjective(k, self)
        end
    end
end