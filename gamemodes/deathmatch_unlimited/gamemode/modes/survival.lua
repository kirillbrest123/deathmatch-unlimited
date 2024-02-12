MODE.Name = "Survival"
MODE.FriendlyFire = false
MODE.RespawnTime = -1
MODE.TimeLimit = 300
MODE.FFA = true
MODE.FriendlyFire = true
MODE.RoundBased = true
MODE.RoundLimit = 7

local dead_players = {}

MODE.Instructions = "Death is permament.\nBe the last man standing."

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    ply:Give("dmu_fists")
    
    return true
end

MODE.Hooks.PlayerInitialSpawn = function(ply)
    if DMU.RoundEnded or DMU.GameEnded then return end
    if #player.GetAll() <= 2 then return end
    if dead_players[ply:SteamID64()] then
        timer.Simple(0, function()
            ply:KillSilent()
        end)
    end
end

MODE.Hooks.DMU_PreRoundStart = function()
    dead_players = {}
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded or DMU.RoundEnded then return end

    dead_players[victim:SteamID64()] = true

    local players_alive = 0
    local survivor
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            players_alive = players_alive + 1
            survivor = ply
        end
    end

    if players_alive <= 1 then
        if survivor then
            survivor:AddScore(1)
        end
        DMU.EndRound(survivor)
    end
end

MODE.Hooks.PlayerDisconnected = function()
    if DMU.GameEnded or DMU.RoundEnded then return end

    local players_alive = 0
    local survivor
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            players_alive = players_alive + 1
            survivor = ply
        end
    end

    if players_alive == 1 then
        survivor:AddScore(1)
        DMU.EndRound(survivor)
    end
end