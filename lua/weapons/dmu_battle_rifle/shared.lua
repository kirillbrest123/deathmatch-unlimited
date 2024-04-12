SWEP.PrintName = "Battle Rifle"

SWEP.Author = ".kkrill"
SWEP.Instructions = "Semi-automatic rifle. Fires in 3-round bursts. Best suited for mid-long range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_rif_sg552.mdl"
SWEP.ViewModel		= "models/weapons/cstrike/c_rif_sg552.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 90
SWEP.Primary.Ammo			= "AR2"
SWEP.Primary.Automatic      = false

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADSFov = 40

SWEP.BulletsToShoot = 0
SWEP.NextBulletShoot = 0

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_battle_rifle" )
	killicon.AddFont( "dmu_battle_rifle", "CSTypeDeath", "A", Color( 255, 80, 0, 255 ), 0.45)
end

function SWEP:CSetupDataTables()
	self:NetworkVar( "Int", 0, "BulletsToShoot" ) -- god i hate using these
	self:NetworkVar( "Float", 0, "NextBullet" ) -- but i have to. otherwise no prediction
end

SWEP.Slot = 2
SWEP.SlotPos = 3

function SWEP:CInitialize()

	self:SetHoldType( "ar2" )

end

function SWEP:PrimaryAttack()

	if ( !self:CanPrimaryAttack() ) then return end

	self:SetBulletsToShoot(3)

    self:SetNextPrimaryFire( CurTime() + 0.48 )
end

function SWEP:CThink()
	if self:GetBulletsToShoot() <= 0 or CurTime() < self:GetNextBullet() then return end
	if self:Clip1() <= 0 then
		self:SetBulletsToShoot(0)
		return
	end

	local owner = self:GetOwner()

	local bullet = {}
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Num		= 1
	bullet.Spread	= 0
	bullet.Tracer	= 2
	bullet.Force	= 1
	bullet.Damage	= 15
	bullet.AmmoType = self.Primary.Ammo
	bullet.TracerName = "AR2Tracer"

	self:ShootEffects()

	self:EmitSound( "Weapon_AR2.Single" )

	owner:FireBullets( bullet )

	self:TakePrimaryAmmo( 1 )

	if owner:IsPlayer() and IsFirstTimePredicted() then
		owner:ViewPunch( Angle( -0.1, 0, 0 ) )

		if CLIENT or game.SinglePlayer() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil
			local ang = owner:EyeAngles()

			ang.p = ang.p - 0.2

			owner:SetEyeAngles(ang)
		end
	end

	self:SetNextBullet(CurTime() + 0.04)
	self:SetBulletsToShoot( self:GetBulletsToShoot() - 1 )
end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end

if !CLIENT then return end

function SWEP:DrawHUDBackground()
	if not self:GetADS() then return end
	DrawMaterialOverlay( "effects/combine_binocoverlay", 0 )
end