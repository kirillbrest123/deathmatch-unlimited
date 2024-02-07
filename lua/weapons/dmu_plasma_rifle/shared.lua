SWEP.PrintName = "Plasma Rifle"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Fully-automatic futuristic rifle-like weapon. Fires balls of superheated plasma instead of conventional rounds. Isn't limited by magazine size but prone to overheating. Self-destructs when running out of energy or when dropped by original owner for security reasons. Best suited for close range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_smg1.mdl"
SWEP.ViewModel		= "models/weapons/c_smg1.mdl"
SWEP.UseHands = true

SWEP.VElements = {
	["battery"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(0.305, 0, -0.383), angle = Angle(0, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["battery++"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-0.336, -1.657, -0.383), angle = Angle(0, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["glow"] = { type = "Sprite", sprite = "sprites/glow02", bone = "ValveBiped.base", rel = "", pos = Vector(-0.035, 0, 13.588), size = { x = 6.465, y = 7.892 }, color = Color(30, 154, 255, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = true},
	["battery+"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-0.336, 1.101, -0.383), angle = Angle(0, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["battery+++"] = { type = "Model", model = "models/Items/combine_rifle_cartridge01.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(1.046, -0.095, -3.754), angle = Angle(-9.254, -36.103, -101.439), size = Vector(0.389, 0.389, 0.389), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.WElements = {
	["battery"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(24.059, 0.006, -8.148), angle = Angle(79.342, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["battery++"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(24.059, 2.733, -8.148), angle = Angle(79.342, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["battery++++"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(23.665, 1.172, -9.712), angle = Angle(79.342, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["glow"] = { type = "Sprite", sprite = "sprites/glow02", bone = "ValveBiped.Bip01_R_Hand", rel = "battery", pos = Vector(0, 1.128, -0.353), size = { x = 10, y = 10 }, color = Color(40, 154, 255, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["battery+"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(23.665, 1.172, -6.559), angle = Angle(79.342, 0, 0), size = Vector(0.5, 0.5, 2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["battery+++"] = { type = "Model", model = "models/Items/combine_rifle_cartridge01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4.346, 3.171, -5.139), angle = Angle(180, 90, 0), size = Vector(0.6, 0.6, 0.6), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Ammo			= "Battery"
SWEP.Primary.Automatic      = true

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Slot = 4
SWEP.SlotPos = 2

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_plasma_rifle" )
	killicon.Add( "dmu_plasma_rifle", "hud/killicons/dmu_plasma_rifle", Color( 255, 80, 0, 255 ) )
end

function SWEP:CSetupDataTables()
	self:NetworkVar( "Float", 0, "Overheat" )
	self:NetworkVar( "Bool", 0, "Overheated" )
end

function SWEP:CInitialize()

	self:SetHoldType( "smg" )

end

local glow1 = Color(30, 154, 255)
local glow2 = Color(255,0,0)

function SWEP:Think()
	if !self:GetOverheated() then
		self:SetOverheat(math.max(0, self:GetOverheat() - 60 * FrameTime()))
		self.VElements.glow.color = glow1
	else
		self.VElements.glow.color = glow2
	end

end

function SWEP:PrimaryAttack()

	if self:GetOwner():GetAmmoCount( "Battery" ) <= 0 or self:GetOverheated() then return end

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

	self:SetNextPrimaryFire( CurTime() + 0.09 ) 

	local owner = self:GetOwner()
	
	self:EmitSound( "dmu/weapons/plasma_rifle/plasma_rifle_single.wav", 120, 98 + 4 * math.random(-1,1), 0.66, CHAN_WEAPON )

	if ( !owner:IsNPC() ) then owner:ViewPunch( Angle( -0.2, util.SharedRandom(self:GetClass(),-0.2,0.2), 0 ) ) end

	self:SetOverheat(math.min(100, self:GetOverheat() + 11))
	if self:GetOverheat() >= 100 then
		self:SetOverheated(true)
		self:EmitSound("buttons/blip2.wav")
		timer.Simple(3, function()
			if !IsValid(self) then return end
			self:SetOverheated(false)
			self:SetOverheat(0)
		end)
	end

	if !SERVER then return end

	local dest = owner:GetAimVector()

	local tr = util.TraceLine( {
		start = owner:EyePos(),
		endpos = owner:EyePos() + dest * 48,
		filter = {owner}
	} )

	if tr.Hit then
		if tr.Entity then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(15)
			dmginfo:SetAttacker(self:GetOwner())
			dmginfo:SetDamageType(DMG_DISSOLVE)
	
			tr.Entity:TakeDamageInfo(dmginfo)
		end
		owner:EmitSound( "physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav", 70, 100, 0.4 )
	else

		local proj = ents.Create("projectile_plasma")

		proj:SetPos(owner:GetShootPos() + dest * 48) -- we did this whole trace thing so we can spawn the projectile further away from the player's face
		proj:SetAngles(dest:Angle()) -- if anyone has a better solution lmk ty

		proj:SetOwner(owner)
		proj:Spawn()

		proj:GetPhysicsObject():SetVelocity(2500 * dest)
	end

	if owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then
		self:SelfDestruct()
	end
end

function SWEP:SecondaryAttack()

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

function SWEP:OnDrop()
	self:SelfDestruct()
end

if not CLIENT then return end

local color_overheat = Color(236,100,37)

function SWEP:DrawHUD()
	local x = ScrW()/2
	local y = ScrH()/2

	surface.SetDrawColor(color_white)
	surface.DrawLine( x - 32, y + 48, x - 32, y + 57)
	surface.DrawLine( x + 32, y + 48, x + 32, y + 57)

	local size = self:GetOverheat() / 100 * 63

	surface.SetDrawColor(color_overheat)
	surface.DrawRect( x - 31, y + 48, size, 10)
end