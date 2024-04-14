include("shared.lua")
include("sh_playerscore.lua")
include("sh_medals.lua")
include("sh_modes.lua")
include("sh_misc.lua")

include("gui/cl_hud.lua")
include("gui/cl_3d2d.lua")
include("gui/cl_vote.lua")
include("gui/cl_voteitem.lua")
include("gui/cl_scoreboard.lua")
include("gui/cl_config.lua")
include("gui/cl_team_selection.lua")
include("gui/cl_nametags.lua")

hook.Add("HUDShouldDraw", "dmu_RemoveRedScreen", function(name)
    if (name == "CHudDamageIndicator") then
       return false
    end
end)

timer.Simple(0, function()
    GAMEMODE:SuppressHint( "OpeningMenu" )
    GAMEMODE:SuppressHint( "Annoy1" )
    GAMEMODE:SuppressHint( "Annoy2" )
end)