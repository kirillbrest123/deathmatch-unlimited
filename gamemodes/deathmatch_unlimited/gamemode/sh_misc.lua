DMU.rarity_to_color = {
    ["common"] = Color(127,127,127),
    ["uncommon"] = Color(0,153,255),
    ["rare"] = Color(127,32,255),
    ["very_rare"] = Color(255,200,0),
}
DMU.color_crimson = Color(255,0,60)

DMU.DefaultPlayLists = {
    {
        name = "Team Deathmatch",
        modes = {"tdm",},
        thumbnail = "game_mode_banners/tdm.png"
    },
    {
        name = "FFA Brawl",
        modes = {"ffa", "instagib", "one_in_the_chamber", "juggernaut"},
        thumbnail = "game_mode_banners/ffa_brawl.png"
    },
    {
        name = "Sniper Frenzy",
        modes = {"snipers", "shotty_snipers", "hot_rockets"},
        thumbnail = "game_mode_banners/sniper_frenzy.png"
    },   
    {
        name = "Team Objective",
        modes = {"domination", "kill_confirmed", "king_of_the_hill"},
        thumbnail = "game_mode_banners/team_objective.png"
    },
    {
        name = "Team Rumble",
        modes = {"laser_tag", "swat", "zombie_vip"},
        thumbnail = "game_mode_banners/team_rumble.png"
    },
    {
        name = "Search and Survive",
        modes = {"showdown", "survival", "evolution", "takedown"},
        thumbnail = "game_mode_banners/search_and_survive.png"
    },
}

if SERVER then
    util.AddNetworkString("DMU_Notification")

    function DMU.SendNotification(text, ply)
        net.Start("DMU_Notification")
            net.WriteString(text)
        if ply == nil then
            net.Broadcast()
        else
            net.Send(ply)
        end
    end

    util.AddNetworkString("DMU_Announcement")

    function DMU.SendAnnouncement(text, length, sound, ply)
        net.Start("DMU_Announcement")
            net.WriteString(text)
            net.WriteUInt(length, 8)
            net.WriteString(sound)
        if ply == nil then
            net.Broadcast()
        else
            net.Send(ply)
        end
    end

    local plymeta = FindMetaTable("Player")

    function plymeta:DMU_SetGravity( gravity )
        self:SetGravity(gravity)
        self:SetNWFloat("DMU_Gravity", gravity)
    end

else

    net.Receive("DMU_Notification", function()
        notification.AddLegacy( net.ReadString(), 0, 5 )
        surface.PlaySound("ui/hint.wav")
    end)

    hook.Add("InitPostEntity", "DMU_GiveInstructions", function()
        timer.Simple(5, function()
            chat.AddText(color_white, "Current Game Mode: ", DMU.color_crimson, DMU.Mode.PrintName)

            if DMU.Mode.Instructions then
                chat.AddText(Color(255,225,120), "========================\n", DMU.Mode.Instructions, "\n========================")
            end
        end)
    end)
    
    hook.Add("SetupMove", "DMU_SharedGravity", function( ply, mv, cmd )
        ply:SetGravity(ply:GetNWFloat("DMU_Gravity", 0))
    end)

end