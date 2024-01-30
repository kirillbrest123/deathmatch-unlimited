MODE.Name = "Domination"
MODE.PrintName = "Domination"
MODE.FriendlyFire = false
MODE.RespawnTime = 3
MODE.TimeLimit = 600
MODE.HillsEnabled = true
MODE.ScoreLimit = 0

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

MODE.Instructions = "Capture hills to score points."

MODE.Hooks = {}

MODE.Hooks.InitPostEntity = function()
    if CLIENT then return end
    DMU.Mode.ScoreLimit = #ents.FindByClass("*dmu_hold_zone") * 200
end

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

MODE.Hooks.DMU_HoldZoneScore = function(index, t)
    if DMU.GameEnded then return end
    team.AddScore(t, 1)

    if team.GetScore(t) >= DMU.Mode.ScoreLimit then
        DMU.EndGame(t)
    end
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end

    if !victim:IsPlayer() or !attacker:IsPlayer() then return end

    if victim == attacker then
        victim:AddScore(-1)
        return
    end

    attacker:AddScore(1)
end