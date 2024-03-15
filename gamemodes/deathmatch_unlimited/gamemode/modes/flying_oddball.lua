MODE.Name = "Flying Oddball"
MODE.FriendlyFire = false
MODE.RespawnTime = 3
MODE.TimeLimit = 600
MODE.WeaponSpawnsDisabled = true

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

MODE.Instructions = "Hold the Oddball to score points."

MODE.Hooks = {}

local oddball_spawns = {}

local function spawn_oddball()
    local pos = DMU.GetRandomSpotOnNavmesh()
    if !pos then
        ErrorNoHalt("This game mode requires a navmesh! Generate a navmesh with 'nav_generate'!")
        return
    end
    local oddball = ents.Create("dmu_oddball")
    oddball:SetPos( pos )
    oddball:Spawn()
end

MODE.Hooks.InitPostEntity = function()
    if CLIENT then return end
    timer.Simple(0, spawn_oddball)
end

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    ply:Give("dmu_bfb")
    ply:GiveAmmo(9999, "Thumper")

    return true
end

MODE.Hooks.PlayerSpawn = function(ply)
    timer.Simple(0, function()
        if SERVER then
            ply:DMU_SetGravity(0.5)
        end
        ply:SetWalkSpeed(300)
        ply:SetRunSpeed(600)
        ply:SetJumpPower(300)
    end)
end

MODE.Hooks.DMU_OddballScore = function(oddball, owner)
    if DMU.GameEnded then return end
    local t = owner:Team()
    team.AddScore(t, 1)
    owner:AddScore(1)

    if team.GetScore(t) >= 300 then
        DMU.EndGame(t)
    end
end

MODE.Hooks.DMU_OddballRemoved = function(oddball)
    -- i have no idea why but it creates a fucking infinite loop when shutting down the server
    -- so we do it in a timer
    timer.Simple(1, function()
        DMU.SendNotification("Oddball respawned!")
        spawn_oddball()
    end)
end