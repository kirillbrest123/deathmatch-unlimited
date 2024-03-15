-- dummy entity that exists only to get loaded and replaced

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:Initialize()
    self:Remove()
 end