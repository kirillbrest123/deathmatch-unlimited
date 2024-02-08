SWEP.PrintName = "Shotgun"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Semi-automatic shotgun. Absolutely devastates everything unfortunate enough to be in its range. Best suited for close range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.UseHands = true

SWEP.ViewModel		= "models/weapons/c_shotgun.mdl"
SWEP.WorldModel		= "models/weapons/w_shotgun.mdl"

SWEP.Primary.ClipSize		= 3
SWEP.Primary.DefaultClip	= 8
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "Buckshot"

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Slot = 3
SWEP.SlotPos = 1

-- SWEP.Reloading = false
-- SWEP.ReloadTimer = 0
-- SWEP.NextReload = 0

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_shotgun" )
	killicon.AddAlias( "dmu_shotgun", "weapon_shotgun" )
end

function CSetupDataTables()

end

function SWEP:CInitialize()
	self:SetHoldType( "shotgun" )
end

function SWEP:PrimaryAttack()

	if self:GetReloading() and self:Clip1() > 0 then
		self:SetReloading(false)
	end

	if ( !self:CanPrimaryAttack() ) then return end

	self:EmitSound( "Weapon_Shotgun.Double" )

	local owner = self:GetOwner()

	local bullet = {}
	bullet.Num		= 1
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Tracer	= 1	
	bullet.Force	= 1	
	bullet.Damage	= 25
	bullet.AmmoType = self.Primary.Ammo

	bullet.Callback = function(attacker, tr, dmginfo)
		if tr.HitGroup == HITGROUP_HEAD then
			dmginfo:ScaleDamage(0.8) // 40 headshot damage 
		end
		local dist = tr.StartPos:Distance(tr.HitPos)
		local falloff = 1 - math.Clamp((dist - 320) / 896, 0, 1) // up to 25% damage falloff starting at 20m up to 40m
		dmginfo:ScaleDamage(falloff)

	end

	owner:FireBullets( bullet )

	for i=1, 6 do
		bullet.Dir = (owner:EyeAngles() + Angle(2.2*math.sin(i/6*2*math.pi), 2.2*math.cos(i/6*2*math.pi), 0)):Forward()
		-- PLEASE I DON'T KNOW HOW TO DO COMPLEX THINGS WITH VECTORS
		-- THE THING ABOVE SOMEWHAT WORKS UNTIL YOU START LOOKING DOWN
		-- THEN YAW JUST CEASES TO EXIST FOR SOME FUCKING REASON
		-- PLEASE HELP

		owner:FireBullets( bullet )
	end
	self:ShootEffects()
	self.NextReload = CurTime() + owner:GetViewModel():SequenceDuration() + 0.3

	self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 1 ) 

	local owner = self:GetOwner()
	if ( !owner:IsNPC() ) then owner:ViewPunch( Angle( -3, 0, 0 ) ) end
end

function SWEP:Think()
	if CurTime() < self:GetReloadTimer() or !self:GetReloading() then return end
	local owner = self:GetOwner()
	local vm = owner:GetViewModel()

	if self:Clip1() >= self:GetMaxClip1() or self:Ammo1() <= 0 then
		self:SetReloading(false)
		vm:SendViewModelMatchingSequence( vm:SelectWeightedSequence( ACT_VM_IDLE ) )
	end

	if self:GetReloading() then
		owner:RemoveAmmo( 1, self:GetPrimaryAmmoType() )
		self:SetClip1(self:Clip1() + 1)
		vm:SendViewModelMatchingSequence( vm:SelectWeightedSequence( ACT_VM_RELOAD ) )
		self:SetReloadTimer(CurTime() + 0.5)

		self:EmitSound( "Weapon_Shotgun.Reload" )
	end 
end

function SWEP:Reload()
	if (self.NextReload or 0) > CurTime() then return end
	if self:Clip1() >= self:GetMaxClip1() then return end
	if self:Ammo1() <= 0 then return end
	if self:GetReloading() then return end

	local owner = self:GetOwner()
	local vm = owner:GetViewModel()

	self:SetReloading(true)
	self:SetReloadTimer(CurTime() + 0.6)

	vm:SendViewModelMatchingSequence( vm:SelectWeightedSequence( ACT_VM_RELOAD ) )
	owner:SetAnimation( PLAYER_RELOAD )
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

function SWEP:OnDrop()
	self:SetClip1(self.Primary.ClipSize)
end