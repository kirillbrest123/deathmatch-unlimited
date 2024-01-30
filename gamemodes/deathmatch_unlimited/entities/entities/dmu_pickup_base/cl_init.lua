include("shared.lua")

local ang = Angle(0,0,0) -- they all rotate in sync anyway
local model_offset = Vector(0,0,8)

function ENT:Draw()

	ang.y = SysTime() * 25 % 360

	if not IsValid(self.PickUpModel) then -- AAAAAAAAAAAA
		self:CreateModels()
	end

	model_offset.z = TimedCos(0.25, 8, 10, 0)
	self.PickUpModel:SetAngles(ang)
	self.PickUpModel:SetPos(self:GetPos() + model_offset)
end

function ENT:Initialize()
	self:CreateModels()

	if self:GetEmpty() then
		self:EmptyChanged(nil, nil, self:GetEmpty())
	end
end

function ENT:CreateModels()
	if IsValid(self.PickUpModel) then self.PickUpModel:Remove() end
	self.PickUpModel = ClientsideModel(self.Model)
    self.PickUpModel:SetParent(self)
	self.PickUpModel:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self.PickUpModel:SetPos(self:GetPos() + model_offset)
	self.PickUpModel:Spawn()
end

function ENT:OnRemove()
	if not IsValid(self.PickUpModel) then return end
	self.PickUpModel:Remove()
end

function ENT:EmptyChanged(name, old, new)
	if not IsValid(self.PickUpModel) then -- AAAAAAAAAAAA
		self:CreateModels()
	end

	if new then
		self.PickUpModel:SetMaterial("lights/white")
		self.PickUpModel:SetColor4Part(32,32,32,127)
	else
		self.PickUpModel:SetMaterial()
		self.PickUpModel:SetColor4Part(255,255,255,255)
	end
end