AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()

    self:SetModel("models/balloons/balloon_star.mdl")

    self:PhysicsInitBox(Vector(-16, -16, 0), Vector(16, 16, 8))
    self:GetPhysicsObject():EnableMotion(false)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:DrawShadow(false)

    self:SetTrigger(true)
    self:UseTriggerBounds(true, 8)

    table.insert(DMU.BotObjectives, self)

    timer.Simple(15, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
end

function ENT:StartTouch(entity)
    if entity:IsPlayer() and entity:Alive() then
        hook.Run("DMU_TagCollected", self, entity)
        self:EmitSound( "garrysmod/balloon_pop_cute.wav" )
        self:Remove()
    end
end

function ENT:OnRemove()
    table.RemoveByValue(DMU.BotObjectives, self)
end