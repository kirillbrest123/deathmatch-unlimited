SWEP.PrintName = "Pistol"

SWEP.Author = ".kkrill"
SWEP.Instructions = "Fully-automatic 9mm handgun. Best suited for close range combat as a last resort.\nPress RMB to enter precision mode, lowering spray, recoil and fire rate."
SWEP.Category = "Deathmatch Unlimited"
SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.UseHands = true

SWEP.VElements = {
	["glow"] = { type = "Sprite", sprite = "sprites/glow01", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.645, 2.165, -2.902), size = { x = 1, y = 1 }, color = Color(0, 255, 0, 0), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}

SWEP.ViewModel		= "models/weapons/c_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"

SWEP.IronSightsPos = Vector(-6.04, 0, 3.079)
SWEP.IronSightsAng = Vector(0.1, -1.3, 0)
-- SWEP.IronSightsPos = Vector(-3.56, 6.599, -4.361)
-- SWEP.IronSightsAng = Vector(0, 0, -34.3)

SWEP.Primary.ClipSize		= 17
SWEP.Primary.DefaultClip	= 60
SWEP.Primary.Ammo			= "Pistol"
SWEP.Primary.Automatic      = true

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.VerticalRecoil			= 0.6
SWEP.HorizontalRecoil		= 0.3

SWEP.Scoped = true
SWEP.ADSZoom = 0.86

SWEP.Slot = 1
SWEP.SlotPos = 1

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_pistol" )
	killicon.AddAlias( "dmu_pistol", "weapon_pistol" )
end

function SWEP:CInitialize()

	self:SetHoldType( "pistol" )

end

function SWEP:PrimaryAttack()

	if ( !self:CanPrimaryAttack() ) then return end

	self:EmitSound( "Weapon_Pistol.Single" )

	local owner = self:GetOwner()

	local recoil_mult = self:GetADS() and 0.5 or 1

	local bullet = {}
	bullet.Num		= 1
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Spread	= Vector(0.0175, 0.0175, 0) * recoil_mult
	bullet.Tracer	= 2
	bullet.Force	= 1
	bullet.Damage	= 13
	bullet.AmmoType = self.Primary.Ammo

	bullet.Callback = function(attacker, tr, dmginfo)
		local dist = tr.StartPos:Distance(tr.HitPos)
		local falloff = 1 - math.Clamp((dist - 768) / 768, 0, 1) * 0.25 // up to 25% damage falloff starting at 20m up to 40m
		dmginfo:ScaleDamage(falloff)
    end

	owner:FireBullets( bullet )

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + (self:GetADS() and 0.18 or 0.13) )

	local rand = util.SharedRandom( self:GetClass(), -self.HorizontalRecoil, self.HorizontalRecoil )

	owner:ViewPunch( Angle( -self.VerticalRecoil * recoil_mult, rand * recoil_mult, 0 ) )

	if owner:IsPlayer() and (CLIENT or game.SinglePlayer()) and IsFirstTimePredicted() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil
		local ang = owner:EyeAngles()

		ang.p = ang.p - self.VerticalRecoil * recoil_mult
		ang.y = ang.y + rand * recoil_mult

		owner:SetEyeAngles(ang)
	end
end

function SWEP:SecondaryAttack()

end

local ads_progress = 0

function SWEP:CalcViewModelView( vm, old_pos, old_ang, pos, ang )
	ads_progress = math.Clamp( ads_progress + ( self:GetADS() and 1 or -1 ) * 2 * RealFrameTime(), 0, 1 )

	local new_pos = self:GetADS() and old_pos or pos -- old pos is position before weapon sway is applied so i.e if we're aiming then don't weapon sway

	local right = ang:Right()
	local forward = ang:Forward()
	local up = ang:Up()

	old_pos = old_pos + self.IronSightsPos.x * right * Lerp( ads_progress, 0, 1 )
	old_pos = old_pos + self.IronSightsPos.y * forward * Lerp( ads_progress, 0, 1 )
	old_pos = old_pos + self.IronSightsPos.z * up * Lerp( ads_progress, 0, 1 )

	ang = ang * 1 -- ?????
	ang:RotateAroundAxis( right, self.IronSightsAng.x * ads_progress )
	ang:RotateAroundAxis( up, self.IronSightsAng.y * ads_progress )
	ang:RotateAroundAxis( forward, self.IronSightsAng.z * ads_progress )
	return old_pos, ang
end

-- shame on me!
function SWEP:Think()
	local owner = self:GetOwner()

	if self:GetReloading() and CurTime() >= self:GetReloadTimer() then
		self:SetReloading(false)

		local num = math.min(owner:GetAmmoCount(self:GetPrimaryAmmoType()), self:GetMaxClip1() - self:Clip1())

		self:SetClip1( self:Clip1() + num )
		owner:RemoveAmmo( num, self:GetPrimaryAmmoType() )

	end

	if owner:KeyPressed( IN_ATTACK2) then
		self:SetADS( true )
		owner:SetFOV(owner:GetFOV() * self.ADSZoom, 0.3)
		self.VElements.glow.color.a = 200
		if CLIENT and IsFirstTimePredicted() then
			surface.PlaySound( "npc/turret_floor/click1.wav" )
		end
	end

	if !owner:KeyDown( IN_ATTACK2 ) and owner:KeyDownLast( IN_ATTACK2 ) then
		self:SetADS( false )
		owner:SetFOV(0, 0.3)
		self.VElements.glow.color.a = 0
	end
end

function SWEP:AdjustMouseSensitivity()
	if not self:GetADS() then return end
	return self.ADSZoom
end

function SWEP:DrawHUDBackground()

end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end