SWEP.PrintName = "Rocket Launcher"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "A rocket launcher. It launches rockets. Handle with care and stay out of the blast. Best suited for mid range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.UseHands = true

SWEP.ViewModel		= "models/weapons/c_rpg.mdl"
SWEP.WorldModel		= "models/weapons/w_rocket_launcher.mdl"

SWEP.Primary.ClipSize		= 2
SWEP.Primary.DefaultClip	= 4
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "RPG_Round"

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Slot = 4
SWEP.SlotPos = 1

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_rocket_launcher" )
end

function SWEP:CInitialize()
	self:SetHoldType( "rpg" )
end

function SWEP:PrimaryAttack()

	if self:GetReloading() and self:Clip1() > 0 then
		self:SetReloading(false)
	end

	if ( !self:CanPrimaryAttack() ) then return end

	self:EmitSound( "Weapon_RPG.Single" )

	local owner = self:GetOwner()

	if ( !owner:IsNPC() ) then owner:ViewPunch( Angle( -3, 0, 0 ) ) end

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 1 ) 

	if !SERVER then return end

	local dest = owner:GetAimVector()

	local proj = ents.Create("rpg_missile")
	proj:SetPos(owner:GetShootPos())
	proj:SetAngles(dest:Angle())
	proj:SetSaveValue("m_flDamage", 150)

	proj:SetOwner(owner)
	proj:Spawn()

	proj:SetVelocity(dest * 500)
end

function SWEP:Think()
	if CurTime() < self:GetReloadTimer() or !self:GetReloading() then return end

	self:GetOwner():RemoveAmmo( 1, self:GetPrimaryAmmoType() )
	self:SetClip1(self:Clip1() + 1)
	self:EmitSound( "Weapon_RPG.Reload" )
	local owner = self:GetOwner()
	local vm = owner:GetViewModel()

	if self:Clip1() >= self:GetMaxClip1() or self:Ammo1() <= 0 then
		self:SetReloading(false)
		self:SendWeaponAnim(ACT_VM_IDLE)
	else
		self:SendWeaponAnim(ACT_VM_RELOAD)
		self:SetReloadTimer(CurTime() + 1)
	end
end

function SWEP:Reload()
	if self:Clip1() >= self:GetMaxClip1() then return end
	if self:Ammo1() <= 0 then return end
	if self:GetReloading() then return end
	local owner = self:GetOwner()
	local vm = owner:GetViewModel()
	self:SetReloading(true)
	self:SendWeaponAnim(ACT_VM_RELOAD)
	self:SetReloadTimer(CurTime() + 1.2)
end

function SWEP:Holster()
	self:SetReloading(false)
	return true
end

function SWEP:OwnerChanged()
	self:SetReloading(false)
end

function SWEP:SecondaryAttack()

end

if not CLIENT then return end