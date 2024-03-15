AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.LastThink = 0
ENT.ThinkInterval = 1.2
ENT.PlayersInZone = {}
ENT.Team = -1
ENT.HoldProgress = 0
ENT.Disabled = false

util.AddNetworkString("DMU_HoldZoneHUD")

function ENT:KeyValue(key, value)
	key = string.lower(key)
    if key == "target" and value != "" then
        self:SetIdentifier( tonumber(value) ) -- backwards compatibility
    end
end

function ENT:Initialize()
    if !DMU.Mode.HillsEnabled or !DMU.Mode.Teams then self:Remove() return end
    self.Disabled = false
    self.LastThink = CurTime()
    -- timer.Simple(0.1, function() -- will hopefully make sure that it networks the right thing
        DMU.Add3D2DEnt(self, "hold_zone_icons/hold_zone_" .. self:GetIdentifier() .. ".png")
    -- end)

    if DMU.Mode.Teams then
        for k, _ in ipairs(DMU.Mode.Teams) do
            DMU.AddBotTeamObjective(k, self)
        end
    end

    -- OH MY FUCKING GOD
    -- even if collision group is set to debris, bullets still collide with an invisible error model, that's why we have to use fence
    -- but then you can't +USE while inside it
    -- all of the problem are solved if we only set solid to none
    -- BUT then you can't grab/click on it at all, so you can't even make it permament in MMM
    self:SetModel("models/props_c17/fence01a.mdl")

    self:PhysicsInitBox(Vector(-16,-16,0), Vector(16,16,16))
    self:SetCollisionBounds(Vector(-256,-256,-64), Vector(256,256,64))
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:GetPhysicsObject():EnableMotion(false)

    if !GetConVar("dmu_server_sandbox"):GetBool() then -- that's the best solution i could think off. Another option would be using like a proxy entity or smth but i'd rather not
        self:SetSolid(SOLID_NONE)
        self:SetMoveType(MOVETYPE_NONE)
    end

    self:SetTrigger(true)
    self:UseTriggerBounds(true) 
    self:DrawShadow(false)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:OnRemove()
    if DMU.Mode.Teams then
        for k, _ in ipairs(DMU.Mode.Teams) do
            DMU.RemoveBotTeamObjective(k, self)
        end
    end
    DMU.Remove3D2DEnt(self)
end

function ENT:Disable()
    DMU.Remove3D2DEnt(self)
    if DMU.Mode.Teams then
        for k, _ in ipairs(DMU.Mode.Teams) do
            DMU.RemoveBotTeamObjective(k, self)
        end
    end

    self.Disabled = true
    self.HoldProgress = 0
    self.Team = -1
    for k,v in pairs(self.PlayersInZone) do
        net.Start("DMU_HoldZoneHUD")
            net.WriteBool(false)
            net.WriteInt(-1, 12)
            net.WriteInt(0, 8)   
            net.WriteUInt(0, 4)
        net.Send(v)
    end
    self.PlayersInZone = {}
end

function ENT:Enable()
    self.Disabled = false
    self.LastThink = CurTime()
    DMU.Add3D2DEnt(self, "hold_zone_icons/hold_zone_" .. self:GetIdentifier() .. ".png")

    for k, _ in ipairs(DMU.Mode.Teams) do
        DMU.AddBotTeamObjective(k, self)
    end
end

-- God, this code is kind of a mess. Might've gone a bit overboard with early-returns. Though without them it'd probably be even worse.
function ENT:Think()
    if self.LastThink > CurTime() or self.Disabled then return end
    self.LastThink = CurTime() + self.ThinkInterval
    
    if self.Team != -1 then
        hook.Run("DMU_HoldZoneScore", self:EntIndex(), self.Team)
    end

    if table.IsEmpty(self.PlayersInZone) then
        self.HoldProgress = math.Max(0, self.HoldProgress - 25)
        return
    end

    local team_players_in_zone = {}

    for _, ply in pairs(self.PlayersInZone) do
        team_players_in_zone[ply:Team()] = (team_players_in_zone[ply:Team()] or 0) + 1
    end

    local biggest_team = table.GetWinningKey(team_players_in_zone)
    local draws = 0

    for k,v in pairs(team_players_in_zone) do
        if v == team_players_in_zone[biggest_team] then
            draws = draws + 1
        end
    end

    if draws > 1 then return end
    
    if self.Team == biggest_team then
        self.HoldProgress = math.Max(0, self.HoldProgress - 25)
    else
        self.HoldProgress = math.min(self.HoldProgress + 15 + team_players_in_zone[biggest_team] * 10, 100)
    end

    if self.HoldProgress >= 100 then
        local old_team = self.Team

        if self.Team != -1 then
            DMU.AddBotTeamObjective(self.Team, self)
            self.Team = -1
            self.HoldProgress = 0
            DMU.Add3D2DEnt(self, "hold_zone_icons/hold_zone_" .. self:GetIdentifier() .. ".png")
        else
            self.Team = biggest_team
            DMU.RemoveBotTeamObjective(self.Team, self)
            self.HoldProgress = 0
            DMU.Add3D2DEnt(self, "hold_zone_icons/hold_zone_" .. self:GetIdentifier() .. ".png", team.GetColor(biggest_team))
        end

        hook.Run("DMU_HoldZoneCaptured", self, biggest_team, self.Team, old_team)
    end

    for _, ply in pairs(self.PlayersInZone) do
        net.Start("DMU_HoldZoneHUD")
            net.WriteBool(true)
            net.WriteInt(self.Team, 12)
            net.WriteInt(self.HoldProgress, 8)
            net.WriteUInt(self:GetIdentifier(), 4)
        net.Send(ply)
    end
end

function ENT:StartTouch(ent)
    if !(ent:IsPlayer() and ent:Alive()) or self.Disabled then return end
    self.PlayersInZone[ent:EntIndex()] = ent
    net.Start("DMU_HoldZoneHUD")
        net.WriteBool(true)
        net.WriteInt(self.Team, 12)
        net.WriteInt(self.HoldProgress, 8)
        net.WriteUInt(self:GetIdentifier(), 4)
    net.Send(ent)
end

function ENT:EndTouch(ent)
    if !ent:IsPlayer() then return end
    self.PlayersInZone[ent:EntIndex()] = nil
    net.Start("DMU_HoldZoneHUD")
        net.WriteBool(false)
        net.WriteInt(-1, 12)
        net.WriteInt(0, 8)  
        net.WriteUInt(0, 4)
    net.Send(ent)
end