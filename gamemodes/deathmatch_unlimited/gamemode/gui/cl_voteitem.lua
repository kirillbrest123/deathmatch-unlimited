local PANEL = {}

local wide = math.ceil(math.max(64, ScrW() * 0.0666)) -- may your woes be many and your days few if you change resolution mid-game

function PANEL:Init()
    self:SetSize( wide, 2*wide )
    self.Material = Material("gui/noicon.png")
    self.Name = ""
    self.Mode = ""
    self:SetText("")
    self.BtnColor = color_white
end

surface.CreateFont( "dmu_vote_font", {
	font = "Roboto Lt",
	extended = false,
	size = math.ceil(wide * 0.5625),
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

surface.CreateFont( "dmu_mode_font", {
	font = "Trebuchet MS",
	extended = false,
	size = math.ceil(wide * 0.1406),
	weight = 900,
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

function PANEL:Paint(w, h)
    surface.SetDrawColor(self.BtnColor)
    if self.Selected then
        surface.SetDrawColor(DMU.color_crimson)
    end
    surface.DrawRect(0, 0, w, h)
    surface.SetMaterial( self.Material )

    if !self.NoResizing then
        surface.DrawTexturedRectUV(2, 2, w-4, h-4, 0.25, 0, 0.75, 1)
    else
        surface.DrawTexturedRectUV(2, 2, w-4, h-4, 0, 0, 1, 1)
    end

    draw.DrawText(self.Mode .. "\n" .. self.Name, "dmu_mode_font", w/2, h-55, color_white, TEXT_ALIGN_CENTER)
    //draw.DrawText(self.Mode, "Trebuchet18", w/2, h-55, color_white, TEXT_ALIGN_CENTER)
    draw.TextShadow({text = self.Votes or "", font = "dmu_vote_font", pos = {w/2, 48}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = color_white},2, 200)
end

function PANEL:OnCursorEntered()
    self.BtnColor = DMU.color_crimson
    surface.PlaySound("garrysmod/ui_hover.wav")
end

function PANEL:OnCursorExited()
    self.BtnColor = color_white
end

vgui.Register("DMU_VoteItem", PANEL, "DButton")