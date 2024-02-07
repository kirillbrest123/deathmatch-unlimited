SWEP.PrintName = "Battle Rifle"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Semi-automatic rifle. Fires in 3-round bursts. Best suited for mid-long range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_rif_sg552.mdl"
SWEP.ViewModel		= "models/weapons/cstrike/c_rif_sg552.mdl"
SWEP.UseHands = true

SWEP.VElements = {
	["element_name++"] = { type = "Model", model = "models/hunter/misc/roundthing2.mdl", bone = "Base", rel = "", pos = Vector(0.082, -2.862, 6.875), angle = Angle(0, 0, 90), size = Vector(0.009, 0.037, 0.009), color = Color(255, 255, 255, 255), surpresslightning = false, material = "phoenix_storms/metalset_1-2", skin = 0, bodygroup = {} },
	["element_name+"] = { type = "Model", model = "models/hunter/misc/cone2x05.mdl", bone = "Base", rel = "element_name", pos = Vector(0, -0.04, 0.34), angle = Angle(0, 0, -180), size = Vector(0.01, 0.01, 0.01), color = Color(255, 255, 255, 255), surpresslightning = false, material = "debug/env_cubemap_model", skin = 0, bodygroup = {} },
	["element_name"] = { type = "Model", model = "models/hunter/tubes/tube1x1x2.mdl", bone = "Base", rel = "", pos = Vector(0.082, -3.33, 3.332), angle = Angle(0, 0, 0), size = Vector(0.025, 0.025, 0.087), color = Color(255, 255, 255, 255), surpresslightning = false, material = "phoenix_storms/metalset_1-2", skin = 0, bodygroup = {} }
}

SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 90
SWEP.Primary.Ammo			= "AR2"
SWEP.Primary.Automatic      = false

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADS_fov = 40

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

			ang.p = ang.p - 0.15

			owner:SetEyeAngles(ang)
		end
	end

	self:SetNextBullet(CurTime() + 0.04)
	self:SetBulletsToShoot( self:GetBulletsToShoot() - 1 )
end

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end