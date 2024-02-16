SWEP.PrintName = "BFB"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "Big Friendly Baton. Hits like a truck when powered."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.HoldType = "melee2"
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV = 54
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {}

SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "Thumper"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.Slot = 0
SWEP.SlotPos = 1

SWEP.Melee = true -- used by bots

if CLIENT then
	SWEP.BounceWeaponIcon = false
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_bfb" )
	killicon.AddAlias( "dmu_bfb", "weapon_stunstick" )
end

function SWEP:Initialize()

	self:SetHoldType( "melee2" )

end

function SWEP:SetupDataTables()

	self:NetworkVar( "Float", 0, "NextMeleeAttack" )
	self:NetworkVar( "Float", 1, "NextIdle" )

end

function SWEP:UpdateNextIdle()

	local vm = self:GetOwner():GetViewModel()
	self:SetNextIdle( CurTime() + vm:SequenceDuration() / vm:GetPlaybackRate() )

end

local phys_pushscale = GetConVar( "phys_pushscale" )

function SWEP:PrimaryAttack()

	local owner = self:GetOwner()
	local powered = owner:GetAmmoCount(self.Primary.Ammo) >= 25

	local hit_distance = powered and 160 or 64

	owner:SetAnimation( PLAYER_ATTACK1 )

	self:EmitSound( "Weapon_StunStick.Swing" )

	self:UpdateNextIdle()

	self:SetNextPrimaryFire( CurTime() + 0.85 )

	owner:LagCompensation( true )

	local tr = util.TraceHull( {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * hit_distance,
		filter = owner,
		mins = Vector( -10, -10, -8 ),
		maxs = Vector( 10, 10, 8 ),
		mask = MASK_SHOT_HULL
	} )

	if !IsValid( tr.Entity ) or ( !tr.Entity:IsNPC() and !( tr.Entity:IsPlayer() and ( tr.Entity:Team() != owner:Team() or tr.Entity:Team() == TEAM_UNASSIGNED ) ) ) then
		tr = util.TraceLine( {
			start = owner:GetShootPos(),
			endpos = owner:GetShootPos() + owner:GetAimVector() * 64,
			filter = owner,
			mask = MASK_SHOT_HULL
		} )
	end

	-- We need the second part for single player because SWEP:Think is ran shared in SP
	if ( tr.Hit and !( game.SinglePlayer() and CLIENT ) and IsFirstTimePredicted() ) then
		local ef = EffectData()
		ef:SetOrigin(tr.HitPos)
		ef:SetStart(tr.StartPos)
		ef:SetSurfaceProp(tr.SurfaceProps)
		ef:SetDamageType(DMG_CLUB)
		ef:SetHitBox(tr.HitBox)
		ef:SetEntity(tr.Entity)

		util.Effect("Impact", ef)
		util.Effect("StunstickImpact", ef)
		util.Decal("ExplosiveGunshot", tr.StartPos, tr.HitPos)
	end

	local scale = phys_pushscale:GetFloat()

	if IsValid( tr.Entity ) and ( tr.Entity:IsNPC() or (tr.Entity:IsPlayer() and ( tr.Entity:Team() != owner:Team() or tr.Entity:Team() == TEAM_UNASSIGNED ) ) ) then

		if powered then
			owner:SetFriction(0)
			owner:SetVelocity( (tr.Entity:GetPos() - owner:GetPos()) * 9 ) -- we actually don't normalize the thing here so it's proportional to the distance between the things
		end

		self:EmitSound( "dmu/weapons/bfb/hit0" .. math.random(3) .. ".mp3", 110, 100, 0.8, CHAN_WEAPON )

		timer.Simple(0.05, function()
			if !IsValid(self) or !IsValid(owner) or !owner:Alive() then return end

			if powered then
				owner:SetFriction(1)
				owner:SetVelocity( owner:GetVelocity() * -0.6 ) -- "If applied to a player, this will actually ADD velocity, not set it."
				self:TakePrimaryAmmo(25)
				
				local ef = EffectData()
				ef:SetEntity(tr.Entity)
				ef:SetMagnitude(10)
			
				util.Effect("TeslaHitboxes", ef)
			end
			
			if SERVER then
				local dmginfo = DamageInfo()

				local attacker = owner
				dmginfo:SetAttacker( attacker )

				dmginfo:SetInflictor( self )
				dmginfo:SetDamage( powered and 200 or 50 )

				dmginfo:SetDamageForce( owner:GetRight() * -4912 * scale + owner:GetForward() * 9989 * scale )

				SuppressHostEvents( NULL ) -- Let the breakable gibs spawn in multiplayer on client
				tr.Entity:TakeDamageInfo( dmginfo )
				SuppressHostEvents( owner )
			end
		end)
	end

    local vm = owner:GetViewModel()

    if tr.Hit then
        vm:SendViewModelMatchingSequence( vm:LookupSequence( "Hitcenter" .. math.floor( util.SharedRandom(self:GetClass(), 1, 3) ) ) )
    else
        vm:SendViewModelMatchingSequence( vm:LookupSequence( "Misscenter" .. math.floor( util.SharedRandom(self:GetClass(), 1, 2) ) ) )
    end

	owner:LagCompensation( false )

end

function SWEP:SecondaryAttack()

end

function SWEP:Deploy()
	if !IsFirstTimePredicted() then return true end

	local speed = GetConVarNumber( "sv_defaultdeployspeed" )

	local vm = self:GetOwner():GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "Draw" ) )
	vm:SetPlaybackRate( speed )

	local ef = EffectData()
	ef:SetOrigin( self:GetOwner():GetBonePosition(11) )
	ef:SetMagnitude( 1 )
	ef:SetScale( 1 )
	ef:SetRadius( 4 )
	util.Effect( "Sparks", ef )

	self:EmitSound("Weapon_StunStick.Activate")

	self:SetNextPrimaryFire( CurTime() + vm:SequenceDuration() / speed )
	self:SetNextSecondaryFire( CurTime() + vm:SequenceDuration() / speed )
	self:UpdateNextIdle()

	return true

end

function SWEP:Holster()

	self:SetNextMeleeAttack( 0 )

	return true

end

function SWEP:Think()

	local vm = self:GetOwner():GetViewModel()
	local curtime = CurTime()
	local idletime = self:GetNextIdle()

	if ( idletime > 0 && CurTime() > idletime ) then

		vm:SendViewModelMatchingSequence( vm:SelectWeightedSequence(ACT_VM_IDLE) )

		self:UpdateNextIdle()

	end

end