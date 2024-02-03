MODE.Name = "Showdown"
MODE.PrintName = "Showdown"
MODE.FriendlyFire = false
MODE.RespawnTime = -1
MODE.TimeLimit = 180
MODE.RoundBased = true
MODE.RoundLimit = 7

MODE.Teams = {
    {
        ["name"] = "Red",
        ["color"] = Color(255,0,0)
    },
    {
        ["name"] = "Blue",
        ["color"] = Color(0,0,255)
    }
}

MODE.Instructions = "Death is permament.\nEliminate the enemy team to win the round."

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    for _, weapon in ipairs(DMU.Weapons.starter) do
        local wpn_ent = ply:Give(weapon)
        if !wpn_ent.Primary or !wpn_ent.Primary.DefaultClip then
            ply:GiveAmmo(wpn_ent:GetMaxClip1() * 2 or 2, wpn_ent:GetPrimaryAmmoType())
        end
    end
    return true
end

local dead_players = {}

MODE.Hooks.PlayerSpawn = function(ply) -- kill dead players that disconnected from spawning
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

    if victim == attacker then
        victim:AddScore(-2)
    end

    if attacker and attacker:IsPlayer() then
        attacker:AddScore(1)
    end

    local players = team.GetPlayers(victim:Team())
    for _, ply in ipairs(players) do
        if ply:Alive() then return end
    end

    local attacker_team = victim:Team() == 1 and 2 or 1

    team.AddScore(attacker_team, 1)
    DMU.EndRound(attacker_team)
end

MODE.Hooks.PlayerDisconnected = function(victim)
    if victim:Team() == TEAM_UNASSIGNED then return end
    if DMU.GameEnded or DMU.RoundEnded then return end
    
    local players = team.GetPlayers(victim:Team())
    for _, ply in ipairs(players) do
        if ply:Alive() then return end
    end

    local attacker_team = victim:Team() == 1 and 2 or 1

    team.AddScore(attacker_team, 1)
    DMU.EndRound(attacker_team)
end