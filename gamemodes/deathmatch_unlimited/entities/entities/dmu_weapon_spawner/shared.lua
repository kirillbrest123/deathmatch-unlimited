ENT.PrintName = "spawn platfrom"

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "admin"
ENT.Spawnable = true
ENT.AdminOnly = false

-- i kinda hate data tables
function ENT:SetupDataTables()

	self:NetworkVar( "String", 1, "Weapon" )
	self:NetworkVar( "Bool", 0, "Empty" )

    self:NetworkVarNotify("Weapon", self.WeaponChanged)
    self:NetworkVarNotify("Empty", self.EmptyChanged)
end