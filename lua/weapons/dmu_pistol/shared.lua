SWEP.PrintName = "Pistol"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Fully-automatic 9mm handgun. Best suited for close range combat as a last resort."
SWEP.Category = "Deathmatch Unlimited"
SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.UseHands = true

SWEP.ViewModel		= "models/weapons/c_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize		= 15
SWEP.Primary.DefaultClip	= 60
SWEP.Primary.Ammo			= "Pistol"
SWEP.Primary.Automatic      = true

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

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

	local bullet = {}
	bullet.Num		= 1
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Spread	= Vector(0.0175,0.0175,0)
	bullet.Tracer	= 2	
	bullet.Force	= 1	
	bullet.Damage	= 12
	bullet.AmmoType = self.Primary.Ammo

	bullet.Callback = function(attacker, tr, dmginfo)
		local dist = tr.StartPos:Distance(tr.HitPos)
		local falloff = 1 - math.Clamp((dist - 768) / 768, 0, 1) * 0.25 // up to 25% damage falloff starting at 20m up to 40m
		dmginfo:ScaleDamage(falloff)
    end

	owner:FireBullets( bullet )

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 0.13 ) 

	local owner = self:GetOwner()
	if owner:IsPlayer() then
		owner:ViewPunch( Angle( -0.4, util.SharedRandom(self:GetClass(),-0.4,0.4), 0 ) )
	end
end

function SWEP:SecondaryAttack()

end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end