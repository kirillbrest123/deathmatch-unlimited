ENT.PrintName = "weapon spawner"

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Editable = true

-- i kinda hate data tables
function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "Weapon")
	self:NetworkVar( "Bool", 0, "Empty" )

    self:NetworkVar( "Int", 0, "RespawnTime", { KeyName = "respawntime", Edit = { type = "Int"} } )

    self:NetworkVar( "String", 1, "MainWeapon", { KeyName = "weapon", Edit = { type = "Generic"} } )
    self:NetworkVar( "String", 2, "FallbackWeapon", { KeyName = "fallbackweapon", Edit = { type = "Generic"} } )
    self:NetworkVar( "Int", 1, "FallbackRarity", { KeyName = "fallbackrarity", Edit = { type = "Combo", values = { Common = 1, Uncommon = 2, Rare = 3, ["Very Rare"] = 4 } } } )
    

    self:NetworkVarNotify("Weapon", self.WeaponChanged)
    self:NetworkVarNotify("Empty", self.EmptyChanged)
end