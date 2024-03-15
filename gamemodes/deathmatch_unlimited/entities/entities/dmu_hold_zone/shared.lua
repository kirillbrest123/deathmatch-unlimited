ENT.PrintName = "Hill"

--ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.Category = "Deathmatch Unlimited"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Editable = true

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "Identifier", { KeyName = "identifier", Edit = { type = "Combo", values = { A = 0, B = 1, C = 2, D = 3, E = 4 } } })
end