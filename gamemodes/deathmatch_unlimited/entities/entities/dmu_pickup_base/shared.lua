ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Empty" )

    self:NetworkVar( "Int", 0, "RespawnTime", { KeyName = "respawntime", Edit = { type = "Int"} } )

    self:NetworkVarNotify("Empty", self.EmptyChanged)
end

ENT.Model = "models/Items/battery.mdl"

if SERVER then
    ENT.RespawnTime = 15
    ENT.PickUpClass = "item_battery"

    function ENT:CanPickUp(ply)
        return true
    end
end