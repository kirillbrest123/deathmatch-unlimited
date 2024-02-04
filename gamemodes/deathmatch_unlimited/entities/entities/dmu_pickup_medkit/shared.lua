AddCSLuaFile()

ENT.PrintName = "medkit pickup"

ENT.Base = "dmu_pickup_base"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Editable = true

ENT.Model = "models/Items/HealthKit.mdl"

if SERVER then
    ENT.RespawnTime = 15
    ENT.PickUpClass = "item_healthkit"

    function ENT:CanPickUp(ply)
        return ply:Health() < ply:GetMaxHealth()
    end
end
