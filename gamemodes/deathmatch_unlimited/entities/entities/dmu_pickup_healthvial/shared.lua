AddCSLuaFile()

ENT.PrintName = "health vial pickup"

ENT.Base = "dmu_pickup_base"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/healthvial.mdl"

if SERVER then
    ENT.RespawnTime = 15
    ENT.PickUpClass = "item_healthvial"

    function ENT:CanPickUp(ply)
        return ply:Health() < ply:GetMaxHealth()
    end
end
