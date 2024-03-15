ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Flag Base"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Team", { KeyName = "team", Edit = { type = "Int", min = 1, max = 8} } )
	self:NetworkVar( "Bool", 0, "Empty" )

	self:NetworkVarNotify("Team", self.TeamChanged)
	self:NetworkVarNotify("Empty", self.EmptyChanged)
end