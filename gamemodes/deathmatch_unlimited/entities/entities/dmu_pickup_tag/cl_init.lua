include("shared.lua")

local material_dot = Material("icon16/bullet_white.png", "alphatest smooth")
local material_glow = Material("dmu_weapon_spawner/light_glow01")

function ENT:Draw()

    local ang = Angle( 0, SysTime() * 25 % 360, 0 )

    self.PickUpModel:SetAngles(ang)

    cam.Start3D()
        render.SetMaterial(material_glow)
        render.DrawSprite( self:GetPos() + Vector(0,0,8), 128, 128, self.Color)
    cam.End3D()

end

function ENT:Initialize()
    self.Color = team.GetColor(self:GetTeam())

    self.PickUpModel = ClientsideModel("models/balloons/balloon_star.mdl")
    self.PickUpModel:SetParent(self)
    self.PickUpModel:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self.PickUpModel:SetMaterial("models/debug/debugwhite")
    self.PickUpModel:SetPos(self:GetPos())
    self.PickUpModel:Spawn()
    self.PickUpModel:SetColor(self.Color)
end

function ENT:OnRemove()
    self.PickUpModel:Remove()
end