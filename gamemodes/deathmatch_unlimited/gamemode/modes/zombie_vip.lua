MODE.Name = "zombie_vip"
MODE.PrintName = "Zombie Vip"
MODE.FriendlyFire = false
MODE.RespawnTime = 4
MODE.TimeLimit = 600
MODE.WeaponSpawnsDisabled = true
MODE.DontDropWeapons = true

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

MODE.Instructions = "Kill enemy's VIP to score points."

MODE.Weapons = { -- even though weapon spawns are disabled, bots use this to figure out what weapon to use
    ["common"] = {
        "dmu_carbine",
    },
    ["very_rare"] = {
        "dmu_bfb",
        "dmu_shotgun"
    }
}

MODE.Hooks = {}

MODE.OldVips = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    if ply == GetGlobalEntity("DMU_CurrentVip" .. ply:Team()) then
        ply:Give("dmu_shotgun")
        ply:Give("dmu_carbine")
    else
        ply:Give("dmu_bfb")
        ply:GiveAmmo(9999, "Thumper")
    end

    return true
end

MODE.Hooks.PlayerSpawn = function(ply)
    if CLIENT then return end
    local ply_team = ply:Team()

    timer.Simple(0, function()
        ply:SetHealth(50)
        if SERVER then
            ply:SetMaxHealth(50) -- ain't not shared
        end
    end)

    if IsValid(GetGlobalEntity("DMU_CurrentVip" .. ply_team)) or (ply == DMU.Mode.OldVips[ply_team] and team.NumPlayers(ply_team >= 2)) then return end

    SetGlobalEntity("DMU_CurrentVip" .. ply:Team(), ply)

    local att_team = ply_team == 1 and 2 or 1
    DMU.BotTeamObjectives[ att_team ] = { GetGlobalEntity("DMU_CurrentVip" .. ply_team) }

    DMU.Mode.OldVips[ ply:Team() ] = ply
    DMU.SendAnnouncement("You are VIP!", 1, "buttons/bell1.wav", ply)
    
    DMU.SendNotification("New VIP!")
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded then return end

    if victim != GetGlobalEntity("DMU_CurrentVip" .. victim:Team()) then return end

    SetGlobalEntity("DMU_CurrentVip" .. victim:Team(), NULL)

    local att_team = victim:Team() == 1 and 2 or 1

    DMU.BotTeamObjectives[ att_team ] = {}

    for k,v in ipairs(player.GetAll()) do
        if v:Team() == att_team then
            DMU.SendNotification("VIP Killed!", v)
        else
            DMU.SendNotification("VIP Lost!", v)
        end
    end

    team.AddScore(att_team, 1)

    if IsValid(attacker) and attacker:IsPlayer() and attacker != victim then
        attacker:AddScore(1)
    end

    if team.GetScore(att_team) >= DMU.DefaultScoreLimit/2 then
        DMU.EndGame(att_team)
    end
end

MODE.Hooks.PlayerSilentDeath = MODE.Hooks.PlayerDeath

--local color_gold = Color(255,200,0)

MODE.Hooks.PreDrawHalos = function()
    halo.Add({GetGlobalEntity("DMU_CurrentVip1")}, DMU.Mode.Teams[1].color, 2, 2, 1, true, true)
    halo.Add({GetGlobalEntity("DMU_CurrentVip2")}, DMU.Mode.Teams[2].color, 2, 2, 1, true, true)
end