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
        modes = {"Team Deathmatch",},
        thumbnail = "game_mode_banners/tdm.png"
    },
    {
        name = "FFA Brawl",
        modes = {"FFA Deathmatch", "Instagib", "One In The Chamber", "Juggernaut", "Gun Game", "Contamination"},
        thumbnail = "game_mode_banners/ffa_brawl.png"
    },
    {
        name = "Sniper Frenzy",
        modes = {"Snipers", "Shotty Snipers", "Hot Rockets"},
        thumbnail = "game_mode_banners/sniper_frenzy.png"
    },   
    {
        name = "Team Objective",
        modes = {"Domination", "Kill Confirmed", "King Of The Hill", "CTF", "One Flag CTF"},
        thumbnail = "game_mode_banners/team_objective.png"
    },
    {
        name = "Team Rumble",
        modes = {"Laser Tag", "SWAT", "Zombie VIP"},
        thumbnail = "game_mode_banners/team_rumble.png"
    },
    {
        name = "Search and Survive",
        modes = {"Showdown", "Survival", "Evolution", "Takedown", "Survival Duo"},
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
            chat.AddText(color_white, "Current Game Mode: ", DMU.color_crimson, DMU.Mode.PrintName or DMU.Mode.Name)

            if DMU.Mode.Instructions then
                chat.AddText(Color(255,225,120), "========================\n", DMU.Mode.Instructions, "\n========================")
            end
        end)
    end)
    
    hook.Add("SetupMove", "DMU_SharedGravity", function( ply, mv, cmd )
        ply:SetGravity(ply:GetNWFloat("DMU_Gravity", 0))
    end)

end