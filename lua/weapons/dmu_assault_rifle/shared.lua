SWEP.PrintName = "Assault Rifle"

SWEP.Author = ".kkrill"
SWEP.Instructions = "Fully-automatic rifle. Best suited for close-mid range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_irifle.mdl"
SWEP.ViewModel		= "models/weapons/c_irifle.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 140
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "AR2"

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADSFov = 56

SWEP.HorizontalRecoil		= 0.1
SWEP.VerticalRecoil			= 0.3

SWEP.Slot = 2
SWEP.SlotPos = 2

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_assault_rifle" )
	killicon.AddAlias( "dmu_assault_rifle", "weapon_ar2" )
end

function SWEP:CInitialize()

	self:SetHoldType( "ar2" )

end

function SWEP:PrimaryAttack()

	if ( !self:CanPrimaryAttack() ) then return end

	self:EmitSound( "Weapon_AR2.Single" )

	local owner = self:GetOwner()

	local bullet = {}
	bullet.Num		= 1
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Spread	= Vector(0.01,0.01,0)
	bullet.Tracer	= 2
	bullet.Force	= 1
	bullet.Damage	= 13
	bullet.AmmoType = self.Primary.Ammo
	bullet.TracerName = "AR2Tracer"

     bullet.Callback = function(attacker, tr, dmginfo)
		local dist = tr.StartPos:Distance(tr.HitPos)
		local falloff = 1 - math.Clamp((dist - 1024) / 1024, 0, 1) * 0.25 -- up to 25% damage falloff starting at 20m up to 40m
		dmginfo:ScaleDamage(falloff)

    end

	owner:FireBullets( bullet )

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 0.1 )

	local rand = util.SharedRandom( self:GetClass(), -self.HorizontalRecoil, self.HorizontalRecoil )

	owner:ViewPunch( Angle( -self.VerticalRecoil * 0.8, rand * 0.8, 0 ) )

	if owner:IsPlayer() and (CLIENT or game.SinglePlayer()) and IsFirstTimePredicted() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil
		local ang = owner:EyeAngles()

		ang.p = ang.p - self.VerticalRecoil
		ang.y = ang.y + rand

		owner:SetEyeAngles(ang)
	end
end

function SWEP:SecondaryAttack()

end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end

if !CLIENT then return end

function SWEP:DrawHUDBackground()
	if not self:GetADS() then return end
	DrawMaterialOverlay( "effects/combine_binocoverlay", 0 )
end