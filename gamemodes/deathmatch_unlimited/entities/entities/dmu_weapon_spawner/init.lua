AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.RespawnTime = 0

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "weapon" then
        self.WeaponClassName = value
    elseif key == "fallbackweapon" then
        self.FallbackWeapon = value
    elseif key == "fallbackrarity" then
        self.FallbackRarity = string.lower(value)
    elseif key == "respawntime" then
        self.RespawnTime = tonumber(value)
    elseif key == "target" then
        self.WeaponClassName = string.lower(value)
        self:SetupWeapon() -- i think mmm remembers datatables and overwrites them after ENT:KeyValue(), so we need to set the weapon instantly 
    elseif key == "speed" then
        self.RespawnTime = tonumber(value)
    end
end

local respawn_time_convar = GetConVar("dmu_server_weapon_respawn_time")

function ENT:SetupWeapon()
    if self.WeaponClassName and DMU.weapon_to_rarity[self.WeaponClassName] then
        self:SetWeapon(self.WeaponClassName)
    elseif self.FallbackWeapon and DMU.weapon_to_rarity[self.FallbackWeapon] then -- try again
        self:SetWeapon(self.FallbackWeapon)
    elseif self.FallbackRarity and DMU.Weapons[self.FallbackRarity] then -- try harder
        local tbl = DMU.Weapons[self.FallbackRarity]
        self:SetWeapon(tbl[math.random(#tbl)])
    else
        self:SetWeapon("weapon_pistol")
    end
end

function ENT:Initialize()

    if DMU.Mode.WeaponSpawnsDisabled then self:Remove() return end

    if self.RespawnTime == 0 then
        self.RespawnTime = respawn_time_convar:GetInt()
    end

    self:SetModel("models/props_junk/sawblade001a.mdl")

    self:PhysicsInitBox(Vector(-16, -16, 0), Vector(16, 16, 8))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

    self:DropToFloor()

    self:SetTrigger(true)
    self:UseTriggerBounds(true, 8)
    
    self:SetupWeapon()
end

local sandbox = GetConVar("dmu_server_sandbox")

function ENT:UpdateTransmitState()
    if sandbox:GetBool() then return TRANSMIT_ALWAYS end -- uhhh so when an entity leaves PVS (i.e stop getting networked) all clientside models get unparented
	return TRANSMIT_PVS -- it's not a serious issue but it's annoying when working with MMM so yeah we just always network it then
end

function ENT:StartTouch(entity)
    if entity:IsPlayer() and entity:Alive() and not self:GetEmpty() then
        local wpn = entity:Give(self:GetWeapon())

        if wpn == NULL then -- player already has weapon, give ammo instead
            local wpn_ent = entity:GetWeapon(self:GetWeapon())
            local ammo = wpn_ent.Primary and wpn_ent.Primary.DefaultClip or (wpn_ent:GetMaxClip1() != -1 and wpn_ent:GetMaxClip1() * 3 or 3) -- if it's not an engine weapon give default clip. If it's an engine weapon and max clip is -1 give 3 rounds, otherwise give 3 clips
            entity:GiveAmmo(ammo, wpn_ent:GetPrimaryAmmoType())
        elseif !wpn.Primary or !wpn.Primary.DefaultClip then -- player doesn't have weapon but it's an engine weapon so it only has 1 clip by default
            local ammo = wpn:GetMaxClip1() != -1 and wpn:GetMaxClip1() * 2 or 2
            entity:GiveAmmo(ammo, wpn:GetPrimaryAmmoType())
        end

        self:SetEmpty(true)
        timer.Create("dmu_weapon_spawner" .. self:GetCreationID(), self.RespawnTime, 1, function()
            if not self:IsValid() then return end
            self:SetEmpty(false)
        end)
    end
end