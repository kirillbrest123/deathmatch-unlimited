ENT.PrintName = "weapon spawner"

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

-- i kinda hate data tables
function ENT:SetupDataTables()

	self:NetworkVar( "String", 1, "Weapon" )
	self:NetworkVar( "Bool", 0, "Empty" )

    self:NetworkVarNotify("Weapon", self.WeaponChanged)
    self:NetworkVarNotify("Empty", self.EmptyChanged)
end