AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:KeyValue(key, value)
	key = string.lower(key)

    if key == "respawntime" then
        self.RespawnTime = tonumber(value)
    elseif key == "speed" then
        self.RespawnTime = value
    end
end

local respawn_time_convar = GetConVar("dmu_pickup_respawn_time")

function ENT:Initialize()

    if DMU.Mode.HealthPickUpsDisabled then self:Remove() return end

    if self.RespawnTime == 0 then
        self.RespawnTime = respawn_time_convar:GetInt()
    end

    self:SetModel(self.Model)

    self:PhysicsInitBox(Vector(-16, -16, 0), Vector(16, 16, 8))
    self:GetPhysicsObject():EnableMotion(false)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:DrawShadow(false)

    self:DropToFloor()

    self:SetTrigger(true)
    self:UseTriggerBounds(true, 8)
end

local sandbox = GetConVar("dmu_sandbox")

function ENT:UpdateTransmitState()
    if sandbox:GetBool() then return TRANSMIT_ALWAYS end -- uhhh so when an entity leaves PVS (i.e stop getting networked) all clientside models get unparrented
	return TRANSMIT_PVS -- it's not a serious issue but it's annoying when workins with MMM so yeah we just always network it then
end

function ENT:StartTouch(entity)
    if entity:IsPlayer() and entity:Alive() and !self:GetEmpty() and self:CanPickUp(entity) then
        local pickup = entity:Give(self.PickUpClass)

        self:SetEmpty(true)
        timer.Create(self:GetClass() .. self:GetCreationID(), self.RespawnTime, 1, function()
            if not self:IsValid() then return end
            self:SetEmpty(false)
        end)
    end
end