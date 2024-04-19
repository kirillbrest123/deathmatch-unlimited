MODE.Name = "Tag Hunt"
MODE.FriendlyFire = true
MODE.RespawnTime = 3
MODE.TimeLimit = 600
MODE.FFA = true

MODE.Hooks = {}

MODE.Instructions = "Collect dog tags to score points. Self damage from explosions disabled. Use your arsenal to your advantage."

MODE.Weapons = {
    common = {
        "dmu_grenade_launcher"
    },
    uncommon = {
        "dmu_plasma_rifle"
    },
    rare = {
        "dmu_rocket_launcher"
    },
    very_rare = {
        "dmu_rocket_launcher"
    }
}

if CLIENT then return end

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    ply:Give( "dmu_grenade_launcher" )

    return true
end

MODE.Hooks.EntityTakeDamage = function( target, dmginfo )
    if target == dmginfo:GetAttacker() then
        dmginfo:SetDamage(0)
    end
end

local next_think = 2

MODE.Hooks.Think = function()
    if CurTime() < next_think then return end
    next_think = CurTime() + 2

    local pos = DMU.GetRandomSpotOnNavmesh()
    local trace = util.QuickTrace( pos, vector_up * 256 )
    local hit_pos = trace.HitPos
    hit_pos.z = math.random( pos.z, hit_pos.z )

    local tag = ents.Create("dmu_pickup_tag")
    tag:SetPos( hit_pos )
    tag:SetTeam( TEAM_UNASSIGNED )
    tag:Spawn()
end

MODE.Hooks.DMU_TagCollected = function(tag, collector)
    if DMU.GameEnded then return end

    collector:AddScore(1)

    if team.GetScore(collector:Team()) >= 50 then
        DMU.EndGame(collector)
    end
end