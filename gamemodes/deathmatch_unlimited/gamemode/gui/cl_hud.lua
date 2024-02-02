local w = ScrW()
local h = ScrH()
local x = w/2 - 170
local y = h/6 - 32
local holdzone_verts = { -- this is fucked up -- UPD: ayo i think i found the proper thing for it??? TODO: look into render.SetScissorRect(). perhaps i'll be able to avoid this mess...
    [1] = {
        {["x"] = x+32, ["y"] = y+60},
        {["x"] = x+6, ["y"] = y+42},
        {["x"] = x+58, ["y"] = y+42},
    },
    [2] = {
        {["x"] = x+6, ["y"] = y+42},
        {["x"] = x+6, ["y"] = y+29},
        {["x"] = x+58, ["y"] = y+29},
        {["x"] = x+58, ["y"] = y+42},
    },
    [3] = {
        {["x"] = x+6, ["y"] = y+29},
        {["x"] = x+6, ["y"] = y+18},
        {["x"] = x+58, ["y"] = y+18},
        {["x"] = x+58, ["y"] = y+29},
    },
    [4] = {
        {["x"] = x+6, ["y"] = y+18},
        {["x"] = x+32, ["y"] = y+2},
        {["x"] = x+58, ["y"] = y+18},
    },
}

surface.CreateFont( "dmu_score_time_font", {
	font = "Roboto Lt", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 42,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local panel_color = Color(0,0,0,120)

net.Receive("DMU_SyncRound", function()
    DMU.Round = net.ReadUInt(8)
end)

net.Receive("DMU_SyncTimeLeft", function()
    DMU.CurTimeLimit = net.ReadUInt(32)
end)

local function display_time(time)
    if time < 0 then
        return "0:00"
    elseif math.floor(time % 60) < 10 then
        return math.floor(time/60)  .. ":0" .. math.floor(time % 60)
    else
        return math.floor(time/60)  .. ":" .. math.floor(time % 60)
    end
end

local function draw_score_team()
    
    local my_team = LocalPlayer():Team()
    if my_team == TEAM_UNASSIGNED or my_team == TEAM_SPECTATOR or my_team == TEAM_CONNECTING then return end

    local best_team = nil
    for k, v in pairs(DMU.Mode.Teams) do
        if k == my_team then continue end
        best_team = best_team or k
        if team.GetScore(k) > team.GetScore(best_team) then
            best_team = k
        end
    end

    draw.RoundedBoxEx(8, w/2-128, 0, 256, 72, panel_color, false, false, true, true)
    surface.SetDrawColor(DMU.Mode.Teams[my_team]["color"])
    surface.DrawRect(w/2-128, 0, 128, 6)
    surface.SetDrawColor(DMU.Mode.Teams[best_team]["color"])
    surface.DrawRect(w/2, 0, 128, 6)

    if DMU.Mode.TimeLimit then
        local time_left = DMU.CurTimeLimit - CurTime()
        draw.SimpleTextOutlined(display_time(time_left), "dmu_score_time_font", w/2, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    end

    if DMU.Round then
        draw.SimpleTextOutlined( "Round " .. DMU.Round, "DermaDefault", w/2, 48, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
    end

    draw.SimpleTextOutlined( team.GetScore(my_team), "DermaLarge", w/2-80, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    draw.SimpleTextOutlined( team.GetScore(best_team), "DermaLarge", w/2+80, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
end

local function draw_score_ffa()

    local players = player.GetAll()

    local best_player = nil
    for k, v in ipairs(players) do
        if v == LocalPlayer() then continue end
        best_player = best_player or v
        if v:GetScore() > best_player:GetScore() then
            best_player = v
        end
    end

    draw.RoundedBoxEx(8, w/2-128, 0, 256, 72, panel_color, false, false, true, true)
    surface.SetDrawColor(color_white)
    surface.DrawRect(w/2-128, 0, 256, 6)

    if DMU.Mode.TimeLimit then
        local time_left = DMU.CurTimeLimit - CurTime()
        draw.SimpleTextOutlined(display_time(time_left), "dmu_score_time_font", w/2, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    end
    draw.SimpleTextOutlined( LocalPlayer():Nick(), "DermaDefault", w/2-80, 48, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
    draw.SimpleTextOutlined( LocalPlayer():GetScore(), "DermaLarge", w/2-80, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)

    if best_player then
        draw.SimpleTextOutlined( best_player:Nick(), "DermaDefault", w/2+80, 48, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
        draw.SimpleTextOutlined( best_player:GetScore(), "DermaLarge", w/2+80, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    end
    
    if DMU.Round then
        draw.SimpleTextOutlined( "Round " .. DMU.Round, "DermaDefault", w/2, 48, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
    end
end

timer.Simple(0, function()
    if DMU.Mode.FFA then
        hook.Add("HUDPaint", "DMU_DrawScore", draw_score_ffa)
    else
        hook.Add("HUDPaint", "DMU_DrawScore", draw_score_team)
    end
end)

-- hill hud

local in_holdzone
local holdzone_team
local hold_progress
local hold_mats = 
{
    Material("hold_zone_icons/hold_zone_0_hud.png"),
    Material("hold_zone_icons/hold_zone_1_hud.png"),
    Material("hold_zone_icons/hold_zone_2_hud.png"),
    Material("hold_zone_icons/hold_zone_3_hud.png"),
    Material("hold_zone_icons/hold_zone_4_hud.png"),
}
local hold_identifier

net.Receive("DMU_HoldZoneHUD", function()
    in_holdzone = net.ReadBool()
    holdzone_team = net.ReadInt(12)
    hold_progress = net.ReadInt(8)
    hold_identifier = net.ReadUInt(4)
end)

hook.Add("HUDPaint", "DMU_DrawHoldZoneProgress", function ()

    if !in_holdzone then return end

    local text_data = {
        ["font"] = "DermaLarge",
        ["pos"] = {w/2,h/6},
        ["xalign"] = TEXT_ALIGN_CENTER,
        ["yalign"] = TEXT_ALIGN_CENTER
    }
    if holdzone_team != LocalPlayer():Team() then
        text_data.text = "Capturing hill"
    else
        text_data.text = "Hill under control"
    end
    draw.TextShadow( text_data, 1)

    local x = w/2 - 170
    local y = h/6 - 32

    local reverse

    if holdzone_team != -1 then
        surface.SetDrawColor(team.GetColor(holdzone_team))
        reverse = true
    else
        surface.SetDrawColor(team.GetColor(LocalPlayer():Team()))
        reverse = false
    end

    draw.NoTexture()

    if !reverse then
        if hold_progress >= 25 then
            surface.DrawPoly(holdzone_verts[1])
        end
        if hold_progress >= 50 then
            surface.DrawPoly(holdzone_verts[2])
        end
        if hold_progress >= 75 then
            surface.DrawPoly(holdzone_verts[3])
        end
        if hold_progress >= 100 then
            surface.DrawPoly(holdzone_verts[4])
        end
    else
        if hold_progress <= 100 then
            surface.DrawPoly(holdzone_verts[1])
        end
        if hold_progress < 75 then
            surface.DrawPoly(holdzone_verts[2])
        end
        if hold_progress < 50 then
            surface.DrawPoly(holdzone_verts[3])
        end
        if hold_progress < 25 then
            surface.DrawPoly(holdzone_verts[4])
        end
    end

    surface.SetMaterial(hold_mats[hold_identifier + 1]) -- i forgot that tables in lua are 1 indexed...
    surface.DrawTexturedRect(x, y, 64, 64)
end)

-- announcements

local announcement_text = ""
local announcement_time = 0
announcement_fadein_timer = 0

surface.CreateFont( "AnnouncementFont", {font = "Roboto", size = 72, italic = true})

net.Receive("DMU_Announcement", function()
    announcement_text = net.ReadString()
    announcement_time = CurTime() + net.ReadUInt(8)
    announcement_fadein_timer = CurTime() + 0.2
    local snd = net.ReadString()
    if snd and snd != "" then
        surface.PlaySound(snd)
    end
end)

hook.Add("HUDPaint", "DMU_DrawAnnouncements", function ()
    if CurTime() > announcement_time then return end

    local alpha = 255 * math.min(1, 1 - (announcement_fadein_timer - CurTime()) / 0.2 )

    draw.TextShadow({text = announcement_text, font = "AnnouncementFont", pos = {w/2, h/2 - 36}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = Color(255,255,255,alpha)}, 2)
end)

local music_disabled = CreateClientConVar( "dmu_client_disable_victory_music", "0", true, false, "", 0, 1)

net.Receive("DMU_MatchVictoryAnnouncement", function()
    announcement_time = CurTime() + 10
    announcement_fadein_timer = CurTime() + 0.2
    local winner = net.ReadUInt(13)

    if DMU.Mode.FFA and winner == LocalPlayer():EntIndex() or !DMU.Mode.FFA and winner == LocalPlayer():Team() then
        announcement_text = "Victory"
        if !(DMU.Mode.RoundBased) and !music_disabled:GetBool() then -- music will be already playing from round victory announcement. Too bad there's no way to stop sounds played with surface.PlaySound()
            surface.PlaySound("music/hl2_song15.mp3")
        end
    else
        announcement_text = "Defeat"
        if !(DMU.Mode.RoundBased) and !music_disabled:GetBool() then
            surface.PlaySound("music/hl2_song23_suitsong3.mp3")
        end
    end
end)

net.Receive("DMU_RoundVictoryAnnouncement", function()
    announcement_time = CurTime() + 10
    announcement_fadein_timer = CurTime() + 0.2
    local winner = net.ReadUInt(13)
    
    if winner == 0 then
        announcement_text = "Round End"
        if !music_disabled:GetBool() then
            surface.PlaySound("music/hl2_song8.mp3")
        end
        return
    end

    winner = winner - 1

    if DMU.Mode.FFA and winner == LocalPlayer():EntIndex() or !DMU.Mode.FFA and winner == LocalPlayer():Team() then
        announcement_text = "Round Won"
        if !music_disabled:GetBool() then
            surface.PlaySound("music/hl2_song15.mp3")
        end
    else
        announcement_text = "Round Lost"
        if !music_disabled:GetBool() then
            surface.PlaySound("music/hl2_song23_suitsong3.mp3")
        end
    end
end)