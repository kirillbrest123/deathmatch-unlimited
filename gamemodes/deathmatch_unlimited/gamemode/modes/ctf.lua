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

MODE.Hooks.InitPostEntity = function()
    if CLIENT then return end
    timer.Simple(0, function()
        if !table.IsEmpty(ents.FindByClass("dmu_flag_base")) then return end

        MsgC(Color(255,0,0), "\n[DMU] There are no flag bases! Using navmesh to create some. There can be issues!")
        MsgC(Color(255,0,0), "\n[DMU] You should really add some flags using Modest Map Manipulator or Hammer instead!\n")

        local red_spawns = team.GetSpawnPoints(1)
        local blue_spawns = team.GetSpawnPoints(2)

        if table.IsEmpty(red_spawns) then
            local pos = DMU.GetRandomSpotOnNavmesh()
            if !pos then
                ErrorNoHalt("There are no flags AND no navmesh! You must either add some flags or generate a navmesh with 'nav_generate'!")
                return
            end

            local navmeshes = navmesh.Find(pos, 256, 128, 128)

            local flag = ents.Create("dmu_flag_base")
            flag:SetPos( navmeshes[math.random(#navmeshes)]:GetCenter() )
            flag:SetTeam(1)
            flag:Spawn()

            local pos = DMU.GetRandomSpotOnNavmesh()

            local navmeshes = navmesh.Find(pos, 256, 128, 128)

            local flag = ents.Create("dmu_flag_base")
            flag:SetPos( navmeshes[math.random(#navmeshes)]:GetCenter() )
            flag:SetTeam(2)
            flag:Spawn()
        else
            local navmeshes = navmesh.Find(red_spawns[1]:GetPos(), 256, 128, 128)
            if table.IsEmpty(navmeshes) then
                
                return
            end

            local flag = ents.Create("dmu_flag_base")
            flag:SetPos( navmeshes[math.random(#navmeshes)]:GetCenter() )
            flag:SetTeam(1)
            flag:Spawn()

            local navmeshes = navmesh.Find(blue_spawns[1]:GetPos(), 256, 128, 128)
            local flag = ents.Create("dmu_flag_base")
            flag:SetPos( navmeshes[math.random(#navmeshes)]:GetCenter() )
            flag:SetTeam(2)
            flag:Spawn()
        end
    end)
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