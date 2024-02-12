MODE.Name = "SWAT"
MODE.FriendlyFire = false
MODE.RespawnTime = 3
MODE.TimeLimit = 600

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

MODE.Instructions = "Headshots kill instantly."

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    ply:Give("dmu_battle_rifle")
    ply:Give("dmu_carbine")
    ply:Give("dmu_fists")
    return true
end

MODE.Hooks.EntityTakeDamage = function(ent, dmginfo)
    if ent:IsPlayer() and ent:LastHitGroup() == HITGROUP_HEAD then
        dmginfo:SetDamage(1000)
    end 
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