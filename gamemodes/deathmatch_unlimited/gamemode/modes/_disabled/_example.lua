MODE.Name = "Example" -- name of the game mode
MODE.PrintName = "Example" -- not required. If defined, will visually replace MODE.Name. Ideally this should be just MODE.PrintName but with \n or a translation string

MODE.FriendlyFire = false -- whether players from the same team should be able to damage each other. This includes TEAM_UNASSIGNED, so it should be true in FFA modes, unless you do team stuff.
MODE.RespawnTime = 3 -- respawn time in seconds. Negative values will disable automatic respawn, i.e permadeath. You will have to respawn players manually
MODE.FFA = false -- will disable most default team things and change GUI to FFA version. Also used to figure out whether a team or a player should be a victor when the time limit is reached.

MODE.TimeLimit = 600 -- time limit in seconds

MODE.RoundBased = false
MODE.RoundLimit = 10 -- must be set if MODE.RoundBased = true

MODE.WeaponSpawnsDisabled = false
MODE.DontDropWeapons = false

MODE.HillsEnabled = false -- if this is set to false, trigger_dmu_hold_zone and dmu_hold_zone will be removed instantly upon spawning
MODE.FlagsEnabled = false

MODE.UseTeamSpawns = false -- if this is set to true, players will spawn on their respective team's hl2dm spawnpoints (info_spawn_rebel, info_spawn_combine). Only supports 2 teams.

MODE.Teams = { -- FFA modes can have teams too, but you will have to manually assign players to them
    {
        name = "Rebels",
        color = Color(255,0,0),
        banner = "game_mode_banners/team_objective.png" -- add this if you wish to overwrite default team banner
    },
    {
        name = "Combine",
        color = Color(0,0,255)
    },
    {
        name = "HECU",
        color = Color(0,255,0)
    },
    {
        name = "Xen",
        color = Color(255,255,0)
    },
}

MODE.Weapons = { -- overwrites weapons set by convars. Also used by bots to figure out the best weapon to use
    common = {
        "dmu_pistol",
        "dmu_carbine"
    },
    uncommon = {
        "dmu_assault_rifle",
        "dmu_battle_rifle"
    },
    rare = {
        "dmu_plasma_rifle",
        "dmu_smg",
        "dmu_sniper_rifle"
    },
    very_rare = {
        "dmu_bfb",
        "dmu_shotgun",
        "dmu_rocket_launcher",
        "dmu_railgun"
    }
    -- special = { } -- special weapons don't spawn, but bots will prefer them over anything else
}


MODE.Instructions = "Kill to score points\nAvoid dying" -- instruction that will be displayed when a player joins

MODE.Hooks = {} -- list of hooks that will be created on load (shared)


/*
Below are various code bits. You can copy & paste the ones you need.
Don't use the same hook twice or it will be overwrited, try to merge instead.
*/


-- Give weapons defined in dmu_server_weapons_starter
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


-- Give your own weapons
MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    ply:Give("dmu_sniper_rifle")
    ply:Give("dmu_pistol")
    return true
end


-- Give 1 point for every kill and end the game when DMU.DefaultScoreLimit is reached. For non-FFA game modes
MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded then return end

    if victim == attacker then
        team.AddScore(victim:Team(), -1)
        victim:AddScore(-1)
        return
    end

    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local att_team = attacker:Team()

    team.AddScore(att_team, 1)
    attacker:AddScore(1)

    if team.GetScore(att_team) >= DMU.DefaultScoreLimit then
        DMU.EndGame(att_team)
    end
end


-- Give 1 point for every kill and end the game when DMU.DefaultScoreLimit/2 is reached. For FFA game modes
MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded then return end

    if !victim:IsPlayer() or !attacker:IsPlayer() then return end

    if victim == attacker then
        victim:AddScore(-1)
        return
    end

    attacker:AddScore(1)

    if attacker:GetScore() >= DMU.DefaultScoreLimit/2 then
        DMU.EndGame(attacker)
    end
end


-- Headshots kill instantly
MODE.Hooks.EntityTakeDamage = function(ent, dmginfo)
    if ent:IsPlayer() and ent:LastHitGroup() == HITGROUP_HEAD then
        dmginfo:SetDamage(1000)
    end 
end


-- Players spawn with 30 HP
MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        ply:SetHealth(30)
        if SERVER then
            ply:SetMaxHealth(30)
        end
    end)
end


-- Players experience gravity at 50% strength
MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        if SERVER then
            ply:DMU_SetGravity(0.5) -- unlike ply:SetGravity(), this one is properly predicted, so use this one instead
        end
    end)
end

-- Make heads 2x bigger because it's hilarious
MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        ply:ManipulateBoneScale( ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(2,2,2) )
    end)
end


-- Scoring for game modes with hills
MODE.Hooks.DMU_HoldZoneScore = function(hill, t)
    if DMU.GameEnded then return end
    team.AddScore(t, 1)

    if team.GetScore(t) >= 200 then
        DMU.EndGame(t)
    end
end


-- End the game early if a team has won the majority of the rounds
MODE.Hooks.DMU_ShouldStartRound = function(round)
    local halfway = math.floor(DMU.Mode.RoundLimit / 2)
    if round == halfway + 1 and ( team.GetScore(1) >= halfway or team.GetScore(2) >= halfway ) then
        DMU.EndGame( team.GetScore(1) > team.GetScore(2) and 1 or 2 )
        return false
    end
end