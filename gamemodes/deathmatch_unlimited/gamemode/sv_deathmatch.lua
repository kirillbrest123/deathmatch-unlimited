DMU.BotObjectives = {}
DMU.BotTeamObjectives = {}
CreateConVar("dmu_server_num_of_map_choices", "3", FCVAR_ARCHIVE + FCVAR_NEVER_AS_STRING, "Number of choices during the map phase of voting.")
function DMU.AutoAssign(ply)
    local best_team = team.BestAutoJoinTeam()
    if best_team == ply:Team() then return end
    if (team.NumPlayers(best_team) + 1 < team.NumPlayers(ply:Team())) or ply:Team() == 1001 then ply:SetTeam(best_team) end
end

util.AddNetworkString("DMU_MatchVictoryAnnouncement")
function DMU.EndGame(winner)
    if DMU.GameEnded then return end
    DMU.GameEnded = true
    if not winner then -- try to find a winner
        if DMU.Mode.FFA then
            local players = player.GetAll()
            winner = players[1]
            for k, v in ipairs(players) do
                if v:GetScore() > winner:GetScore() then winner = v end
            end
        else
            local teams = DMU.Mode.Teams
            winner = 1
            for k, v in ipairs(teams) do
                if team.GetScore(k) > team.GetScore(winner) then winner = k end
            end
        end
    end

    hook.Run("DMU_GameEnded", winner)
    local is_winner_player = isentity(winner)
    net.Start("DMU_MatchVictoryAnnouncement")
    net.WriteBool(is_winner_player)
    if is_winner_player then
        net.WriteEntity(winner)
    else
        net.WriteUInt(winner, 13)
    end

    net.Broadcast()
    if not DMU.Mode.FFA and not is_winner_player then
        local plys = team.GetPlayers(winner)
        local mvp = plys[1]
        for _, ply in ipairs(plys) do
            if ply:GetScore() > mvp:GetScore() then mvp = ply end
        end

        timer.Simple(5, function() DMU.GiveMedal(mvp, "mvp") end)
    end

    timer.Simple(10, function() DMU.StartVotes() end)
end

-- try to avoid spawning in opposing teams' players' LoS
hook.Add("IsSpawnpointSuitable", "dmu_IsSpawnpointSuitable", function(ply, spawnpoint, bMakeSuitable)
    if bMakeSuitable then return true end
    local players = player.GetAll()
    for k, v in ipairs(players) do
        if v:Team() == TEAM_SPECTATOR or v:Team() == TEAM_CONNECTING or v == ply or (v:Team() == ply:Team() and v:Team() ~= TEAM_UNASSIGNED) then table.remove(players, k) end
    end

    for k, v in ipairs(players) do
        local tr = util.TraceLine({
            start = spawnpoint:GetPos() + Vector(0, 0, 64),
            endpos = v:GetPos() + Vector(0, 0, 64),
        })

        if tr.Entity and tr.Entity:IsPlayer() then return false end
    end
    return true
end)

local function death_spectate(ply)
    timer.Simple(0, function()
        ply:SetObserverMode(OBS_MODE_ROAMING)
        ply:SetMoveType(MOVETYPE_OBSERVER)
    end)
end

-- Disable respawning manually
hook.Add("PlayerDeathThink", "dmu_PlayerDeathThink", function(ply) return false end)
hook.Add("PlayerDeath", "DMU_PlayerDeath", function(ply)
    ply:StripAmmo()
    if DMU.Mode.RespawnTime < 0 then
        death_spectate(ply)
        return
    end

    timer.Create(ply:SteamID64() .. "respawn_timer", DMU.Mode.RespawnTime, 1, function()
        if not IsValid(ply) then return end
        ply:Spawn()
    end)
end)

hook.Add("PlayerSilentDeath", "DMU_PlayerDeath", function(ply)
    ply:StripAmmo()
    if DMU.Mode.RespawnTime < 0 or (not DMU.Mode.FFA and ply:Team() == TEAM_UNASSIGNED and not ply:IsBot()) then
        death_spectate(ply)
        return
    end

    timer.Create(ply:SteamID64() .. "respawn_timer", DMU.Mode.RespawnTime, 1, function()
        if not IsValid(ply) then return end
        ply:Spawn()
    end)
end)

hook.Add("DoPlayerDeath", "DMU_DropWeaponsOnDeath", function(ply)
    if DMU.Mode.DontDropWeapons then return end
    for _, wpn in ipairs(ply:GetWeapons()) do
        timer.Create(wpn:GetCreationID() .. "dropped_remove_timer", 15, 1, function()
            if not wpn:IsValid() or wpn:GetOwner():IsValid() then return end
            wpn:Remove()
        end)

        ply:DropWeapon(wpn)
    end
end)

-- Config menu
util.AddNetworkString("DMU_ShowConfigMenu")
util.AddNetworkString("DMU_SaveConfig")
function DMU.ShowConfigMenu(ply)
    net.Start("DMU_ShowConfigMenu")
    net.Send(ply)
end

hook.Add("ShowSpare2", "DMU_ShowConfigMenu", function(ply)
    if ply:IsSuperAdmin() then
        net.Start("DMU_SendPlayLists")
        net.WriteTable(DMU.PlayLists)
        net.Send(ply)
        DMU.ShowConfigMenu(ply)
    end
end)

-- this whole weapons system was a bit of an after thought
-- probably should've just had something like DMU.Config table with all of that stuff
-- but oh well. at least i was able to resort to convars...
net.Receive("DMU_SaveConfig", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    DMU.SendNotification("Config saved!", ply)
    GetConVar("dmu_server_weapons_starter"):SetString(net.ReadString())
    GetConVar("dmu_server_weapons_common"):SetString(net.ReadString())
    GetConVar("dmu_server_weapons_uncommon"):SetString(net.ReadString())
    GetConVar("dmu_server_weapons_rare"):SetString(net.ReadString())
    GetConVar("dmu_server_weapons_very_rare"):SetString(net.ReadString())
end)

-- Team stuff
-- okay so in non-ffa game modes the player life cycle is as follows:
-- PlayerInitialSpawn() is called -> player is *killed silently* (doesn't respawn because he's TEAM_UNASSIGNED) -> team menu shows up -> once a team is selected, player *spawns*
-- if a player changes teams after that, he's *killed silently* and will be respawned in accordance with MODE.RespawnTime
-- ^idk if that'll be useful to anyone other than myself
function GM:PlayerCanJoinTeam(ply, t)
    if ply:Team() == t then
        ply:ChatPrint("You're already on that team")
        return false
    end

    if not DMU.Mode.Teams[t] then
        ply:ChatPrint("Invalid team!")
        return false
    end

    if CurTime() < (ply.TeamChangeCooldown or 0) then
        ply:ChatPrint("Please wait " .. math.Round(ply.TeamChangeCooldown - CurTime()) .. " more seconds before trying to change team again")
        ply.TeamChangeCooldown = ply.TeamChangeCooldown + 1
        return false
    end

    local a = team.NumPlayers(1)
    for k, v in ipairs(DMU.Mode.Teams) do
        local b = team.NumPlayers(k)
        if a > b then a = b end
    end

    if a + 1 < team.NumPlayers(t) then
        ply:ChatPrint("There's too few players on the other team!")
        return false
    else
        return true
    end
end

function GM:PlayerRequestTeam(ply, t)
    if DMU.Mode.FFA then return end
    if t == -1 then
        if ply:Team() == TEAM_UNASSIGNED then
            DMU.AutoAssign(ply)
            ply:Spawn()
        else
            ply:KillSilent()
            DMU.AutoAssign(ply)
        end

        ply.TeamChangeCooldown = CurTime() + 60
        return
    end

    if GAMEMODE:PlayerCanJoinTeam(ply, t) then
        if ply:Team() == TEAM_UNASSIGNED then
            ply:SetTeam(t)
            ply:Spawn() -- it's a hack to allow game modes like showdown to function
        else
            ply:SetTeam(t)
            ply:KillSilent()
        end

        ply.TeamChangeCooldown = CurTime() + 60
    end
end

util.AddNetworkString("DMU_ShowTeamMenu")
function GM:ShowTeam(ply)
    if DMU.Mode.FFA then return end
    net.Start("DMU_ShowTeamMenu")
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "DMU_PlayerInit", function(ply)
    if DMU.Mode.FFA or ply:IsBot() then return end
    timer.Simple(0, function()
        ply:KillSilent()
        GAMEMODE:ShowTeam(ply)
    end)
end)

hook.Add("PlayerSpawn", "DMU_SetPlayerSpawn", function(ply)
    ply:DisableWorldClicking(true)
    if ply:IsBot() and not DMU.Mode.FFA then DMU.AutoAssign(ply) end
    timer.Simple(0, function()
        local color = team.GetColor(ply:Team())
        ply:SetPlayerColor(color:ToVector())
    end)
end)

hook.Add("EntityTakeDamage", "dmu_FriendlyFire", function(target, dmginfo)
    if DMU.Mode.FriendlyFire then return end
    local attacker = dmginfo:GetAttacker()
    if target:IsPlayer() and attacker:IsPlayer() and target ~= attacker and target:Team() == attacker:Team() then
        dmginfo:SetDamage(0)
        return true
    end
end)

function GM:PlayerSelectSpawn(pl, transiton)
    -- If we are in transition, do not reset player's position
    if transiton then return end
    if DMU.Mode.UseTeamSpawns then
        local ent = self:PlayerSelectTeamSpawn(pl:Team(), pl)
        if IsValid(ent) then return ent end
    end

    -- Save information about all of the spawn points
    -- in a team based game you'd split up the spawns
    if not IsTableOfEntitiesValid(self.SpawnPoints) then
        self.LastSpawnPoint = 0
        self.SpawnPoints = ents.FindByClass("info_player_start")
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_deathmatch"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_combine"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_rebel"))
        -- CS Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_counterterrorist"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_terrorist"))
        -- DOD Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_axis"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_allies"))
        -- (Old) GMod Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("gmod_player_start"))
        -- TF Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_teamspawn"))
        -- INS Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("ins_spawnpoint"))
        -- AOC Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("aoc_spawnpoint"))
        -- Dystopia Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("dys_spawn_point"))
        -- PVKII Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_pirate"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_viking"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_knight"))
        -- DIPRIP Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("diprip_start_team_blue"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("diprip_start_team_red"))
        -- OB Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_red"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_blue"))
        -- SYN Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_coop"))
        -- ZPS Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_human"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_zombie"))
        -- ZM Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_zombiemaster"))
        -- FOF Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_fof"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_desperado"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_player_vigilante"))
        -- L4D Maps
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("info_survivor_rescue"))
        -- Removing this one for the time being, c1m4_atrium has one of these in a box under the map
        --self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_survivor_position" ) )
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("dmu_team_spawn_1"))
        self.SpawnPoints = table.Add(self.SpawnPoints, ents.FindByClass("dmu_team_spawn_2"))
    end

    local Count = table.Count(self.SpawnPoints)
    if Count == 0 then
        Msg("[PlayerSelectSpawn] Error! No spawn points!\n")
        return nil
    end

    -- If any of the spawnpoints have a MASTER flag then only use that one.
    -- This is needed for single player maps.
    for k, v in pairs(self.SpawnPoints) do
        if v:HasSpawnFlags(1) and hook.Call("IsSpawnpointSuitable", GAMEMODE, pl, v, true) then return v end
    end

    local ChosenSpawnPoint = nil
    -- Try to work out the best, random spawnpoint
    for i = 1, Count do
        ChosenSpawnPoint = table.Random(self.SpawnPoints)
        if IsValid(ChosenSpawnPoint) and ChosenSpawnPoint:IsInWorld() then
            if (ChosenSpawnPoint == pl:GetVar("LastSpawnpoint") or ChosenSpawnPoint == self.LastSpawnPoint) and Count > 1 then continue end
            if hook.Call("IsSpawnpointSuitable", GAMEMODE, pl, ChosenSpawnPoint, i == Count) then
                self.LastSpawnPoint = ChosenSpawnPoint
                pl:SetVar("LastSpawnpoint", ChosenSpawnPoint)
                return ChosenSpawnPoint
            end
        end
    end
    return ChosenSpawnPoint
end