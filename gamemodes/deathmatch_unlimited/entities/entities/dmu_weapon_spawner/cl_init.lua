include("shared.lua")

local material_dot = Material("icon16/bullet_white.png", "alphatest smooth")
local material_glow = Material("dmu_weapon_spawner/light_glow01")

local engine_weapon_tables = {
	weapon_pistol = {
		PrintName = "#HL2_PISTOL",
		WorldModel = "models/weapons/w_pistol.mdl",
	},
	weapon_357 = {
		PrintName = "#HL2_357HANDGUN",
		WorldModel = "models/weapons/w_357.mdl",
	},
	weapon_crossbow = {
		PrintName = "#HL2_CROSSBOW",
		WorldModel = "models/weapons/w_crossbow.mdl",
	},
	weapon_crowbar = {
		PrintName = "#HL2_CROWBAR",
		WorldModel = "models/weapons/w_crowbar.mdl",
	},
	weapon_frag = {
		PrintName = "#HL2_GRENADE",
		WorldModel = "models/weapons/w_grenade.mdl",
	},
	weapon_physcannon = {
		PrintName = "#HL2_GRAVITYGUN",
		WorldModel = "models/weapons/w_Physics.mdl",
	},
	weapon_ar2 = {
		PrintName = "#HL2_PULSE_RIFLE",
		WorldModel = "models/weapons/w_irifle.mdl",
	},
	weapon_rpg = {
		PrintName = "#HL2_RPG",
		WorldModel = "models/weapons/w_rocket_launcher.mdl",
	},
	weapon_slam = {
		PrintName = "#HL2_SLAM",
		WorldModel = "models/weapons/w_slam.mdl",
	},
	weapon_shotgun = {
		PrintName = "#HL2_SHOTGUN",
		WorldModel = "models/weapons/w_shotgun.mdl",
	},
	weapon_smg1 = {
		PrintName = "#HL2_SMG1",
		WorldModel = "models/weapons/w_smg1.mdl",
	},
	weapon_stunstick = {
		PrintName = "#HL2_STUNBATON",
		WorldModel = "models/weapons/w_stunbaton.mdl",
	},
	weapon_physgun = {
		PrintName = "#GMOD_PHYSGUN",
		WorldModel = "models/weapons/w_Physics.mdl",
	},
}

local function Draw3DText( pos, scale, text)
	local ang = EyeAngles()
	ang:RotateAroundAxis(ang:Right(),90)
	ang:RotateAroundAxis(-ang:Up(),90)

	cam.Start3D2D( pos, ang, scale )
		draw.SimpleTextOutlined( text, "CloseCaption_BoldItalic", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
	cam.End3D2D()
end

function ENT:Draw()
	-- Draw the model
	self:DrawModel()

	-- The text to display
	self.WeaponName = self.WeaponName or ""

	-- The position. We use model bounds to make the text appear just above the model. Customize this to your liking.
	local mins, maxs = self:GetModelBounds()
	local pos = self:GetPos() + Vector( 0, 0, maxs.z + 56 )

	local ang = Angle( 0, SysTime() * 25 % 360, 0 )

	if not IsValid(self.WeaponModel) or not IsValid(self.WeaponModel.Overlay) then -- FUCKYOUFUCKYOUFUCKYOUFUCKYOU
		self:Initialize()
		return 
	end

	self.WeaponModel:SetAngles(ang)
	self.WeaponModel.Overlay:SetAngles(ang)

	if self:GetEmpty() then return end -- Don't draw most of stuff when it's empty

	Draw3DText( pos, 0.2, self.WeaponName)

	cam.Start3D()
		render.DrawLine(self:GetPos() + Vector(0,0,30), self:GetPos() + Vector(0,0,48), color_white, true)
		render.SetMaterial(material_dot)
		render.DrawSprite( self:GetPos() + Vector(0,0,48), 4, 4, color_white)
		render.SetMaterial(material_glow)
		render.DrawSprite( self:GetPos() + Vector(0,0,4), 128, 64, self.Color)
	cam.End3D()
end

-- TODO: uhhh idk maybe sck support? that'd be neat. though that'd probably mean no overlays cuz that's 2x client models
function ENT:Initialize()
	if IsValid(self.WeaponModel) then self.WeaponModel:Remove() end
	self.WeaponModel = ClientsideModel("models/weapons/w_pistol.mdl")
    self.WeaponModel:SetParent(self)
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self.WeaponModel:SetPos(self:GetPos() + Vector(0,0,24))

	if IsValid(self.WeaponModel.Overlay) then self.WeaponModel.Overlay:Remove() end -- should i be ashamed of this?
	self.WeaponModel.Overlay = ClientsideModel("models/weapons/w_pistol.mdl")
	self.WeaponModel.Overlay:SetParent(self.WeaponModel)
	self.WeaponModel.Overlay:SetMaterial("models/props_combine/portalball001_sheet")
	self.WeaponModel.Overlay:SetModelScale(1.01, 0)
	self.WeaponModel.Overlay:SetPos(self.WeaponModel:GetPos())

	if self:GetWeapon() then
		self:WeaponChanged(nil, nil, self:GetWeapon())
	end
	if self:GetEmpty() then
		self:EmptyChanged(nil, nil, self:GetEmpty())
	end
end

function ENT:OnRemove()
	if not IsValid(self.WeaponModel) or not IsValid(self.WeaponModel.Overlay) then -- FUCKYOUFUCKYOUFUCKYOUFUCKYOU
		self:Initialize()
		return 
	end
	self.WeaponModel:Remove()
	self.WeaponModel.Overlay:Remove()
end

function ENT:WeaponChanged(name, old, new_weapon)
	if new == "" then return end -- I HAVE NO IDEA WHY, BUT WHEN PLAYING WITH NET_FAKELAG 100 ENT:INITIALIZE() GETS CALLED WHENEVER IT ENTERS PVS (?) AND SELF:GETWEAPONTABLE() RETURNS ""
	local weapon = weapons.GetStored(new_weapon)
	if !weapon then
		weapon = engine_weapon_tables[new_weapon]
	end
	if !weapon then
		weapon = {WorldModel = "models/weapons/w_irifle.mdl", PrintName = "UNKNOWN WEAPON"}
	end
	if not IsValid(self.WeaponModel) or not IsValid(self.WeaponModel.Overlay) then -- FUCKYOUFUCKYOUFUCKYOUFUCKYOU
		self:Initialize()
		return 
	end
	self.WeaponModel:SetModel(weapon.WorldModel)
	self.WeaponModel.Overlay:SetModel(weapon.WorldModel)

	self.WeaponName = weapon.PrintName

	local rarity = DMU.weapon_to_rarity[new_weapon]

	self.Color = DMU.rarity_to_color[rarity] or DMU.rarity_to_color["common"]

	self.WeaponModel.Overlay:SetColor(self.Color)
end

function ENT:EmptyChanged(name, old, new)
	if new then
		self.WeaponModel:SetNoDraw(true)
	else
		self.WeaponModel:SetNoDraw(false)
	end
end