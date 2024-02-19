SWEP.PrintName = "Flag"
    
SWEP.Author = ".kkrill"
SWEP.Instructions = "A flag. Press RMB to drop it. You should probably bring it to your base."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.HoldType = "melee2"
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.ViewModelFOV = 54
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
	["element_name1"] = { type = "Model", model = "models/hunter/plates/plate05x075.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(7.225, -10.745, -30.733), angle = Angle(94.378, -6.52, 0), size = Vector(0.5, 0.5, 0.009), color = Color(255, 255, 255, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["element_name"] = { type = "Model", model = "models/hunter/plates/plate2.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.849, 0.639, -13.863), angle = Angle(6.446, 0, 90), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.VElements = {
	["element_name1"] = { type = "Model", model = "models/hunter/plates/plate05x075.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.371, -4.861, -32.243), angle = Angle(90, 90, 90), size = Vector(0.5, 0.5, 0.009), color = Color(255, 255, 255, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["element_name"] = { type = "Model", model = "models/hunter/plates/plate2.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.371, 0.686, -14.837), angle = Angle(0, 0, 90), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

local flags = flags or {}

function SWEP:CInitialize()

	self:SetHoldType( "melee2" )

	if SERVER then
		DMU.AddBotObjective(self)
	end
	if CLIENT then
		flags[self] = true
	end
end

function SWEP:CSetupDataTables()

	self:NetworkVar( "Float", 0, "NextMeleeAttack" )
	self:NetworkVar( "Float", 1, "NextIdle" )
	self:NetworkVar( "Int", 0, "Team" )

	self:NetworkVarNotify("Team", self.TeamChanged)
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

	if IsValid( tr.Entity ) and ( tr.Entity:IsNPC() or (tr.Entity:IsPlayer() and ( tr.Entity:Team() != owner:Team() or tr.Entity:Team() == TEAM_UNASSIGNED ) ) ) then

		self:EmitSound( "Weapon_Crowbar.Melee_Hit" )

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
		end
	else
		self:EmitSound( "Weapon_Crowbar.Single" )
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
	if CLIENT then return end
	self:GetOwner():DropWeapon(self)
	timer.Simple(15, function()
		if !IsValid(self) or IsValid(self:GetOwner()) then return end
		self:Remove()
	end)
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

function SWEP:Holster()

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

end

function SWEP:Equip(owner)
	if owner:Team() == self:GetTeam() then
		self:Remove()
		return
	end
	owner:SelectWeapon("dmu_flag")
	self._owner = owner
	local bases = ents.FindByClass("dmu_flag_base")
	for k,v in ipairs(bases) do
		if v:GetTeam() == owner:Team() then
			self.valid_base = v
			break
		end
	end
	if self.valid_base then
		DMU.AddBotPersonalObjective(owner, self.valid_base)
	end
end

function SWEP:OnRemove()
	if CLIENT then
		flags[self] = nil
		return
	end
	
	DMU.RemoveBotObjective(self)
	if IsValid(self.valid_base) then
		DMU.RemoveBotPersonalObjective(self._owner, self.valid_base)
	end
end

function SWEP:OnDrop()
	if IsValid(self.valid_base) then
		DMU.RemoveBotPersonalObjective(self._owner, self.valid_base)
	end

	self._owner = NULL
end

function SWEP:TeamChanged(name, old, new)
	self.WElements.element_name1.color = team.GetColor(new)
	self.VElements.element_name1.color = team.GetColor(new)
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

local flag_mat = Material("dmu/flag.png")

-- i would rather avoid using sv_3d2d.lua whenever an entity exists on client
hook.Add("HUDPaint", "DMU_Flags3D2D", function()

	for k,v in pairs(flags) do
		local data = k:GetPos():ToScreen()
		if !data.visible then continue end
		surface.SetMaterial(flag_mat)
		surface.SetDrawColor(team.GetColor(k:GetTeam()))
		surface.DrawTexturedRect(data.x, data.y, 24, 24)
	end

end)