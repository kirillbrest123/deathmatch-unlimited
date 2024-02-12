MODE.Name = "Gun Game"
MODE.FriendlyFire = true
MODE.FFA = true -- mostly used in GUIs
MODE.RespawnTime = 3
MODE.TimeLimit = 600
MODE.DontDropWeapons = true 
MODE.WeaponSpawnsDisabled = true

MODE.Hooks = {}

MODE.Instructions = "Frag enemies to progress through weapon tiers.\nFirst player to score a frag with fists wins the game."

MODE.GunTiers = {
    "dmu_assault_rifle",
    "dmu_carbine",
    "dmu_smg",
    "dmu_battle_rifle",
    "dmu_plasma_rifle",
    "dmu_shotgun",
    "dmu_sniper_rifle",
    "dmu_bfb",
    "dmu_railgun",
    "dmu_rocket_launcher",
    "dmu_pistol",
    "dmu_rocket_launcher",
    "dmu_railgun",
    "dmu_bfb",
    "dmu_sniper_rifle",
    "dmu_shotgun",
    "dmu_plasma_rifle",
    "dmu_battle_rifle",
    "dmu_smg",
    "dmu_carbine",
    "dmu_assault_rifle",
    "dmu_fists",
}

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    local tier = math.Clamp(ply:GetScore() + 1, 1, 22)

    local wpn_ent = ply:Give( DMU.Mode.GunTiers[tier] )
    ply:GiveAmmo( 9999, wpn_ent:GetPrimaryAmmoType(), true )

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

    if attacker:GetScore() >= 22 then
        DMU.EndGame(attacker)
        return
    end

    local tier = math.Clamp(attacker:GetScore() + 1, 1, 22)

    timer.Simple(0, function()
        attacker:StripWeapons()
        attacker:RemoveAllAmmo()

        local wpn_ent = attacker:Give( DMU.Mode.GunTiers[ tier ] )
        attacker:GiveAmmo( 9999, wpn_ent:GetPrimaryAmmoType(), true )
        attacker:SelectWeapon( DMU.Mode.GunTiers[ tier ])
    end)
end