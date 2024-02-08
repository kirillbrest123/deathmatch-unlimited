MODE.Name = "laser_tag"
MODE.PrintName = "Laser Tag"
MODE.FriendlyFire = false
MODE.RespawnTime = 2
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

MODE.Weapons = {
    ["common"] = {
        "dmu_plasma_rifle"
    }
}

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    ply:Give("dmu_fists")
    ply:Give("dmu_plasma_rifle")
    ply:GiveAmmo(9999, "Battery")
    return true
end

MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        ply:SetHealth(30)
        ply:ManipulateBoneScale( ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(2,2,2) ) -- make heads 2x bigger because it's hilarious
        if SERVER then
            ply:SetMaxHealth(30) -- ain't not shared
            ply:DMU_SetGravity(0.5)
        end
    end)
end

MODE.Hooks.EntityTakeDamage = function(ent, dmginfo)
    if !ent:IsPlayer() or !dmginfo:IsFallDamage() then return end
    dmginfo:SetDamage(0)
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