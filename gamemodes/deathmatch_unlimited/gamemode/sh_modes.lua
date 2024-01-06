DMU.Modes = DMU.Modes or {}

local prefix = "deathmatch_unlimited/gamemode/modes/"

local function create_teams(teams)
    for k, v in ipairs(teams) do
        team.SetUp(k, v.name, v.color, true)
        if SERVER then
            DMU.BotTeamObjectives[k] = {}
        end
    end
end

local function load_modes()
    for _,f in ipairs(file.Find(prefix .. "*", "LUA")) do
        MODE = {}
        AddCSLuaFile(prefix .. f)
        include(prefix .. f)

        MODE.Name = string.lower(MODE.Name or string.Explode(".", f)[1])

        DMU.Modes[MODE.Name] = MODE
    end
    MODE = nil
end

local function load_mode(name)
    name = string.lower(name)
    name = string.Replace(name, " ", "_")
    DMU.Mode = DMU.Modes[name] or DMU.Modes["tdm"]

    for k,v in pairs(DMU.Mode.Hooks or {}) do
        hook.Add(k, "dmu_mode_" .. name, v)
    end

    if DMU.Mode.Teams then
        create_teams(DMU.Mode.Teams)
    end

    DMU.Weapons = {}

    if DMU.Mode.Weapons then
        DMU.Weapons = DMU.Mode.Weapons
    else
        DMU.Weapons.starter = string.Split(GetConVar("dmu_weapons_starter"):GetString(), ",")
        DMU.Weapons.common = string.Split(GetConVar("dmu_weapons_common"):GetString(), ",")
        DMU.Weapons.uncommon = string.Split(GetConVar("dmu_weapons_uncommon"):GetString(), ",")
        DMU.Weapons.rare = string.Split(GetConVar("dmu_weapons_rare"):GetString(), ",")
        DMU.Weapons.very_rare = string.Split(GetConVar("dmu_weapons_very_rare"):GetString(), ",")
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
load_mode( string.lower( GetConVar("dmu_mode"):GetString() ) ) -- thank GOD these are networked automatically