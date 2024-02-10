MODE.Name = "contamination"
MODE.PrintName = "Contamination"
MODE.FFA = true
MODE.RoundBased = true
MODE.RoundLimit = 5
MODE.FriendlyFire = false
MODE.RespawnTime = 4
MODE.TimeLimit = 180
MODE.WeaponSpawnsDisabled = true
MODE.DontDropWeapons = true

MODE.Teams = {
    {
        ["name"] = "Survivors",
        ["color"] = Color(255,0,0)
    },
    {
        ["name"] = "Infected",
        ["color"] = Color(0,200,0)
    }
}

MODE.Instructions = "There's 1 infected.\nWhen you die, you get infected.\nRound ends after all survivors got infected.\nPlayer with most frags at the end of the match wins."

MODE.Weapons = { -- even though weapon spawns are disabled, bots use this to figure out what weapon to use
    ["common"] = {
        "dmu_assault_rifle",
    },
    ["very_rare"] = {
        "dmu_bfb",
        "dmu_shotgun"
    }
}

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    if ply:Team() == 1 then
        ply:Give("dmu_shotgun")
        ply:Give("dmu_assault_rifle")
        ply:Give("dmu_fists")
        ply:GiveAmmo(9999, "AR2")
    else
        ply:Give("dmu_bfb")
        ply:GiveAmmo(9999, "Thumper")
    end

    return true
end

MODE.Hooks.PlayerSpawn = function(ply)
    if CLIENT then return end

    if ply:Team() == TEAM_UNASSIGNED then
        ply:SetTeam(1)
    end

    if #team.GetPlayers(2) == 0 then
        ply:SetTeam(2)
        DMU.SendNotification("You are infected!", ply)
    end

    if ply:Team() == 2 then
        timer.Simple(0, function()
            ply:SetHealth(50)
            if SERVER then
                ply:SetMaxHealth(50) -- ain't not shared
            end
        end)
    end
end

MODE.Hooks.DMU_PreRoundStart = function()
    local plys = player.GetAll()

    for _, ply in ipairs(plys) do
        ply:SetTeam(1)
    end

    local ply = plys[math.random(#plys)]
    ply:SetTeam(2)
    DMU.SendNotification("You are infected!", ply)
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded then return end

    if victim:Team() == 1 then
        victim:SetTeam(2)
        DMU.SendNotification("You got infected!", victim)
    end

    if IsValid(attacker) and attacker:IsPlayer() and attacker != victim then
        attacker:AddScore(1)
    end

    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() then return end
    end

    DMU.EndRound()
end

MODE.Hooks.PlayerSilentDeath = MODE.Hooks.PlayerDeath