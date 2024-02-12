MODE.Name = "Shotty Snipers"
MODE.FriendlyFire = false
MODE.RespawnTime = 3
MODE.TimeLimit = 600
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
MODE.Weapons = { -- even though weapon spawns are disabled, bots use this to figure out what weapon to use
    ["common"] = {
        "dmu_sniper_rifle",
    },
    ["very_rare"] = {
        "dmu_shotgun"
    }
}

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    ply:Give("dmu_sniper_rifle")
    ply:Give("dmu_shotgun")
    ply:Give("dmu_fists")
    ply:GiveAmmo(8, "357", true)
    return true
end

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