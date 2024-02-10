ENT.Type 				= "anim"
ENT.Base 				= "base_anim"
ENT.Author 				= ""

ENT.Spawnable 			= false

AddCSLuaFile()

ENT.Model = "models/hunter/misc/sphere025x025.mdl"

local material_glow = Material("dmu_weapon_spawner/light_glow01")
local color = Color(30, 154, 255)
ENT.NextSpark = 0

function ENT:Draw()
	self:DrawModel()

	cam.Start3D(EyePos(), EyeAngles(), nil, 0, 0, ScrW(), ScrH(), 64)
		render.SetMaterial(material_glow)
		render.DrawSprite( self:GetPos(), 128, 96, color)
	cam.End3D()

	if self.NextSpark < CurTime() then
		local effectData = EffectData()
		effectData:SetEntity(self)
		effectData:SetMagnitude(1)

		util.Effect("TeslaHitboxes", effectData)
		self.NextSpark = UnPredictedCurTime() + 0.1
	end
end

-- should it be predicted? no idea
function ENT:Initialize()
    if SERVER then

		self:SetTrigger(true)

		self:SetModel("models/hunter/misc/sphere025x025.mdl")
		self:ResetSequence("idle")
		self:SetModelScale(0.6)
		self:SetMaterial("lights/white")
        self:DrawShadow(false)
        self:PhysicsInitSphere(12)

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:SetMass(16)
            phys:SetBuoyancyRatio(0)
            phys:EnableDrag(false)
            phys:EnableGravity(false)
        end

        timer.Simple(0, function()
            if !IsValid(self) then return end
            self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        end)
		
		timer.Simple(10, function() -- just in case
			if !IsValid(self) then return end
			self:Remove()
		end)

		local light = ents.Create("light_dynamic")
		light:SetKeyValue("brightness", "4")
		light:SetKeyValue("distance", "128")
		light:SetPos(self:GetPos())
		light:Fire("Color", "30 154 255")
		light:SetParent(self)
		light:Spawn()
		light:Activate()
		light:Fire("TurnOn", "", 0)
	end
end

function ENT:StartTouch(entity)
    if SERVER then
		if entity == self:GetOwner() then return end
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(15)
		dmginfo:SetAttacker(self:GetOwner())
		dmginfo:SetDamageType(DMG_DISSOLVE)

		entity:TakeDamageInfo(dmginfo)

		local effectData = EffectData()
		effectData:SetEntity(entity)
		effectData:SetMagnitude(6)
	
		util.Effect("TeslaHitboxes", effectData)

		entity:EmitSound( "physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav", 70, 100, 0.4 )

		self:Remove()
    end
end

function ENT:PhysicsCollide(data, physobj)
    if SERVER then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(15)
		dmginfo:SetAttacker(self:GetOwner())
		dmginfo:SetDamageType(DMG_DISSOLVE)

		data.HitEntity:TakeDamageInfo(dmginfo)

		local effectData = EffectData()
		effectData:SetOrigin(data.HitPos)
		effectData:SetNormal(data.HitNormal)
		effectData:SetRadius(128)
		effectData:SetMagnitude(5)
	
		util.Effect("AR2Impact", effectData)

		util.Decal("FadingScorch", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)

		self:EmitSound( "physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav", 70, 100, 0.4 )
		self:Remove()
    end
end