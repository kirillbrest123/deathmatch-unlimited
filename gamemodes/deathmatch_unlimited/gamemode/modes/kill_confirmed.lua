MODE.Name = "Kill_Confirmed"
MODE.PrintName = "Kill Confirmed"
MODE.FriendlyFire = false
MODE.RespawnTime = 3
MODE.TimeLimit = 600

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

MODE.Instructions = "Collect enemy dog tags to score points.\nCollect friendly dog tags to prevent the enemy team from scoring."

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

MODE.Hooks.PlayerDeath = function(victim)
    if CLIENT then return end

    local tag = ents.Create("dmu_pickup_tag")
    tag:SetPos(victim:GetPos() + Vector(0,0,32))
    tag:SetTeam(victim:Team())
    tag:Spawn()
end

MODE.Hooks.DMU_TagCollected = function(tag, collector)
    if CLIENT then return end
    if DMU.GameEnded then return end
    if tag:GetTeam() == collector:Team() then return end
    
    team.AddScore(collector:Team(), 1)
    collector:AddScore(1)

    if team.GetScore(collector:Team()) >= DMU.DefaultScoreLimit then
        DMU.EndGame(collector:Team())
    end
end