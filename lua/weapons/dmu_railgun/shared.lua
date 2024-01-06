SWEP.PrintName = "Railgun"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Handheld particle accelerator. Needs charging before each shot but the impact is guaranteed to reduce the target to atoms. Self-destructs when running out of energy or when dropped by original owner for safety concerns. Best suited for long range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.HoldType = "shotgun"
SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {}

SWEP.VElements = {
	["rail1+"] = { type = "Model", model = "models/props_junk/iBeam01a_cluster01.mdl", bone = "ValveBiped.Gun", rel = "", pos = Vector(0, 1.574, 21.263), angle = Angle(90, 0, 0), size = Vector(0.217, 0.351, 0.352), color = Color(255, 255, 255, 255), surpresslightning = false, material = "phoenix_storms/metalfloor_2-3", skin = 0, bodygroup = {} },
	["glow"] = { type = "Sprite", sprite = "sprites/glow01", bone = "ValveBiped.Gun", rel = "", pos = Vector(0.674, 1.223, 45.744), size = { x = 10, y = 10 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["rail1"] = { type = "Model", model = "models/props_junk/iBeam01a.mdl", bone = "ValveBiped.Gun", rel = "", pos = Vector(0, -1.836, 13.234), angle = Angle(90, 0, 0), size = Vector(0.254, 0.374, 0.195), color = Color(255, 255, 255, 255), surpresslightning = false, material = "phoenix_storms/metalfloor_2-3", skin = 0, bodygroup = {} },
	["rail1+++"] = { type = "Model", model = "models/props_combine/CombineTrain01a.mdl", bone = "ValveBiped.Gun", rel = "", pos = Vector(0.064, 6.855, -13.136), angle = Angle(-90, 180, 90), size = Vector(0.032, 0.032, 0.032), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["rail1+"] = { type = "Model", model = "models/props_junk/iBeam01a_cluster01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(26.423, 0.643, -5.226), angle = Angle(-6.301, 0, 0), size = Vector(0.112, 0.217, 0.112), color = Color(255, 255, 255, 255), surpresslightning = false, material = "phoenix_storms/metalfloor_2-3", skin = 0, bodygroup = {} },
	["glow"] = { type = "Sprite", sprite = "sprites/glow01", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(38.183, 1.34, -7.544), size = { x = 10, y = 10 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["rail1"] = { type = "Model", model = "models/props_junk/iBeam01a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(21.99, 1.649, -7.088), angle = Angle(-5.39, 0.081, 0), size = Vector(0.151, 0.231, 0.165), color = Color(255, 255, 255, 255), surpresslightning = false, material = "phoenix_storms/metalfloor_2-3", skin = 0, bodygroup = {} },
	["rail1+++"] = { type = "Model", model = "models/props_combine/CombineTrain01a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(-1.392, 1.148, -4.127), angle = Angle(-4.574, 0, 0), size = Vector(0.018, 0.018, 0.018), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Ammo			= "CombineCannon"		-- some fucking ammo types make it so there's no tracers for some fucking reason IN MULTIPLAYER SPECIFICALLY
SWEP.Primary.Automatic      = false					-- I SPENT 30 MINUTES FIGURIN THIS OUT AND YOU'RE LAUGHING

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADS_fov = 40

SWEP.Delay = 0

SWEP.Slot = 4
SWEP.SlotPos = 3

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_railgun" )
	killicon.Add( "dmu_railgun", "hud/killicons/dmu_railgun", Color( 255, 80, 0, 255 ) )
end

function SWEP:CSetupDataTables()
	self:NetworkVar( "Float", 0, "ChargeTimer" )
	self:NetworkVar( "Float", 1, "Delay" )
end

function SWEP:CInitialize()

	self:SetHoldType( "ar2" )
	self.ChargeTime = DMU.Mode.InstantRailgun and 0.15 or 1

end

function SWEP:FirePrimary()

	//if !IsFirstTimePredicted() then return end

	self:EmitSound( "PropJeep.FireChargedCannon" )

	local owner = self:GetOwner()

	local bullet = {}
	bullet.Num		= 1
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Spread	= 0
	bullet.Tracer	= 1
	bullet.Force	= 1	
	bullet.Damage	= 1000
	bullet.AmmoType = self.Primary.Ammo
	bullet.TracerName = "railguntracer"
	bullet.HullSize = 1

	self.Pierces = 0

	bullet.Callback = function(attacker, tr, dmginfo)
		dmginfo:SetDamageType(DMG_DISSOLVE)
		if IsValid(tr.Entity) and !tr.Entity:IsRagdoll() and self.Pierces <= 5 then
			bullet.Src = tr.HitPos
			bullet.Attacker = owner
			dmginfo:SetInflictor(self)
			bullet.Tracer = 0
			self.Pierces = self.Pierces + 1
			tr.Entity:FireBullets( bullet )
		end
    end

	owner:FireBullets( bullet )

	self:ShootEffects()

	self:TakePrimaryAmmo( 25 )

	local owner = self:GetOwner()
	if ( !owner:IsNPC() ) then owner:ViewPunch( Angle( -3, 0, 0 ) ) end

	if owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then
		self:SelfDestruct()
	end
end

function SWEP:CThink()

	if self:GetOwner():IsBot() or !(self:GetDelay() < CurTime()) then return end
 
	if self:GetOwner():KeyPressed( IN_ATTACK ) and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 and IsFirstTimePredicted() then
		self:SetChargeTimer(CurTime() + self.ChargeTime)
		self.LoopSound = self:StartLoopingSound( "Jeep.GaussCharge" )
	end

	if !self:GetOwner():KeyDown( IN_ATTACK ) and self:GetOwner():KeyDownLast( IN_ATTACK ) then
		self:SetChargeTimer(0)

		if self.LoopSound then
			self:StopLoopingSound(self.LoopSound)
			self.LoopSound = nil
		end
	end

	if self:GetChargeTimer() != 0 and self:GetChargeTimer() < CurTime() then
		self:FirePrimary()
		self:SetChargeTimer(0)
		self:SetDelay(CurTime() + 0.75)
		if self.LoopSound then
			self:StopLoopingSound(self.LoopSound)
			self.LoopSound = nil
		end
	end
end

function SWEP:PrimaryAttack() -- bots use a simplified control scheme
	if !self:GetOwner():IsBot() then return end

	self:SetNextPrimaryFire( CurTime() + self.ChargeTime + 0.75 )
	self.LoopSound = self:StartLoopingSound( "Jeep.GaussCharge" )
	timer.Simple(self.ChargeTime, function()
		if !IsValid(self) or !IsValid(self:GetOwner()) then return end
		self:FirePrimary()
		if self.LoopSound then
			self:StopLoopingSound(self.LoopSound)
			self.LoopSound = nil
		end
	end) 
end

function SWEP:SelfDestruct() -- stolen from rb655
	if CLIENT then return end
	local phys = self:GetPhysicsObject()
	if ( IsValid( phys ) ) then phys:EnableGravity( false ) end

	self:SetName( "dissolve" .. self:EntIndex() )

	local dissolver = ents.Create( "env_entity_dissolver" )
	dissolver:SetPos( self:GetPos() )
	dissolver:Spawn()
	dissolver:Activate()
	dissolver:SetKeyValue( "magnitude", 100 )
	dissolver:SetKeyValue( "dissolvetype", 0 )
	dissolver:Fire( "Dissolve", "dissolve" .. self:EntIndex() )

	local owner = self:GetOwner()

	timer.Simple(2.2, function()
		if IsValid(owner) and #owner:GetWeapons() > 0 and owner:GetActiveWeapon() == NULL then
			owner:SelectWeapon( owner:GetWeapons()[math.random(#owner:GetWeapons())]:GetClass() )
		end
		dissolver:Remove()

	end)
end

function SWEP:SecondaryAttack()

end

function SWEP:Reload()

end

function SWEP:CHolster()
    self.ADS = nil
    return true
end

function SWEP:COnRemove()
	if self.LoopSound then
		self:StopLoopingSound(self.LoopSound)
	end
end

function SWEP:OnDrop()
	self:SelfDestruct()
	if self.LoopSound then
		self:StopLoopingSound(self.LoopSound)
		self.LoopSound = nil
	end
end

if !CLIENT then return end

local color_overheat = Color(236,100,37)

function SWEP:DoDrawCrosshair( x, y )
	if x == 0 or y == 0 then return end
	surface.SetDrawColor(color_white)
	surface.DrawLine( x - 32, y + 48, x - 32, y + 57)
	surface.DrawLine( x + 32, y + 48, x + 32, y + 57)

	if self:GetChargeTimer() == 0 then return end

	local size = (1 - (self:GetChargeTimer() - CurTime()) / self.ChargeTime) * 63

	surface.SetDrawColor(color_overheat)
	surface.DrawRect( x - 31, y + 48, size, 10)
end