MODE.Name = "Team Fiesta"
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

MODE.Instructions = "You spawn with random weapons."

MODE.Hooks = {}

local available_weapons = {}

MODE.Hooks.InitPostEntity = function()
    for k,v in pairs(DMU.weapon_to_rarity) do
        if v == "starter" then continue end
        table.insert(available_weapons, k)
    end
end

MODE.Hooks.PlayerLoadout = function(ply)
    if CLIENT then return end

    ply:StripWeapons() -- strip the loadout given by game_player_equip, which is present in some hl2dm maps

    local wpns = table.Copy(available_weapons)

    for i = 1, 2 do
        local wpn = wpns[math.random(#wpns)]
        table.RemoveByValue(wpns, wpn)

        local wpn_ent = ply:Give(wpn)
        if !wpn_ent.Primary or !wpn_ent.Primary.DefaultClip then
            ply:GiveAmmo(wpn_ent:GetMaxClip1() * 2 or 2, wpn_ent:GetPrimaryAmmoType())
        end
    end
    return true
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded then return end

    if victim == attacker then
        team.AddScore(victim:Team(), -1)
        victim:AddScore(-1)
        return
    end

    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local att_team = attacker:Team()

    team.AddScore(att_team, 1)
    attacker:AddScore(1)

    if team.GetScore(att_team) >= DMU.DefaultScoreLimit then
        DMU.EndGame(att_team)
    end
end