MODE.Name = "One in the Chamber"
MODE.FriendlyFire = true
MODE.FFA = true -- mostly used in GUIs
MODE.RespawnTime = 3
MODE.TimeLimit = 600
MODE.WeaponSpawnsDisabled = true
MODE.DontDropWeapons = true

MODE.Hooks = {}

MODE.Weapons = {
    ["common"] = {
        "dmu_fists"
    },
    ["uncommon"] = {
        "dmu_carbine"
    }
}

MODE.Instructions = "You have only 1 bullet.\nGet more by fragging enemies."

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    local wpn = ply:Give("dmu_carbine", true)
    ply:Give("dmu_fists")

    wpn:SetClip1(1)

    return true
end

MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        ply:SetHealth(5)
        if SERVER then
            ply:SetMaxHealth(5) -- ain't not shared
        end
    end)
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

    local wpn = attacker:GetWeapon("dmu_carbine")
    wpn:SetClip1(wpn:Clip1() + 1)

    if attacker:GetScore() >= DMU.DefaultScoreLimit/2 then
        DMU.EndGame(attacker)
    end
end