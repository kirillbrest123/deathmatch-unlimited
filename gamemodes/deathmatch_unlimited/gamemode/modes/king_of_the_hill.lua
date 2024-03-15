MODE.Name = "King Of The Hill"
MODE.FriendlyFire = false
MODE.RespawnTime = 3
MODE.TimeLimit = 600
MODE.HillsEnabled = true
MODE.LastSwitchedHill = 0

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

MODE.Instructions = "Capture the hill to score points.\nThe hill moves every minute."

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

MODE.Hooks.DMU_HoldZoneScore = function(hill, t)
    if DMU.GameEnded then return end
    team.AddScore(t, 1)

    if team.GetScore(t) >= 200 then
        DMU.EndGame(t)
    end
end

MODE.Hooks.InitPostEntity = function()
    if CLIENT then return end

    timer.Simple(0, function() -- navmesh is not loaded on initpostentity for some reason
        local hills = ents.FindByClass("*dmu_hold_zone")

        if table.IsEmpty(hills) then
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
        end

        for k,v in ipairs(ents.FindByClass("*dmu_hold_zone")) do
            v:Disable()
        end
    end)

end

MODE.Hooks.Think = function()
    if CLIENT then return end
    if !(DMU.Mode.LastSwitchedHill < CurTime()) then return end

    local hills = ents.FindByClass("*dmu_hold_zone")
    if table.IsEmpty(hills) then return end

    DMU.Mode.LastSwitchedHill = CurTime() + 60

    DMU.SendNotification("Hill moved!")

    for k,v in ipairs(hills) do
        v:Disable()
        if v == DMU.Mode.CurrentHill then table.remove(hills, k) end
    end

    DMU.Mode.CurrentHill = hills[math.random(#hills)] or DMU.Mode.CurrentHill
    DMU.Mode.CurrentHill:Enable()

    timer.Simple(50, function()
        DMU.SendNotification("Hill will move in 10 seconds.")
    end)
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