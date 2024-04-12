SWEP.PrintName = "Carbine"

SWEP.Author = ".kkrill"
SWEP.Instructions = "Semi-automatic rifle. Best suited for mid-long range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_rif_galil.mdl" -- yeah i probably need to learn blender or smth at this point
SWEP.ViewModel		= "models/weapons/cstrike/c_rif_galil.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize		= 15
SWEP.Primary.DefaultClip	= 60
SWEP.Primary.Ammo			= "AR2"
SWEP.Primary.Automatic      = true

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADSFov = 56

SWEP.VerticalRecoil			= 0.45
SWEP.HorizontalRecoil		= 0.05

SWEP.Slot = 1
SWEP.SlotPos = 2

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_carbine" )
	killicon.AddFont( "dmu_carbine", "CSTypeDeath", "v", Color( 255, 80, 0, 255 ), 0.45)
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
	bullet.Spread	= 0
	bullet.Tracer	= 2
	bullet.Force	= 1
	bullet.Damage	= 32
	bullet.AmmoType = self.Primary.Ammo

	owner:FireBullets( bullet )

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 0.3 )

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