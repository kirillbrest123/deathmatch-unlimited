DMU.Modes = DMU.Modes or {}

local prefix = "deathmatch_unlimited/gamemode/modes/"

local function create_teams(teams)
    
    for k, v in ipairs(teams) do
        team.SetUp(k, v.name, v.color, true)
        if SERVER then
            DMU.BotTeamObjectives[k] = {}
        end
    end

    team.SetSpawnPoint(1, {"info_player_rebel", "info_player_terrorist"})
    team.SetSpawnPoint(2, {"info_player_combine", "info_player_counterterrorist"})
end

local function load_modes()
    for _,f in ipairs(file.Find(prefix .. "*", "LUA")) do
        MODE = {}
        AddCSLuaFile(prefix .. f)
        include(prefix .. f)

        MODE.Name = MODE.Name or string.Explode(".", f)[1]

        DMU.Modes[string.lower(MODE.Name)] = MODE
    end
    MODE = nil
end

local function load_mode(name)
    name = string.lower(name)
    DMU.Mode = DMU.Modes[name] or DMU.Modes["team deathmatch"]

    for k,v in pairs(DMU.Mode.Hooks or {}) do
        hook.Add(k, "dmu_mode_" .. name, v)
    end

    if DMU.Mode.Teams then
        create_teams(DMU.Mode.Teams)
    end

    DMU.Weapons = {}

    DMU.Weapons.starter = string.Split(GetConVar("dmu_server_weapons_starter"):GetString(), ",")
    DMU.Weapons.common = string.Split(GetConVar("dmu_server_weapons_common"):GetString(), ",")
    DMU.Weapons.uncommon = string.Split(GetConVar("dmu_server_weapons_uncommon"):GetString(), ",")
    DMU.Weapons.rare = string.Split(GetConVar("dmu_server_weapons_rare"):GetString(), ",")
    DMU.Weapons.very_rare = string.Split(GetConVar("dmu_server_weapons_very_rare"):GetString(), ",")

    if DMU.Mode.Weapons then
        for rarity, sweps in pairs(DMU.Mode.Weapons) do
            DMU.Weapons[rarity] = sweps
        end
    end

    -- string.Split() still returns a table with an empty string if the string is empty
    -- we only do this for the starter weapons because it's just useless for everything else
    if DMU.Weapons.starter[1] == "" then
        DMU.Weapons.starter = {}
    end

    DMU.weapon_to_rarity = {}

    for rarity, sweps in pairs(DMU.Weapons) do
        for k, swep in ipairs(sweps) do
            DMU.weapon_to_rarity[swep] = rarity
        end
    end

    if DMU.Mode.RoundBased then
        DMU.Round = 1 -- DMU.StartNextRound() never gets called initially, so it may cause problems later?
    end

    if DMU.Mode.TimeLimit then
        DMU.CurTimeLimit = DMU.Mode.TimeLimit

        if SERVER then
            if DMU.Mode.RoundBased then
                hook.Add("Think", "DMU_TimeLimit", function()
                    if CurTime() >= DMU.CurTimeLimit and !DMU.GameEnded and !DMU.RoundEnded then
                        DMU.EndRound()
                    end
                end)
            else
                hook.Add("Think", "DMU_TimeLimit", function()
                    if CurTime() >= DMU.CurTimeLimit and !DMU.GameEnded then
                        DMU.EndGame()
                    end
                end)
            end
        end
    end
end

load_modes()
local mode_convar = GetConVar("dmu_server_mode")
if not IsValid(mode_convar) then
    mode_convar = CreateConVar( "dmu_server_mode", "Team Deathmatch", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Game Mode. If you're unsure, enter Team Deathmatch or FFA Deathmatch.") -- failsafe in case client doesn't receive deathmatch_unlimited.txt
end
load_mode( string.lower( GetConVar("dmu_server_mode"):GetString() ) )