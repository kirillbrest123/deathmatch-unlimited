SWEP.PrintName = "Grenade Launcher"

SWEP.Author = ".kkrill"
SWEP.Instructions = "A grenade launcher. It launches grenades. Holding the trigger will allow you to shoot grenades at higher velocity. Handle with extreme care. Best suited for short-mid range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.HoldType = "physgun"
SWEP.ViewModelFOV = 58
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_physcannon.mdl"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

SWEP.VElements = {
	["element_name"] = { type = "Model", model = "models/props_trainstation/trashcan_indoor001b.mdl", bone = "Base", rel = "", pos = Vector(0.063, 2.545, 11.161), angle = Angle(0, 0, 0), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["glow"] = { type = "Sprite", sprite = "sprites/glow01", bone = "ValveBiped.Bip01_R_Hand", rel = "element_name", pos = Vector(0, 0, 5.771), size = { x = 10, y = 10 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["element_name+"] = { type = "Model", model = "models/props_trainstation/trashcan_indoor001b.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(21.423, -3.106, -5.261), angle = Angle(-88.567, 5.073, -6.467), size = Vector(0.405, 0.405, 0.405), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["element_name"] = { type = "Model", model = "models/Items/grenadeAmmo.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(22.979, -2.662, -5.081), angle = Angle(-98.155, 5.073, -6.467), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.Primary.ClipSize		= 6
SWEP.Primary.DefaultClip	= 12
SWEP.Primary.Ammo			= "Grenade"
SWEP.Primary.Automatic      = false

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= ""

SWEP.Scoped = true
SWEP.ADSZoom = 0.88

SWEP.VerticalRecoil			= 1.5

SWEP.Slot = 4
SWEP.SlotPos = 3

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_grenade_launcher" )
end

function SWEP:CSetupDataTables()
	self:NetworkVar( "Float", 0, "ChargeTimer" )
	self:NetworkVar( "Float", 1, "Delay" )
end

function SWEP:CInitialize()

	self:SetHoldType( "physgun" )
	self.LoopSound = CreateSound( self, "Airboat_engine_idle" )

end

function SWEP:FirePrimary()

	self:EmitSound( "dmu/weapons/grenade_launcher/fire1.mp3", 140, 100, 0.55, CHAN_WEAPON )

	local owner = self:GetOwner()

	self:ShootEffects()

	self:TakePrimaryAmmo( 1 )

	owner:ViewPunch( Angle( -self.VerticalRecoil, 0, 0 ) )

	if owner:IsPlayer() and (CLIENT or game.SinglePlayer()) and IsFirstTimePredicted() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil
		local ang = owner:EyeAngles()

		ang.p = ang.p - self.VerticalRecoil

		owner:SetEyeAngles(ang)
	end

	if !SERVER then return end

	if self:GetChargeTimer() == 0 then self:SetChargeTimer( CurTime() ) end -- for some reason weird things happen if you hold the mouse for just one tick or smth
	local velocity = 600 + math.Clamp( CurTime() - self:GetChargeTimer() , 0, 3 ) * 600

	local dest = owner:GetAimVector()

	local proj = ents.Create("npc_grenade_frag")
	proj:SetOwner(owner)
	proj:SetPos(owner:GetShootPos())
	proj:SetAngles(dest:Angle())
	proj:SetSaveValue("m_hThrower", owner) -- brother why things just can't be nice and simple
	proj:Fire("SetTimer", "1", 0)
	proj:AddCallback("PhysicsCollide", function(ent, data)
		-- proj:Fire("SetTimer", "0", 0)
	end)

	proj:Spawn()
	-- proj:Activate()

	proj:GetPhysicsObject():SetVelocity(dest * velocity)

	owner:ViewPunch( Angle( -self.VerticalRecoil, 0, 0 ) )

	-- self.NextReload = CurTime() + owner:GetViewModel():SequenceDuration() + 0.1
end

function SWEP:CThink()

	if self:GetOwner():IsBot() or self:GetDelay() >= CurTime() then goto reload end

	if self:GetOwner():KeyPressed( IN_ATTACK )  then
		if self:GetReloading() and self:Clip1() > 0 then
			self:SetReloading(false)
		end

		if self:CanPrimaryAttack() then
			self:SendWeaponAnim( ACT_VM_RELOAD )

			self:SetChargeTimer( CurTime() )
			if IsFirstTimePredicted() then
				self:StartChargeSound()
			end
		end
	end

	if self:GetChargeTimer() != 0 then
		self.LoopSound:ChangePitch( 100 + math.min( 3, CurTime() - self:GetChargeTimer() ) * 30 )

		if !self:GetOwner():KeyDown( IN_ATTACK ) and self:GetOwner():KeyDownLast( IN_ATTACK ) or CurTime() - self:GetChargeTimer() >= 4 then
			self:StopChargeSound()
			self:FirePrimary()
			self:SetChargeTimer(0)
			self:SetDelay( CurTime() + 0.5 )
		end
	end

	::reload::

	if CurTime() < self:GetReloadTimer() or !self:GetReloading() then return end
	local owner = self:GetOwner()

	if self:Clip1() >= self:GetMaxClip1() or self:Ammo1() <= 0 then
		self:SetReloading(false)
		self:SendWeaponAnim( ACT_VM_IDLE )
	end

	if self:GetReloading() then
		owner:RemoveAmmo( 1, self:GetPrimaryAmmoType() )
		self:SetClip1(self:Clip1() + 1)
		self:SetReloadTimer(CurTime() + 0.8)

		self:EmitSound( "dmu/weapons/grenade_launcher/insert_round.mp3", 75, 100, 1, CHAN_ITEM )
	end
end

function SWEP:PrimaryAttack() -- bots use a simplified control scheme
	if !self:GetOwner():IsBot() then return end
	if !self:CanPrimaryAttack() then return end

	self:SetNextPrimaryFire( CurTime() + 1.3 )
	self:SetChargeTimer( CurTime() - 0.5 )
	self:StartChargeSound()
	timer.Simple( 0.5, function()
		if !IsValid( self ) or !IsValid( self:GetOwner() ) or !self:GetOwner():Alive() or !self:GetOwner():IsBot() then return end
		self:StopChargeSound()
		self:FirePrimary()
		self:SetChargeTimer( 0 )
	end)

end

function SWEP:SecondaryAttack()

end

function SWEP:Reload()
	if (self.NextReload or 0) > CurTime() then return end
	if self:Clip1() >= self:GetMaxClip1() then return end
	if self:Ammo1() <= 0 then return end
	if self:GetReloading() or self:GetChargeTimer() != 0 then return end

	local owner = self:GetOwner()

	self:SetReloading(true)
	self:SetReloadTimer(CurTime() + 0.6)

	self:SendWeaponAnim( ACT_VM_HOLSTER )
	owner:SetAnimation( PLAYER_RELOAD )
end

function SWEP:StartChargeSound()
	self.LoopSound:Play()
end

function SWEP:StopChargeSound()
	self.LoopSound:Stop()
end

function SWEP:Equip( owner )
	owner:Give( "weapon_frag" ) -- you get grenades with the weapon. you should be able to use them'
end

function SWEP:CHolster()
	self:SetChargeTimer(0)

	self:StopChargeSound()

	return true
end

function SWEP:COnRemove()
	self:StopChargeSound()
end

function SWEP:OnDrop()
	self:StopChargeSound()
end

function SWEP:OwnerChanged()
	self:SetReloading( false )
	self:StopChargeSound()
	self:SetChargeTimer( 0 )
	self:SetDelay( 0 )
end

if !CLIENT then return end

local color_overheat = Color(236,100,37)

function SWEP:DrawHUD()
	local x = ScrW()/2
	local y = ScrH()/2

	surface.SetDrawColor(color_white)
	surface.DrawLine( x - 32, y + 48, x - 32, y + 57)
	surface.DrawLine( x + 32, y + 48, x + 32, y + 57)

	if self:GetChargeTimer() == 0 then return end

	local size = math.Clamp( CurTime() - self:GetChargeTimer(), 0, 3 ) * 21

	surface.SetDrawColor(color_overheat)
	surface.DrawRect( x - 31, y + 48, size, 10)
end