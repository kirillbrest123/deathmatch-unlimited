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
SWEP.ADS_fov = 56

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

	if owner:IsPlayer() then 
		owner:ViewPunch( Angle( -0.3, util.SharedRandom(self:GetClass(),-0.3,0.3), 0 ) )
	end
end

function SWEP:SecondaryAttack()

end