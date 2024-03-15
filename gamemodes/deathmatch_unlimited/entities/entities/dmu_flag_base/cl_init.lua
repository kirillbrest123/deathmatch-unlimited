include("shared.lua")

local flag_bases = flag_bases or {}

function ENT:Initialize()
    self:CreateModels()
end

local pole_offset = Vector(0,0,48)
local flag_offset = Vector(0,22,82)
local material_dot = Material("icon16/bullet_white.png", "alphatest smooth")

local mat = Matrix()
mat:Scale(Vector(1,1,0.1))

function ENT:Draw()
	self:DrawModel()

    if !IsValid(self.FlagModel) then self:CreateModels() return end
end

function ENT:CreateModels()
	if IsValid(self.FlagModel) then self.FlagModel:Remove() end
	self.FlagModel = ClientsideModel("models/hunter/plates/plate2.mdl")
    self.FlagModel:SetParent(self)
    self.FlagModel:SetPos(self:GetPos() + pole_offset)
    self.FlagModel:SetAngles(Angle(0,0,90))
    self.FlagModel:Spawn()

    if IsValid(self.FlagModel.Banner) then self.FlagModel.Banner:Remove() end
    self.FlagModel.Banner = ClientsideModel("models/hunter/plates/plate05x075.mdl")
    self.FlagModel.Banner:SetParent(self)
    self.FlagModel.Banner:SetPos(self:GetPos() + flag_offset)
    self.FlagModel.Banner:SetAngles(Angle(90,0,0))
    self.FlagModel.Banner:SetMaterial("models/debug/debugwhite")

    self.FlagModel.Banner:EnableMatrix("RenderMultiply", mat)

    self.FlagModel.Banner:Spawn()
    self.FlagModel.Banner:SetRenderMode( RENDERMODE_TRANSCOLOR )

    flag_bases[self] = true
	self:TeamChanged(nil, nil, self:GetTeam())

	self:EmptyChanged(nil, nil, self:GetEmpty())
end

function ENT:OnRemove()
    flag_bases[self] = nil

	if not IsValid(self.FlagModel) then return end
	self.FlagModel:Remove()
    self.FlagModel.Banner:Remove()
end

function ENT:TeamChanged(name, old, new)
    if !IsValid(self.FlagModel) then self:CreateModels() return end
    self.FlagModel.Banner:SetColor(team.GetColor(new))
end

function ENT:EmptyChanged(name, old, new)
    if new then
        if !IsValid(self.FlagModel) then self:CreateModels() return end
		self.FlagModel:SetNoDraw(true)
        self.FlagModel.Banner:SetNoDraw(true)
	else
        if !IsValid(self.FlagModel) then self:CreateModels() return end
		self.FlagModel:SetNoDraw(false)
        self.FlagModel.Banner:SetNoDraw(false)
	end
end

-- i would rather avoid using sv_3d2d.lua whenever an entity exists on client
-- \/ this doesn't actually work properly for some reason. It draws the thing slightly off and i have no idea why it happens
hook.Add("HUDPaint", "DMU_FlagBases3D2D", function()

        for k,v in pairs(flag_bases) do
            local data = k:GetPos():ToScreen()
            if !data.visible then continue end
            surface.SetMaterial(material_dot)
            surface.SetDrawColor(team.GetColor(k:GetTeam()))
            surface.DrawTexturedRect(data.x, data.y, 32, 32)
        end

end)