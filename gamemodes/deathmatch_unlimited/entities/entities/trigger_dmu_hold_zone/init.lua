ENT.Type = "brush"

ENT.LastThink = 0
ENT.ThinkInterval = 1.2
ENT.PlayersInZone = {}
ENT.Team = -1
ENT.HoldProgress = 0
ENT.Disabled = false
ENT.Identifier = 0

util.AddNetworkString("DMU_HoldZoneHUD")

function ENT:KeyValue(key, value)
	key = string.lower(key)
    value = string.lower(value)
	if key == "identifier" then
        self.Identifier = tonumber(value)
    end
end

function ENT:Initialize()
    if !DMU.Mode.HillsEnabled then self:Remove() return end
    self.LastThink = CurTime()
    DMU.Add3D2DPos(self:EntIndex(), self:GetPos(), "hold_zone_icons/hold_zone_" .. self.Identifier .. ".png")

    for k, _ in ipairs(DMU.Mode.Teams) do
        table.insert(DMU.BotTeamObjectives[k], self)
    end
end

function ENT:OnRemove()
    DMU.Remove3D2DPos(self:EntIndex())
end

function ENT:Disable()
    DMU.Remove3D2DPos(self:EntIndex())
    for k, _ in ipairs(DMU.Mode.Teams) do
        table.RemoveByValue(DMU.BotTeamObjectives[k], self)
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
    DMU.Add3D2DPos(self:EntIndex(), self:GetPos(), "hold_zone_icons/hold_zone_" .. self.Identifier .. ".png")

    for k, _ in ipairs(DMU.Mode.Teams) do
        table.insert(DMU.BotTeamObjectives[k], self)
    end
end

-- God, this code is kind of a mess. Might've gone a bit overboard with early-returns. Thought without them it'd probably be even worse.
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
        self.HoldProgress = self.HoldProgress + 25
    end

    if self.HoldProgress >= 100 then
        if self.Team != -1 then
            table.insert(DMU.BotTeamObjectives[self.Team], self) -- bots should care when their zone is captured
            self.Team = -1
            self.HoldProgress = 0
            DMU.Add3D2DPos(self:EntIndex(), self:GetPos(), "hold_zone_icons/hold_zone_" .. self.Identifier .. ".png")
        else
            self.Team = biggest_team
            table.RemoveByValue(DMU.BotTeamObjectives[self.Team], self) -- bots shouldn't care about zones they have captured
            self.HoldProgress = 0
            DMU.Add3D2DPos(self:EntIndex(), self:GetPos(), "hold_zone_icons/hold_zone_" .. self.Identifier .. ".png", team.GetColor(biggest_team))
        end
    end

    for _, ply in pairs(self.PlayersInZone) do
        net.Start("DMU_HoldZoneHUD")
            net.WriteBool(true)
            net.WriteInt(self.Team, 12)
            net.WriteInt(self.HoldProgress, 8)
            net.WriteUInt(self.Identifier, 4)
        net.Send(ply)
    end
end

function ENT:StartTouch(ent)
    if not (ent:IsPlayer() and ent:Alive()) or self.Disabled then return end
    self.PlayersInZone[ent:EntIndex()] = ent
    net.Start("DMU_HoldZoneHUD")
        net.WriteBool(true)
        net.WriteInt(self.Team, 12)
        net.WriteInt(self.HoldProgress, 8)
        net.WriteUInt(self.Identifier, 4)
    net.Send(ent)
end

function ENT:EndTouch(ent)
    if not ent:IsPlayer() then return end
    self.PlayersInZone[ent:EntIndex()] = nil
    net.Start("DMU_HoldZoneHUD")
        net.WriteBool(false)
        net.WriteInt(-1, 12)
        net.WriteInt(0, 8)
        net.WriteUInt(0, 4) 
    net.Send(ent)
end