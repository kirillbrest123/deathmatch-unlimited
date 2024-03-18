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
        modes = {"Domination", "Kill Confirmed", "King Of The Hill", "CTF", "One Flag CTF", "Oddball"},
        thumbnail = "game_mode_banners/team_objective.png"
    },
    {
        name = "Team Rumble",
        modes = {"Laser Tag", "SWAT", "Zombie VIP", "Team Fiesta", "Flying Oddball"},
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

    function DMU.GetRandomSpotOnNavmesh()
        local navareas = navmesh.GetAllNavAreas()
        if table.IsEmpty(navareas) then return end

        for i = 1, 10 do
            local navarea = navareas[math.random(#navareas)]

            if navarea:IsUnderwater() or bit.band(navarea:GetAttributes(), NAV_MESH_INVALID + NAV_MESH_AVOID + NAV_MESH_TRANSIENT + NAV_MESH_STAIRS) != 0 then
                continue 
            end
            return navarea:GetCenter()
        end

        return navareas[math.random(#navareas)]:GetCenter()
    end

else

    net.Receive("DMU_Notification", function()
        notification.AddLegacy( net.ReadString(), 0, 5 )
        surface.PlaySound("ui/hint.wav") -- no way it's from css
    end)

    hook.Add("player_activate", "DMU_GiveInstructions", function(data)
        if Player(data.userid) != LocalPlayer() then return end
        timer.Simple(10, function()
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