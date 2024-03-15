SWEP.PrintName = "Oddball"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "An odd-looking ball. Press RMB to drop it."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.HoldType = "melee2"
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.ViewModelFOV = 70
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_R_Hand"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.Slot = 0

SWEP.Melee = true -- used by bots

SWEP.ShowWorldModel = false

SWEP.WElements = {
	["ball"] = { type = "Model", model = "models/Gibs/HGIBS.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.766, 1.455, 0.388), angle = Angle(-17.074, -138.945, -180), size = Vector(1.463, 1.463, 1.463), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.VElements = {
	["ball"] = { type = "Model", model = "models/Gibs/HGIBS.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.444, 1.536, -2.564), angle = Angle(180, 0, 0), size = Vector(1.327, 1.327, 1.327), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

local oddballs = oddballs or {}

function SWEP:CInitialize()

	self:SetHoldType( "melee2" )

	if SERVER then
		if DMU.Mode.Teams then
			for k, _ in ipairs(DMU.Mode.Teams) do
				DMU.AddBotTeamObjective(k, self)
			end
		end

		self.light = ents.Create("light_dynamic")
		self.light:SetKeyValue("brightness", "4")
		self.light:SetKeyValue("distance", "128")
		self.light:SetPos(self:GetPos())
		self.light:Fire("Color", "255 0 0")
		self.light:SetParent(self)
		self.light:Spawn()
		self.light:Activate()
		self.light:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(self.light)

		self.ScoreTimer = CurTime() + 1

		timer.Create(self:GetCreationID() .. "dropped_remove_timer", 30, 1, function()
			if !IsValid(self) or IsValid(self:GetOwner()) then return end
			self:Remove()
		end)
	end
	if CLIENT then
		oddballs[self] = true
	end

	self._owner = self:GetOwner()
end

function SWEP:CSetupDataTables()

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

	local hit_distance = 64

	owner:SetAnimation( PLAYER_ATTACK1 )

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
			endpos = owner:GetShootPos() + owner:GetAimVector() * hit_distance,
			filter = owner,
			mask = MASK_SHOT_HULL
		} )
	end

	local scale = phys_pushscale:GetFloat()

	if IsValid( tr.Entity ) then
		if SERVER then
			local dmginfo = DamageInfo()

			local attacker = owner
			dmginfo:SetAttacker( attacker )

			dmginfo:SetInflictor( self )
			dmginfo:SetDamage( 50 )

			dmginfo:SetDamageForce( owner:GetRight() * -4912 * scale + owner:GetForward() * 9989 * scale )

			SuppressHostEvents( NULL ) -- Let the breakable gibs spawn in multiplayer on client
			tr.Entity:TakeDamageInfo( dmginfo )
			SuppressHostEvents( owner )

			local phys = tr.Entity:GetPhysicsObject()
			if ( IsValid( phys ) ) then
				phys:ApplyForceOffset( owner:GetAimVector() * 80 * phys:GetMass() * scale, tr.HitPos )
			end
		end
	end

    local vm = owner:GetViewModel()

    if tr.Hit then
		self:EmitSound( "dmu/weapons/bfb/hit0" .. math.random(3) .. ".mp3", 110, 100, 0.8, CHAN_WEAPON )
        vm:SendViewModelMatchingSequence( vm:LookupSequence( "Hitcenter" .. math.floor( util.SharedRandom(self:GetClass(), 1, 3) ) ) )
    else
		self:EmitSound( "Zombie.AttackMiss" )
        vm:SendViewModelMatchingSequence( vm:LookupSequence( "Misscenter" .. math.floor( util.SharedRandom(self:GetClass(), 1, 2) ) ) )
    end

	owner:LagCompensation( false )

end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	self:GetOwner():DropWeapon(self)
end

function SWEP:Deploy()
	if !IsFirstTimePredicted() then return true end

	local speed = GetConVarNumber( "sv_defaultdeployspeed" )

	local vm = self:GetOwner():GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "Draw" ) )
	vm:SetPlaybackRate( speed )

	self:SetNextPrimaryFire( CurTime() + vm:SequenceDuration() / speed )
	self:SetNextSecondaryFire( CurTime() + vm:SequenceDuration() / speed )
	self:UpdateNextIdle()

	return true

end

function SWEP:CHolster()

	self:SetNextMeleeAttack( 0 )

	return false

end

function SWEP:Think()

	local vm = self:GetOwner():GetViewModel()
	local curtime = CurTime()
	local idletime = self:GetNextIdle()

	if ( idletime > 0 && CurTime() > idletime ) then

		vm:SendViewModelMatchingSequence( vm:SelectWeightedSequence(ACT_VM_IDLE) )

		self:UpdateNextIdle()

	end

	if SERVER and CurTime() > self.ScoreTimer then
		hook.Run("DMU_OddballScore", self, self:GetOwner())
		self.ScoreTimer = CurTime() + 1
	end

end

function SWEP:Equip(owner)
	owner:SelectWeapon("dmu_oddball")
	DMU.RemoveBotTeamObjective(owner:Team(), self)
end

function SWEP:OnDrop()
	timer.Create(self:GetCreationID() .. "dropped_remove_timer", 30, 1, function()
		if !IsValid(self) or IsValid(self:GetOwner()) then return end
		self:Remove()
	end)

	if DMU.Mode.Teams then
		for k, _ in ipairs(DMU.Mode.Teams) do
			DMU.AddBotTeamObjective(k, self)
		end
	end
end

function SWEP:OwnerChanged()
	if CLIENT and self:GetOwner() == NULL and self._owner == LocalPlayer() then
		local vm = self._owner:GetViewModel()

		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
	end
	self._owner = self:GetOwner()
end

function SWEP:OnRemove()
	if CLIENT then
		oddballs[self] = nil
		return
	end

	hook.Run("DMU_OddballRemoved", self)
	
	if DMU.Mode.Teams then
        for k, _ in ipairs(DMU.Mode.Teams) do
            DMU.RemoveBotTeamObjective(k, self)
        end
    end
end

function SWEP:SelfDestruct() -- stolen from rb655

	self:OnRemove()

	if CLIENT then return end

	if IsValid(self:GetOwner()) then
		self:GetOwner():DropWeapon(self)
	end

	local phys = self:GetPhysicsObject()
	if ( IsValid( phys ) ) then phys:EnableGravity( false ) end

	self:SetName( "dissolve" .. self:EntIndex() )

	local dissolver = ents.Create( "env_entity_dissolver" )
	dissolver:SetPos( self:GetPos() )
	dissolver:Spawn()
	dissolver:Activate()
	dissolver:SetKeyValue( "magnitude", 100 )
	dissolver:SetKeyValue( "dissolvetype", 0 )
	dissolver:Fire( "Dissolve", "dissolve" .. self:EntIndex() )

	timer.Simple(2.2, function()
		dissolver:Remove()
	end)
end

function SWEP:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

if SERVER then return end

local oddball_mat = Material("dmu/oddball.png")

-- i would rather avoid using sv_3d2d.lua whenever an entity exists on client
hook.Add("HUDPaint", "DMU_Oddball3D2D", function()
	for k,_ in pairs(oddballs) do
		local data = k:GetPos():ToScreen()
		if !data.visible then continue end
		surface.SetMaterial(oddball_mat)
		surface.SetDrawColor( IsValid(k:GetOwner()) and team.GetColor(k:GetOwner():Team()) or color_white )
		surface.DrawTexturedRect(data.x - 16, data.y - 16, 32, 32)
	end
end)