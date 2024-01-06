ENT.Type = "anim"
ENT.Base = "base_anim"

-- i kinda hate data tables
function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Empty" )

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