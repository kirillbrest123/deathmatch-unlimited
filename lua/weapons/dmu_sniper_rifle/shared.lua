SWEP.PrintName = "Sniper Rifle"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Bolt-action sniper rifle. Powerful enough to rip through multiple targets. Best suited for long range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_snip_awp.mdl" -- may your woes be many and your days few if you don't have css content.
SWEP.ViewModel		= "models/weapons/cstrike/c_snip_awp.mdl"

SWEP.UseHands = true

SWEP.Primary.ClipSize		= 4
SWEP.Primary.DefaultClip	= 12
SWEP.Primary.Ammo			= "357"
SWEP.Primary.Automatic      = false

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADS_fov = 30

SWEP.Slot = 3
SWEP.SlotPos = 3

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_sniper_rifle" )
	killicon.AddFont( "dmu_sniper_rifle", "CSTypeDeath", "r", Color( 255, 80, 0, 255 ), 0.45)
end

function SWEP:CInitialize()

	self:SetHoldType( "ar2" )

end

function SWEP:PrimaryAttack()

	if ( !self:CanPrimaryAttack() ) then return end

	self:EmitSound( "Weapon_357.Single" )

	local owner = self:GetOwner()

	local bullet = {}
	bullet.Num		= 1
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Spread	= 0
	bullet.Tracer	= 1
	bullet.Force	= 1	
	bullet.Damage	= 75
	bullet.AmmoType = self.Primary.Ammo
	bullet.TracerName = "snipertracer"

	self.Pierces = 0

	bullet.Callback = function(attacker, tr, dmginfo)
        if tr.HitGroup == HITGROUP_HEAD then
            dmginfo:ScaleDamage(1.5)
        end
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

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 0.85 ) 

	owner:ViewPunch( Angle( -1.5, 0, 0 ) )
	
	if owner:IsPlayer() and (CLIENT or game.SinglePlayer()) and IsFirstTimePredicted() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil

		local ang = owner:EyeAngles()

		ang.p = ang.p - 1.5

		owner:SetEyeAngles(ang)
	end
end

function SWEP:SecondaryAttack()

end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end