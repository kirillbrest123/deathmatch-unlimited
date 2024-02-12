
surface.CreateFont( "dmu_scoreboard_default", {
	font	= "Trebuchet",
	size	= 22,
	weight	= 550,
	shadow = true,
} )

surface.CreateFont( "dmu_scoreboard_info", {
	font	= "Trebuchet",
	size	= 18,
	weight	= 800
} )

surface.CreateFont( "dmu_scoreboard_score", {
	font	= "Roboto",
	size	= 56,
	weight	= 500,
	//italic = true
} )

local black96 = Color(0,0,0,96) -- gmod wiki says that you shouldn't use Color() in rendering hooks
local black127 = Color(0,0,0,127) -- and Color() was used a lot in the rendering hooks here
local black48 = Color(0,0,0,48) -- am i missing something?
local black200 = Color( 0, 0, 0, 200 ) -- am i stupid?

--
-- This defines a new panel type for the player row. The player row is given a player
-- and then from that point on it pretty much looks after itself. It updates player info
-- in the think function, and removes itself when the player leaves the server.
--
local PLAYER_LINE = {
	Init = function( self )

		self.AvatarButton = self:Add( "DButton" )
		self.AvatarButton:Dock( LEFT )
		self.AvatarButton:SetSize( 32, 32 )
		self.AvatarButton.DoClick = function() self.Player:ShowProfile() end

		self.Avatar = vgui.Create( "AvatarImage", self.AvatarButton )
		self.Avatar:SetSize( 32, 32 )
		self.Avatar:SetMouseInputEnabled( false )

		self.Name = self:Add( "DLabel" )
		self.Name:Dock( FILL )
		self.Name:SetFont( "dmu_scoreboard_default" )
		self.Name:SetTextColor( color_white )
		self.Name:DockMargin( 8, 0, 0, 0 )

		self.Mute = self:Add( "DImageButton" )
		self.Mute:SetSize( 32, 32 )
		self.Mute:Dock( RIGHT )

		self.Ping = self:Add( "DLabel" )
		self.Ping:Dock( RIGHT )
		self.Ping:SetWidth( 50 )
		self.Ping:SetFont( "dmu_scoreboard_default" )
		self.Ping:SetTextColor( color_white )
		self.Ping:SetContentAlignment( 5 )

		self.Deaths = self:Add( "DLabel" )
		self.Deaths:Dock( RIGHT )
		self.Deaths:SetWidth( 50 )
		self.Deaths:SetFont( "dmu_scoreboard_default" )
		self.Deaths:SetTextColor( color_white )
		self.Deaths:SetContentAlignment( 5 )

		self.Kills = self:Add( "DLabel" )
		self.Kills:Dock( RIGHT )
		self.Kills:SetWidth( 50 )
		self.Kills:SetFont( "dmu_scoreboard_default" )
		self.Kills:SetTextColor( color_white )
		self.Kills:SetContentAlignment( 5 )

		self.Score = self:Add( "DLabel" )
		self.Score:Dock( RIGHT )
		self.Score:SetWidth( 50 )
		self.Score:SetFont( "dmu_scoreboard_default" )
		self.Score:SetTextColor( color_white )
		self.Score:SetContentAlignment( 5 )

		if DMU.Mode.Teams then
			timer.Simple(0, function()
				self.Name:SetTextColor( team.GetColor(self.Player:Team()) )
				self.Ping:SetTextColor( team.GetColor(self.Player:Team()) )
				self.Deaths:SetTextColor( team.GetColor(self.Player:Team()) )
				self.Kills:SetTextColor( team.GetColor(self.Player:Team()) )
				self.Score:SetTextColor( team.GetColor(self.Player:Team()) )
			end)
		end

		self:Dock( TOP )
		self:DockPadding( 3, 3, 3, 3 )
		self:SetHeight( 32 + 3 * 2 )
		self:DockMargin( 2, 0, 2, 2 )

	end,

	Setup = function( self, pl )

		self.Player = pl

		self.Avatar:SetPlayer( pl )

		self.Team = pl:Team()

		self:Think( self )

		--local friend = self.Player:GetFriendStatus()
		--MsgN( pl, " Friend: ", friend )

	end,

	Think = function( self )

		if ( !IsValid( self.Player ) or self.Player:Team() != self.Team ) then
			self:SetZPos( 9999 ) -- Causes a rebuild
			self:Remove()
			return
		end

		if ( self.PName == nil || self.PName != self.Player:Nick() ) then
			self.PName = self.Player:Nick()
			self.Name:SetText( self.PName )
		end

		if ( self.NumKills == nil || self.NumKills != self.Player:Frags() ) then
			self.NumKills = self.Player:Frags()
			self.Kills:SetText( self.NumKills )
		end

		if ( self.NumDeaths == nil || self.NumDeaths != self.Player:Deaths() ) then
			self.NumDeaths = self.Player:Deaths()
			self.Deaths:SetText( self.NumDeaths )
		end

		if ( self.NumPing == nil || self.NumPing != self.Player:Ping() ) then
			self.NumPing = self.Player:Ping()
			self.Ping:SetText( self.NumPing )
		end

		if ( self.NumScore == nil || self.NumScore != self.Player:GetScore() ) then
			self.NumScore = self.Player:GetScore()
			self.Score:SetText( self.NumScore )
		end		

		--
		-- Change the icon of the mute button based on state
		--
		if ( self.Muted == nil || self.Muted != self.Player:IsMuted() ) then

			self.Muted = self.Player:IsMuted()
			if ( self.Muted ) then
				self.Mute:SetImage( "icon32/muted.png" )
			else
				self.Mute:SetImage( "icon32/unmuted.png" )
			end

			self.Mute.DoClick = function( s ) self.Player:SetMuted( !self.Muted ) end
			self.Mute.OnMouseWheeled = function( s, delta )
				self.Player:SetVoiceVolumeScale( self.Player:GetVoiceVolumeScale() + ( delta / 100 * 5 ) )
				s.LastTick = CurTime()
			end

			self.Mute.PaintOver = function( s, w, h )
				if ( !IsValid( self.Player ) ) then return end
			
				local a = 255 - math.Clamp( CurTime() - ( s.LastTick or 0 ), 0, 3 ) * 255
				if ( a <= 0 ) then return end
				
				draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, a * 0.75 ) )
				draw.SimpleText( math.ceil( self.Player:GetVoiceVolumeScale() * 100 ) .. "%", "DermaDefaultBold", w / 2, h / 2, Color( 255, 255, 255, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end

		end

		--
		-- Connecting players go at the very bottom
		--
		if ( self.Player:Team() == TEAM_CONNECTING ) then
			self:SetZPos( 2000 + self.Player:EntIndex() )
			return
		end

		--
		-- This is what sorts the list. The panels are docked in the z order,
		-- so if we set the z order according to kills they'll be ordered that way!
		-- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
		--
		self:SetZPos( ( self.NumScore * -50 ) + self.NumDeaths + self.Player:EntIndex() )

	end,

	OnCursorEntered = function( self )
		self.Selected = true
	end,

	OnCursorExited = function( self )
		self.Selected = false
	end,

	Paint = function( self, w, h )

		if ( !IsValid( self.Player ) ) then
			return
		end

		if ( self.Selected ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 60, 60, 60, 127 ) )
			return
		end

		if ( self.Player:Team() == TEAM_CONNECTING ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 200, 200, 200, 200 ) )
			return
		end

		if ( !self.Player:Alive() ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 80, 0, 0, 127 ) )
			return
		end

		draw.RoundedBox( 4, 0, 0, w, h, black127 )

	end
}

--
-- Convert it from a normal table into a Panel Table based on DPanel
--
PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" )



local TEAM_LINE = {
	Init = function( self )

		self:Dock( TOP )
		self:DockPadding( 3, 3, 3, 3 )
		self:SetHeight( ScrH()/4 )
		self:DockMargin( 0, 2, 0, 2 )

		self.Score = self:Add( "Panel" )
		self.Score:Dock(LEFT)
		self.Score:DockMargin( 2, 0, 2, 2 )
		self.Score:SetWide(96)
		self.Score.Paint = function(s, w, h)
			draw.RoundedBox( 4, 0, 0, w, h, black96 )
			draw.TextShadow({text = team.GetScore(self.Team), font = "dmu_scoreboard_score", pos = {w/2, h/2}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = team.GetColor(self.Team)},2, 200)
		end

		self.Scores = self:Add( "DScrollPanel" )
		self.Scores:Dock( FILL )
	end,

	Think = function( self, w, h )

		for id, pl in ipairs( team.GetPlayers(self.Team) ) do

			if ( IsValid( pl.ScoreEntry ) ) then continue end

			pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
			pl.ScoreEntry:Setup( pl )

			self.Scores:AddItem( pl.ScoreEntry )

		end

	end,

	Paint = function( self, w, h )
		//draw.RoundedBox( 4, 0, 0, w, h, black127 )
		draw.RoundedBox( 4, 0, 0, w, h, black48 )
	end,

	Setup = function( self, t )
		self.Team = t
		self.Color = DMU.Mode.Teams[self.Team]["color"]
		self:Think()
	end,
}

TEAM_LINE = vgui.RegisterTable( TEAM_LINE, "DPanel" )

--
-- Here we define a new panel table for the scoreboard. It basically consists
-- of a header and a scrollpanel - into which the player lines are placed.
--

local SCORE_BOARD = {
	Init = function( self )

		self.Header = self:Add( "Panel" )
		self.Header:Dock( TOP )
		self.Header:SetHeight( 48 )

		self.Name = self.Header:Add( "DLabel" )
		self.Name:SetFont( "ScoreboardDefaultTitle" )
		self.Name:SetTextColor( DMU.color_crimson )
		self.Name:Dock( RIGHT )
		self.Name:SetSize( ScrW()/2 - 200, 40 )
		self.Name:SetContentAlignment( 6 )
		self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
		self.Name:SetText( GetHostName() )

		self.Mode = self.Header:Add( "DLabel" )
		self.Mode:SetFont( "ScoreboardDefaultTitle" )
		self.Mode:SetTextColor( DMU.color_crimson )
		self.Mode:Dock( LEFT )
		self.Mode:SetSize( ScrW()/2 - 200, 40 )
		self.Mode:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
		self.Mode:SetText( string.Replace(DMU.Mode.PrintName or DMU.Mode.Name, "\n", " ") .. " - " .. game.GetMap() )

		self.Info = self:Add( "Panel" )
		self.Info:Dock( TOP )
		self.Info:SetHeight( 48 )
		self.Info:DockPadding(96,0,50,0)

		self.Info.Paint = function(s, w ,h)
			draw.RoundedBox( 4, 0, 0, w, h, black200 )
		end

		self.Info.Name = self.Info:Add( "DLabel" )
		self.Info.Name:SetFont("dmu_scoreboard_info")
		self.Info.Name:SetTextColor( color_white )
		self.Info.Name:SetContentAlignment(5)
		self.Info.Name:Dock(LEFT)
		self.Info.Name:SetText("Name")

		self.Info.Ping = self.Info:Add( "DLabel" )
		self.Info.Ping:SetFont("dmu_scoreboard_info")
		self.Info.Ping:SetTextColor( color_white )
		self.Info.Ping:SetContentAlignment(5)
		self.Info.Ping:SetWidth( 50 )
		self.Info.Ping:Dock(RIGHT)
		self.Info.Ping:SetText("Ping")

		self.Info.Deaths = self.Info:Add( "DLabel" )
		self.Info.Deaths:SetFont("dmu_scoreboard_info")
		self.Info.Deaths:SetTextColor( color_white )
		self.Info.Deaths:SetContentAlignment(5)
		self.Info.Deaths:SetWidth( 50 )
		self.Info.Deaths:Dock(RIGHT)
		self.Info.Deaths:SetText("Deaths")

		self.Info.Kills = self.Info:Add( "DLabel" )
		self.Info.Kills:SetFont("dmu_scoreboard_info")
		self.Info.Kills:SetTextColor( color_white )
		self.Info.Kills:SetContentAlignment(5)
		self.Info.Kills:SetWidth( 50 )
		self.Info.Kills:Dock(RIGHT)
		self.Info.Kills:SetText("Kills")

		self.Info.Score = self.Info:Add( "DLabel" )
		self.Info.Score:SetFont("dmu_scoreboard_info")
		self.Info.Score:SetTextColor( color_white )
		self.Info.Score:SetContentAlignment(5)
		self.Info.Score:SetWidth( 50 )
		self.Info.Score:Dock(RIGHT)
		self.Info.Score:SetText("Score")

		self.Teams = self:Add( "DScrollPanel" )
		self.Teams:Dock( FILL )

		if !DMU.Mode.FFA then
			local teams = table.Copy(DMU.Mode.Teams)

			-- i originally wanted to make it so your team line is displayed first, but i kinda can't figure out a way to do it properly rn

			--[[local team_line = vgui.CreateFromTable( TEAM_LINE, self )
			local first_team = LocalPlayer():Team() == TEAM_UNASSIGNED and 1 or LocalPlayer():Team()
			team_line:Setup( first_team )

			self.Teams:AddItem(team_line)

			teams[first_team] = nil]]--
			for k,v in ipairs(teams) do
				team_line = vgui.CreateFromTable( TEAM_LINE, self )
				team_line:Setup(k)

				self.Teams:AddItem(team_line)
			end
		end
	end,

	PerformLayout = function( self )

		self:SetSize( ScrW() - 400, ScrH()*0.6666 )
		self:Center()

	end,

	Paint = function( self, w, h )

		//draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 80 ) )

	end,

	Think = function( self, w, h )
		if DMU.Mode.FFA then
			for id, pl in ipairs( player.GetAll() ) do

				if ( IsValid( pl.ScoreEntry ) ) then continue end

				pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
				pl.ScoreEntry:Setup( pl )

				self.Teams:AddItem( pl.ScoreEntry )

			end
		end
	end
}

SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" )

--[[---------------------------------------------------------
	Name: gamemode:ScoreboardShow( )
	Desc: Sets the scoreboard to visible
-----------------------------------------------------------]]
function GM:ScoreboardShow()

	if ( !IsValid( g_Scoreboard ) ) then
		g_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
	end

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Show()
		g_Scoreboard:MakePopup()
		g_Scoreboard:SetKeyboardInputEnabled( false )
	end

end

--[[---------------------------------------------------------
	Name: gamemode:ScoreboardHide( )
	Desc: Hides the scoreboard
-----------------------------------------------------------]]
function GM:ScoreboardHide()

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Hide()
	end

end

--[[---------------------------------------------------------
	Name: gamemode:HUDDrawScoreBoard( )
	Desc: If you prefer to draw your scoreboard the stupid way (without vgui)
-----------------------------------------------------------]]
function GM:HUDDrawScoreBoard()
end
