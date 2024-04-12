SWEP.PrintName = "Auto Crossbow"

SWEP.Author = ".kkrill"
SWEP.Instructions = "Fully-automatic crossbow. Fires red-hot bolts of steel rebar with enough force to pin its victim to a wall. Best suited for mid-long range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel		= "models/weapons/w_crossbow.mdl"
SWEP.ViewModel		= "models/weapons/c_crossbow.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 30
SWEP.Primary.Ammo			= "XBowBolt"
SWEP.Primary.Automatic      = true

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADSFov = 40

SWEP.VerticalRecoil			= 0.4
SWEP.HorizontalRecoil		= 0.05

SWEP.Slot = 3
SWEP.SlotPos = 2

SWEP.VElements = {
	["element_name"] = { type = "Model", model = "models/weapons/c_smg1.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(10.541, -5.614, -27.368), angle = Angle(90, 0, -90), size = Vector(1.695, 1.695, 1.695), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.WElements = {
	["element_name"] = { type = "Model", model = "models/weapons/w_smg1.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(8.751, -1.655, -1.89), angle = Angle(0, 12.123, 180), size = Vector(1.123, 1.644, 1.123), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_crossbow" )
end

function SWEP:CInitialize()

	self:SetHoldType( "crossbow" )

end

function SWEP:PrimaryAttack()

	if self:GetOwner():GetAmmoCount( "XBowBolt" ) <= 0 then return end

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

	self:SetNextPrimaryFire( CurTime() + 0.4 )

	local owner = self:GetOwner()

	self:EmitSound("Weapon_Crossbow.Single")

	local rand = util.SharedRandom( self:GetClass(), -self.HorizontalRecoil, self.HorizontalRecoil )

	owner:ViewPunch( Angle( -self.VerticalRecoil * 0.8, rand * 0.8, 0 ) )

	if owner:IsPlayer() and (CLIENT or game.SinglePlayer()) and IsFirstTimePredicted() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil
		local ang = owner:EyeAngles()

		ang.p = ang.p - self.VerticalRecoil
		ang.y = ang.y + rand

		owner:SetEyeAngles(ang)
	end

	if !SERVER then return end

	local dest = owner:GetAimVector()

	local tr = util.TraceLine( {
		start = owner:EyePos(),
		endpos = owner:EyePos() + dest * 48,
		filter = {owner}
	} )

	if tr.Hit then
		if IsValid(tr.Entity) then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(45)
			dmginfo:SetAttacker(self:GetOwner())
			dmginfo:SetDamageType(DMG_BULLET)

			tr.Entity:TakeDamageInfo(dmginfo)
			owner:EmitSound("Weapon_Crossbow.BoltHitBody")
		else
			owner:EmitSound("Weapon_Crossbow.BoltHitWorld")
		end
	else
		local proj = ents.Create("crossbow_bolt")
		proj:Fire("SetDamage", "40") -- HAAHAHAHAHAHA I FOUND IT
		proj:SetOwner(owner)

		proj:SetPos(owner:GetShootPos())
		proj:SetAngles(dest:Angle())

		proj:SetVelocity(dest * 3500)

		timer.Simple(0, function() -- WHY DOES IT NOT APPLY DAMAGE UNTIL 1 TICK HAS PASSED
			proj:Spawn()
		end)
	end
end

function SWEP:ShootEffects()

	local owner = self:GetOwner()
	if !IsValid(owner) then return end -- because that can happen

	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	timer.Simple(0, function()
		owner:GetViewModel():SetSequence("idle")
	end)
	owner:MuzzleFlash()
	owner:SetAnimation( PLAYER_ATTACK1 )

end

if !CLIENT then return end

function SWEP:DrawHUDBackground()
	if not self:GetADS() then return end
	DrawMaterialOverlay( "effects/combine_binocoverlay", 0 )
end