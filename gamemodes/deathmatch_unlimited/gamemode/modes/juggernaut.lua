MODE.Name = "juggernaut"
MODE.PrintName = "Juggernaut"
MODE.FriendlyFire = false
MODE.FFA = true -- mostly used in GUIs
MODE.RespawnTime = 3
MODE.TimeLimit = 600

MODE.Teams = {
    {
        ["name"] = "Non-Juggernaut",
        ["color"] = Color(127,127,127)
    },
    {
        ["name"] = "Juggernaut",
        ["color"] = Color(255,100,0)
    }
}

MODE.Instructions = "You get points for being the Juggernaut.\nFrag the current Juggernaut to become the new Juggernaut.\nJuggernaut has more health, moves faster and heals on kills."

local function set_juggernaut(ply)
    local juggernaut = GetGlobalEntity("DMU_CurrentJuggernaut")

    if IsValid(juggernaut) then
        juggernaut:SetMaxHealth(100)
        juggernaut:SetWalkSpeed( ply:GetWalkSpeed() / 1.25 )
        juggernaut:SetRunSpeed( ply:GetRunSpeed() / 1.25 )
        juggernaut:SetTeam(1)
    end 

    SetGlobalEntity("DMU_CurrentJuggernaut", ply)

    DMU.BotTeamObjectives[1] = {GetGlobalEntity("DMU_CurrentJuggernaut")}

    local new_health = ply:GetMaxHealth() + 20 * player.GetCount()
    ply:SetMaxHealth(new_health)
    ply:SetHealth(new_health)
    ply:SetWalkSpeed( ply:GetWalkSpeed() * 1.25 )
    ply:SetRunSpeed( ply:GetRunSpeed() * 1.25 )
    ply:SetTeam(2)

    ply:SetPlayerColor( DMU.Mode.Teams[2].color:ToVector() )

    DMU.SendNotification("New Juggernaut!")
    DMU.SendAnnouncement("You are the new Juggernaut!", 1, "buttons/bell1.wav", ply)
end

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

MODE.Hooks.PlayerInitialSpawn = function(ply)
    timer.Simple(0, function()
        ply:SetTeam(1)
    end)
end

MODE.Hooks.PlayerDeath = function(victim, inflictor, attacker)
    if CLIENT then return end
    if DMU.GameEnded then return end
    if victim != GetGlobalEntity("DMU_CurrentJuggernaut") then
        if attacker == GetGlobalEntity("DMU_CurrentJuggernaut") then
            attacker:SetHealth( math.min( attacker:GetMaxHealth(), attacker:Health() + 15 ) )
        end
        return
    end

    if !attacker:IsPlayer() or attacker == victim then
        local players = player.GetAll()
        local new_juggernaut = players[math.random(#players)]
        set_juggernaut(new_juggernaut)
        return
    end

    set_juggernaut(attacker)
end

MODE.Hooks.PlayerSilentDeath = MODE.Hooks.PlayerDeath

local next_think = 0

MODE.Hooks.Think = function()
    if CLIENT then return end
    if next_think > CurTime() or #player.GetAll() <= 0 or DMU.GameEnded then return end

    next_think = CurTime() + 1

    local juggernaut = GetGlobalEntity("DMU_CurrentJuggernaut")

    if !IsValid(juggernaut) or juggernaut:Team() != 2 then
        local players = player.GetAll()
        local new_juggernaut = players[math.random(#players)]
        set_juggernaut(new_juggernaut)
        return
    end

    juggernaut:AddScore(1)

    if juggernaut:GetScore() >= 200 then
        DMU.EndGame(juggernaut)
    end
end

MODE.Hooks.PreDrawHalos = function()
    halo.Add({GetGlobalEntity("DMU_CurrentJuggernaut")}, DMU.Mode.Teams[2].color, 2, 2, 1, true, true)
end