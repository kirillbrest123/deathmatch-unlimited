MODE.Name = "Takedown"
MODE.FriendlyFire = false
MODE.RespawnTime = -1
MODE.TimeLimit = 300
MODE.RoundBased = true
MODE.RoundLimit = 7
MODE.RespawnTimes = {
    [1] = 3,
    [2] = 3,
}

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

MODE.Instructions =
    "Every time you or your teammate dies the respawn times increase.\nIf everyone from your team is dead simultaneously, you lose the round."

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

MODE.Hooks.DMU_PreRoundStart = function()
    DMU.Mode.RespawnTimes = {
        [1] = 3,
        [2] = 3,
    }

    for k,v in ipairs(player.GetAll()) do
        timer.Remove(v:Name().. "respawn_timer")
    end
end

MODE.Hooks.PlayerChangedTeam = function(ply, oldteam, newteam)
    if oldteam == TEAM_UNASSIGNED or newteam == TEAM_UNASSIGNED or oldteam == newteam then return end
    DMU.SendNotification("You will respawn in " .. DMU.Mode.RespawnTimes[newteam] .. " seconds.", ply)
    timer.Create(ply:Name() .. "respawn_timer", DMU.Mode.RespawnTimes[newteam], 1, function()
        if !IsValid(ply) then return end
        ply:Spawn()
    end)
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded or DMU.RoundEnded then return end

    DMU.Mode.RespawnTimes[victim:Team()] = DMU.Mode.RespawnTimes[victim:Team()] + 4
    DMU.SendNotification("You will respawn in " .. DMU.Mode.RespawnTimes[victim:Team()] .. " seconds.", victim)

    timer.Create(victim:Name() .. "respawn_timer", DMU.Mode.RespawnTimes[victim:Team()], 1, function()
        if !IsValid(victim) then return end
        victim:Spawn()
    end)

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