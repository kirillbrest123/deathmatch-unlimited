include("shared.lua")

function ENT:Draw()

	local ang = Angle( 0, SysTime() * 25 % 360, 0 )

	if not IsValid(self.PickUpModel) then -- AAAAAAAAAAAA
		self:Initialize()
		return 
	end

	self.PickUpModel:SetAngles(ang)

end

function ENT:Initialize()
	--self.PickUpModel = ents.CreateClientside("base_anim")
	if IsValid(self.PickUpModel) then self.PickUpModel:Remove() end
	self.PickUpModel = ClientsideModel(self.Model)
    self.PickUpModel:SetParent(self)
	self.PickUpModel:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self.PickUpModel:SetPos(self:GetPos() + Vector(0,0,8))
	self.PickUpModel:Spawn()

	--self.PickUpModel:SetModel("models/Items/HealthKit.mdl")

	if self:GetEmpty() then
		self:EmptyChanged(nil, nil, self:GetEmpty())
	end
end

function ENT:OnRemove()
	self.PickUpModel:Remove()
end

function ENT:EmptyChanged(name, old, new)
	if new then
		self.PickUpModel:SetMaterial("lights/white")
		self.PickUpModel:SetColor4Part(32,32,32,127)
	else
		self.PickUpModel:SetMaterial()
		self.PickUpModel:SetColor4Part(255,255,255,255)
	end
end