MODE.Name = "hot_rockets"
MODE.PrintName = "Hot Rockets"
MODE.FriendlyFire = false
MODE.RespawnTime = 2
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

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    ply:Give("dmu_rocket_launcher")
    ply:GiveAmmo(9999, "RPG_Round")

    return true
end

MODE.Hooks.EntityTakeDamage = function(ply, dmginfo)
    dmginfo:ScaleDamage(3)
    if ply:IsPlayer() and ply == dmginfo:GetAttacker() then
        dmginfo:SetDamage(0)
        return true
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

    if team.GetScore(att_team) >= DMU.DefaultScoreLimit * 1.25 then
        DMU.EndGame(att_team)
    end
end