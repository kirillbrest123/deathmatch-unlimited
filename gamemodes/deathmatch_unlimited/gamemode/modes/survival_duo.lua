MODE.Name = "Survival Duo"
MODE.FriendlyFire = false
MODE.RespawnTime = -1
MODE.TimeLimit = 300
MODE.FFA = true
MODE.RoundBased = true
MODE.RoundLimit = 7

local dead_players = {}

MODE.Instructions = "Death is permament.\nEvery round you get assigned a random partner.\nIf you die and your partner is still alive, you can respawn after 30 seconds.\nBe the last team standing."

MODE.Teams = {}

for i = 1, math.ceil(game.MaxPlayers()/2) do
    local color = HSVToColor( 360 * (i / math.ceil(game.MaxPlayers()/2)), 1, 1 )
    local t = {
        name = "Team " .. i,
        color = Color(color.r, color.g, color.b) -- FUCK YOU
    }
    table.insert(MODE.Teams, t)
end

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    ply:Give("dmu_fists")
    
    return true
end

MODE.Hooks.PlayerInitialSpawn = function(ply)
    if DMU.RoundEnded or DMU.GameEnded then return end
    timer.Simple(0, function()
        DMU.AutoAssign(ply)
    end)
    if player.GetCount() > 3 and dead_players[ply:SteamID64()] then
        timer.Simple(0, function()
            ply:KillSilent()
        end)
    end
end

MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        ply:SetNoCollideWithTeammates(false) -- "This will only work for teams with ID 1 to 4 due to internal Engine limitations." FUCK YUO
    end)
end

MODE.Hooks.DMU_PreRoundStart = function()
    if CLIENT then return end
    dead_players = {}

    for k,v in ipairs(DMU.Mode.Teams) do
        timer.Remove("DMU_TeamRespawnTimer" .. k)
    end

    local players = table.Copy(player.GetAll())
    table.Shuffle(players)

    for i = 1, #players, 2 do
        players[i]:SetTeam(i)

        if players[i].Objectives then
            players[i].Objectives = {}
        end

        if players[i+1] then
            players[i+1]:SetTeam(i)

            if players[i+1].Objectives then
                players[i+1].Objectives = {}
            end

            DMU.AddBotPersonalObjective(players[i+1], players[i]) -- creates a convincing enough illusion of trust between bots
            players[i].DMU_Partner = players[i+1]
            players[i+1].DMU_Partner = players[i]

            DMU.SendNotification("Your partner is " .. players[i+1]:Name() .. "!", players[i])
            DMU.SendNotification("Your partner is " .. players[i]:Name() .. "!", players[i+1])
        else
            timer.Simple(0, function()
                players[i]:SetHealth(200)
            end)
            players[i].DMU_Partner = NULL
            DMU.SendNotification("You have no partner.", players[i])
        end
    end
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end

    if IsValid(victim.DMU_Partner) then
        DMU.RemoveBotPersonalObjective(victim.DMU_Partner, victim)
    end

    if DMU.GameEnded or DMU.RoundEnded then return end

    if IsValid(victim.DMU_Partner) and victim.DMU_Partner:Alive() then
        DMU.SendNotification("You will respawn in 30 seconds.", victim)
        DMU.SendNotification("Your partner will respawn in 30 seconds!", victim.DMU_Partner)
        timer.Create("DMU_TeamRespawnTimer" .. victim:Team(), 30, 1, function()
            if !IsValid(victim) then return end
            victim:Spawn()
            DMU.AddBotPersonalObjective(victim.DMU_Partner, victim)
            if IsValid(victim.DMU_Partner) then
                DMU.SendNotification("Your partner has respawned!", victim.DMU_Partner)
            end
        end)
    else
        DMU.SendNotification("Your team has been eliminated.", victim)
        timer.Remove( "DMU_TeamRespawnTimer" .. victim:Team() )
    end

    dead_players[victim:SteamID64()] = true

    local alive_teams = {}
    local alive_team
    for _, ply in ipairs(player.GetAll()) do
        if !ply:Alive() then continue end
        alive_teams[ply:Team()] = true
        alive_team = ply:Team()
    end

    if table.Count(alive_teams) <= 1 then
        for k,v in ipairs(team.GetPlayers(alive_team)) do
            v:AddScore(1)
        end
        DMU.EndRound(alive_team)
    end
end

MODE.Hooks.PlayerSilentDeath = MODE.Hooks.PlayerDeath

MODE.Hooks.PlayerDisconnected = MODE.Hooks.PlayerDeath

local color_red = Color(255,0,0)

MODE.Hooks.PreDrawHalos = function()
    local t = LocalPlayer():Team()

    for k,v in ipairs(player.GetAll()) do
        if v != LocalPlayer() and v:Alive() then
            if v:Team() == t then
                halo.Add({v}, DMU.Mode.Teams[t].color, 2, 2, 1, true, true)
            elseif DMU.CurTimeLimit - CurTime() < 60 then
                halo.Add({v}, color_red, 2, 2, 1, true, true)
            end
        end
    end
end