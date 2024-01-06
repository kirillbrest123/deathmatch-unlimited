ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "tag pickup"
ENT.Category = "admin"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Team" )
end