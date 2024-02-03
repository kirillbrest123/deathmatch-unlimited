MODE.Name = "evolution"
MODE.PrintName = "Evolution"
MODE.FriendlyFire = false
MODE.RespawnTime = -1
MODE.TimeLimit = 180
MODE.RoundBased = true
MODE.RoundLimit = 10
MODE.WeaponSpawnsDisabled = true

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

MODE.Weapons = {
    ["common"] = {
        "dmu_pistol",
        "dmu_carbine"
    },
    ["uncommon"] = {
        "dmu_battle_rifle",
        "dmu_assault_rifle",
    },
    ["rare"] = {
        "dmu_sniper_rifle",
        "dmu_smg",
        "dmu_plasma_rifle",
    },
    ["very_rare"] = {
        "dmu_shotgun",
        "dmu_rocket_launcher",
        "dmu_railgun"
    }
}

MODE.Instructions = "Death is permament.\nYour weapons get better if you lose a round."

MODE.Hooks = {}

local dead_players = {}
local weps = {
    {
        "dmu_carbine",
        "dmu_assault_rifle"
    },
    {
        "dmu_battle_rifle",
        "dmu_smg",
    },
    {
        "dmu_shotgun",
        "dmu_sniper_rifle"
    },
    {
        "dmu_plasma_rifle",
        "dmu_shotgun"
    },
    {
        "dmu_railgun",
        "dmu_rocket_launcher",
    }
}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    local level = math.min(5, DMU.Round - team.GetScore(ply:Team()))

    for _, wep in ipairs(weps[level]) do
        ply:Give(wep)
    end

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