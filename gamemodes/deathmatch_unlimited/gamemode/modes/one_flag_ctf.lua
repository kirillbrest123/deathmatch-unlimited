MODE.Name = "One Flag CTF"
MODE.FriendlyFire = false
MODE.RespawnTime = 8
MODE.TimeLimit = 120
MODE.RoundBased = true
MODE.RoundLimit = 6
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

MODE.Instructions = "The attackers must capture the defending team's flag.\nThe defenders must protect their flag until the time runs out.\nTeams switch roles every round."

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

MODE.Hooks.DMU_PreRoundStart = function()
    if CLIENT then return end
    local attacking_team = DMU.Round % 2 + 1

    for k,v in ipairs(ents.FindByClass("dmu_flag_base")) do
        if v:GetTeam() == attacking_team then
            v:Disable()
        end
    end
end

MODE.Hooks.InitPostEntity = MODE.Hooks.DMU_PreRoundStart

MODE.Hooks.DMU_RoundStart = function()
    if CLIENT then return end
    local attacking_team = DMU.Round % 2 + 1
    for _, ply in ipairs(player.GetAll()) do
        DMU.SendAnnouncement("You are " .. (ply:Team() == attacking_team and "attacking!" or "defending!"), 2, "buttons/bell1.wav", ply)
    end
end

MODE.Hooks.DMU_FlagCaptured = function(flag, collector)
    if CLIENT then return end
    if DMU.RoundEnded then return end

    team.AddScore(collector:Team(), 1)
    collector:AddScore(1)

    DMU.EndRound(collector:Team())
end

MODE.Hooks.DMU_TimeLimitReached = function()
    local attacking_team = DMU.Round % 2 + 1
    local defending_team = attacking_team == 1 and 2 or 1

    team.AddScore(defending_team, 1)

    DMU.EndRound(defending_team)
    return true -- don't execute default behaviour (end round without winner)
end