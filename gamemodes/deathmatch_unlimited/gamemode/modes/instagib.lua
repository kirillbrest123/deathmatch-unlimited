MODE.Name = "instagib"
MODE.PrintName = "Instagib"
MODE.FriendlyFire = true
MODE.FFA = true -- mostly used in GUIs
MODE.RespawnTime = 2
MODE.TimeLimit = 600
MODE.WeaponSpawnsDisabled = true
MODE.InstantRailgun = true

MODE.Hooks = {}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in hl2dm maps

    ply:Give("dmu_railgun")
    ply:GiveAmmo(9999, "CombineCannon")
    return true
end

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