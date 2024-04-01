MODE.Name = "Crazy King"
MODE.FriendlyFire = false
MODE.RespawnTime = 8
MODE.TimeLimit = 600
MODE.FFA = true
MODE.HillsEnabled = true

local dead_players = {}

MODE.Instructions = "Capture the hill to score points.\nThe hill moves every minute."

MODE.Teams = {}

-- Dynamically create teams
-- NOTE: This is a hack. You should really just create/modify hill entities to work with FFA.
for i = 1, math.ceil(game.MaxPlayers()) do
    local color = HSVToColor( 360 * ( i / math.ceil( game.MaxPlayers() ) ), 1, 1 )
    local t = {
        name = "Team " .. i,
        color = Color(color.r, color.g, color.b) -- FUCK YOU
    }
    table.insert(MODE.Teams, t)
end

MODE.Hooks = {}

local team_to_player = {} -- team.GetPlayers() iterates over all players which is not efficient so we do this instead. I don't know why the scrapheads at facepunch don't do this

MODE.Hooks.PlayerInitialSpawn = function(ply)
    timer.Simple(0, function()
        DMU.AutoAssign(ply)
        team_to_player[ply:Team()] = ply
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

MODE.Hooks.DMU_HoldZoneScore = function(hill, t)
    if DMU.GameEnded then return end

    local ply = team_to_player[t]
    if !IsValid(ply) then return end

    ply:AddScore( 1 )

    if ply:GetScore() >= 120 then
        DMU.EndGame(ply)
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

local last_switched_hill = 3

MODE.Hooks.Think = function()
    if CLIENT then return end
    if !(last_switched_hill < CurTime()) then return end

    local hills = ents.FindByClass("*dmu_hold_zone")
    if table.IsEmpty(hills) then return end

    last_switched_hill = CurTime() + 60

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