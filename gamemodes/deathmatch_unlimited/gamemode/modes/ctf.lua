MODE.Name = "CTF"
MODE.FriendlyFire = false
MODE.RespawnTime = 8
MODE.TimeLimit = 600
MODE.UseTeamSpawns = true
MODE.FlagsEnabled = true

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

MODE.Weapons = {
    special = {"dmu_flag"}
}

MODE.Instructions = "Steal the enemy flag and bring it back to your base to score points."

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

MODE.Hooks.DMU_FlagCaptured = function(flag, collector)
    if CLIENT then return end
    if DMU.GameEnded then return end

    team.AddScore(collector:Team(), 1)
    collector:AddScore(1)
    DMU.SendNotification(DMU.Mode.Teams[collector:Team()].name .. " have captured " .. DMU.Mode.Teams[flag:GetTeam()].name .. " flag!")

    if team.GetScore(collector:Team()) >= DMU.DefaultScoreLimit/4 then
        DMU.EndGame(collector:Team())
    end
end