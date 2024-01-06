DeriveGamemode( "sandbox" )

GM.Name = "Deathmatch: Unlimited"
GM.Author = ".kkrill"
GM.Email = "N/A"
GM.Website = "N/A"

//GM.TeamBased = true
GM.AllowAutoTeam = true

DMU = {}

function GM:Initialize()

end

function GM:ShouldCollide(ent1, ent2)
	if !(ent1:IsPlayer() and ent2:IsPlayer()) then return end
	return not ent1:Team() == ent2:Team()
end

local function check_allow_feature()
    if GetConVar("dmu_sandbox"):GetBool() then
        return true
    else
        return false
    end
end

hook.Add("SpawnMenuOpen", "dmu_SpawnMenu", check_allow_feature)

function GM:CanProperty() return check_allow_feature() end

function GM:PlayerDeathSound() return true end

function GM:PlayerNoClip(ply) return check_allow_feature() end

function GM:PlayerSpawnVehicle(ply,model,name,table) return check_allow_feature() end

function GM:PlayerSpawnSWEP(ply,weapon,info) return check_allow_feature() end

function GM:PlayerSpawnSENT(ply,class) return check_allow_feature() end

function GM:PlayerSpawnRagdoll(ply,model) return check_allow_feature() end

function GM:PlayerSpawnProp(ply,model) return check_allow_feature() end

function GM:PlayerSpawnObject(ply,model,skin) return check_allow_feature() end

function GM:PlayerSpawnNPC(ply,npc_type,weapon) return check_allow_feature() end

function GM:PlayerSpawnEffect(ply,model) return check_allow_feature() end

function GM:PlayerGiveSWEP(ply,weapon,swep) return check_allow_feature() end

CreateConVar( "dmu_weapons_starter", "dmu_pistol,dmu_carbine", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Default starter weapons, separated by commas. Can be overriden by game mode.")
CreateConVar( "dmu_weapons_common", "dmu_pistol,dmu_carbine", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Default common weapons, separated by commas. Can be overriden by game mode.")
CreateConVar( "dmu_weapons_uncommon", "dmu_assault_rifle,dmu_battle_rifle", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Default uncommon weapons, separated by commas. Can be overriden by game mode.")
CreateConVar( "dmu_weapons_rare", "dmu_smg,dmu_sniper_rifle,dmu_plasma_rifle", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Rare weapons, separated by commas. Can be overriden by game mode.")
CreateConVar( "dmu_weapons_very_rare", "dmu_railgun,dmu_rocket_launcher,dmu_shotgun,dmu_bfb", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Very rare weapons, separated by commas. Can be overriden by game mode.")

CreateConVar( "dmu_weapon_respawn_time", "30", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Default weapons respawn time.")
CreateConVar( "dmu_pickup_respawn_time", "15", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Default health/armor pick-ups respawn time.")

DMU.DefaultScoreLimit = CreateConVar( "dmu_score_limit", "60", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Default score limit. Can be overriden by game mode."):GetInt()