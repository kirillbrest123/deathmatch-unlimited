MODE.Name = "Flying Scoutsman"
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
    ["very_rare"] = {
        "dmu_sniper_rifle"
    }
}

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    ply:Give("dmu_sniper_rifle")
    ply:Give("dmu_fists")
    ply:GiveAmmo(9999, "357", true)
    return true
end

MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        ply:ManipulateBoneScale( ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(2,2,2) ) -- make heads 2x bigger because it's hilarious
        if SERVER then
            ply:DMU_SetGravity(0.3)
            ply:SetJumpPower(300)
        end
    end)
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