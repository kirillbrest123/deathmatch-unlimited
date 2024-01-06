AddCSLuaFile()

ENT.PrintName = "battery pickup"

ENT.Base = "dmu_pickup_base"
ENT.Category = "admin"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/Items/battery.mdl"

if SERVER then
    ENT.RespawnTime = 15
    ENT.PickUpClass = "item_battery"

    function ENT:CanPickUp(ply)
        return ply:Armor() < ply:GetMaxArmor()
    end
end