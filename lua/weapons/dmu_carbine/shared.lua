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
SWEP.Primary.Automatic      = false

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADS_fov = 56

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

    self:SetNextPrimaryFire( CurTime() + 0.25 ) 

	local owner = self:GetOwner()
	if !owner:IsNPC() then owner:ViewPunch( Angle( -1, 0, 0 ) ) end
end

function SWEP:SecondaryAttack()

end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end