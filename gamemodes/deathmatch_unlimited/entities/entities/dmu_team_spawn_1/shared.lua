AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Team 1 Spawnpoint"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

if SERVER then


function ENT:Initialize()
    self:SetModel("models/editor/playerstart.mdl")
    self:SetColor4Part(255, 0, 0, 255)
    self:SetMaterial("models/debug/debugwhite")
    self:PhysicsInitBox(Vector(-1,-1,-1), Vector(1,1,1))
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
end


else


local sandbox = GetConVar("dmu_server_sandbox")
function ENT:Draw()
    if !sandbox:GetBool() then return end
    self:DrawModel()
end


end