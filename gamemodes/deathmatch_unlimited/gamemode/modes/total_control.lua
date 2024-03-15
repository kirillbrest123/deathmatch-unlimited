MODE.Name = "Total Control"
MODE.FriendlyFire = false
MODE.RespawnTime = 6
MODE.TimeLimit = 300
MODE.HillsEnabled = true
MODE.RoundBased = true
MODE.RoundLimit = 3

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

MODE.Instructions = "Control all hills for 30 seconds total to win."

MODE.Hooks = {}

if SERVER then

local num_of_hills = 0

MODE.Hooks.InitPostEntity = function()
    timer.Simple(0, function() -- navmesh is not loaded on initpostentity for some reason
        num_of_hills = #ents.FindByClass("*dmu_hold_zone")

        if num_of_hills != 0 then return end
    
        MsgC(Color(255,0,0), "\n[DMU] There are no hills! Using navmesh to create some. There can be issues!")
        MsgC(Color(255,0,0), "\n[DMU] You should really add some hills using Modest Map Manipulator or Hammer instead!\n")

        for i = 0, 2 do
            local pos = DMU.GetRandomSpotOnNavmesh()
            if pos == nil then
                ErrorNoHalt("There are no hills AND no navmesh! You must either add some hills or generate a navmesh with 'nav_generate'!")
                return
            end
            local hill = ents.Create("dmu_hold_zone")
            hill:SetPos(pos + Vector(0,0,48))
            hill:SetIdentifier(i)
            hill:Spawn()
        end

        num_of_hills = 3
    end)
end

MODE.Hooks.PlayerLoadout = function(ply)
    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    for _, weapon in ipairs(DMU.Weapons.starter) do
        local wpn_ent = ply:Give(weapon)
        if !wpn_ent.Primary or !wpn_ent.Primary.DefaultClip then
            ply:GiveAmmo(wpn_ent:GetMaxClip1() * 2 or 2, wpn_ent:GetPrimaryAmmoType())
        end
    end
    return true
end

local hills_under_control = {
    0,
    0,
}

local scores = {
    0,
    0
}

MODE.Hooks.DMU_HoldZoneCaptured = function(hill, capturing_team, current_team, old_team)
    if DMU.RoundEnded then return end

    if old_team != -1 then
        if hills_under_control[old_team] >= num_of_hills then
            DMU.SendNotification(DMU.Mode.Teams[old_team].name .. " no longer has total control.")
        end

        hills_under_control[old_team] = hills_under_control[old_team] - 1
    end

    if current_team != -1 then
        hills_under_control[current_team] = hills_under_control[current_team] + 1

        if hills_under_control[current_team] >= num_of_hills then
            DMU.SendNotification(DMU.Mode.Teams[current_team].name .. " has total control!")
        end
    end
end

local next_think = 3

MODE.Hooks.Think = function()
    if CurTime() < next_think then return end

    if hills_under_control[1] >= num_of_hills then
        scores[1] = scores[1] + 1
    elseif hills_under_control[2] >= num_of_hills then
        scores[2] = scores[2] + 1
    end

    if scores[1] == 10 and hills_under_control[1] >= num_of_hills then
        DMU.SendNotification(DMU.Mode.Teams[1].name .. " is 20 seconds away from victory!")
    elseif scores[1] == 20 and hills_under_control[1] >= num_of_hills then
        DMU.SendNotification(DMU.Mode.Teams[1].name .. " is 10 seconds away from victory!")
    elseif scores[1] >= 30 then
        team.AddScore(1, 1)
        DMU.EndRound(1)
    elseif scores[2] == 10 and hills_under_control[2] >= num_of_hills then
        DMU.SendNotification(DMU.Mode.Teams[2].name .. " is 20 seconds away from victory!")
    elseif scores[2] == 20 and hills_under_control[2] >= num_of_hills then
        DMU.SendNotification(DMU.Mode.Teams[2].name .. " is 10 seconds away from victory!")
    elseif scores[2] >= 30 then
        team.AddScore(2, 1)
        DMU.EndRound(2)
    end

    next_think = CurTime() + 1
end

MODE.Hooks.DMU_TimeLimitReached = function()
    local winner = (scores[1] > scores[2]) and 1 or 2
    team.AddScore(winner, 1)
    DMU.EndRound(winner)
    return true
end

MODE.Hooks.DMU_PreRoundStart = function()
    hills_under_control = {0,0}
    scores = {0,0}

    timer.Simple(1, DMU.Mode.Hooks.InitPostEntity)
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if !victim:IsPlayer() or !attacker:IsPlayer() then return end

    if victim == attacker then
        victim:AddScore(-1)
        return
    end

    attacker:AddScore(1)
end

end