MODE.Name = "FFA Deathmatch"
MODE.FriendlyFire = true
MODE.FFA = true -- mostly used in GUIs
MODE.RespawnTime = 3
MODE.TimeLimit = 600

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