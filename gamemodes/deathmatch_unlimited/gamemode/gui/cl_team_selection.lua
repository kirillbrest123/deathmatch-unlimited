local bg_color = Color(0, 0, 0, 200)
local color_disabled = Color(150, 150, 150, 180)
local color_red = Color(255,0,0)

local PANEL = {}

function PANEL:Init()
    local tall = ScrH()*0.6

    self:SetText("")

    self:SetSize( tall/2, tall )
    self.Selected = false

    self.Color = color_white
    self.Name = ""
    self.Material = nil
end

function PANEL:OnCursorEntered()
    self.Selected = true
    surface.PlaySound("garrysmod/ui_hover.wav")
end

function PANEL:OnCursorExited()
    self.Selected = false
end

function PANEL:Think()
    local smallest_team = 1
    local a = team.NumPlayers(smallest_team)

    for k,v in ipairs(DMU.Mode.Teams) do
        local b = team.NumPlayers(k)
        if a > b then
            smallest_team = k
            a = b
        end
    end

    self.Disabled = a + 1 < team.NumPlayers(self.Team)
end

function PANEL:Paint(w, h)

    if self.Disabled then
        surface.SetDrawColor( color_disabled )
    elseif self.Selected then
        surface.SetDrawColor( self.SelectColor )
    else
        surface.SetDrawColor( self.Color )
    end


    surface.SetMaterial( self.Material )

    surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, 1, 1)

    -- if self.Disabled then
    --     draw.TextShadow({text = "Too many players!", font = "Trebuchet24", pos = {w/2, h*0.85}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = color_red},2, 200)
    -- end

    draw.TextShadow({text = self.Name, font = "DermaLarge", pos = {w/2, h*0.9}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = color_white},2, 200)
    draw.TextShadow({text = team.NumPlayers(self.Team) .. " Players", font = "Trebuchet18", pos = {w/2, h*0.95}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = color_white},2, 200)
end

function PANEL:DoClick()
    surface.PlaySound("garrysmod/ui_click.wav")
    if self.Disabled then return end
    RunConsoleCommand("changeteam", self.Team)
    DMU.TeamMenu:Remove()
end

vgui.Register("DMU_TeamItem", PANEL, "DButton")

local PANEL = {}

function PANEL:Init()
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:ParentToHUD()

    self:Dock(FILL)
    self:DockPadding(ScrW()/10,ScrH()/10,ScrH()/10,ScrW()/10)

    local item_wide = ScrH() * 0.3
    local gap = 64
    local x = ScrW()/2 - ( item_wide * #DMU.Mode.Teams + gap * (#DMU.Mode.Teams - 1) )/2

    for k,v in ipairs(DMU.Mode.Teams) do
        local btn = vgui.Create("DMU_TeamItem", self)
        btn:SetPos(x, ScrH()/2 - item_wide)

        btn.Name = v.name
        btn.Team = k

        local h,s,v1 = v.color:ToHSV()
        s = s * 0.85
        btn.Color = HSVToColor(h,s,v1)
        s = s * 0.8
        btn.SelectColor = HSVToColor(h,s,v1)

        if v.banner then
            btn.Material = Material(v.banner)
        else
            btn.Material = Material("team_banners/" .. k .. ".png")
        end

        if btn.Material:IsError() then
            btn.Material = Material("gui/noicon.png")
        end

        x = x + item_wide + gap
    end

    local auto_assign = vgui.Create("DButton", self)
    auto_assign:SetFont("DermaLarge")
    auto_assign:SetText("Auto-assign")
    auto_assign:SizeToContents()
    auto_assign:SetPos(ScrW()*0.9, ScrH()*0.95 - auto_assign:GetTall()/2)
    auto_assign:SetContentAlignment(5)

    auto_assign.DoClick = function()
        RunConsoleCommand("changeteam", -1)
        self:Remove()
    end

    auto_assign.Paint = function() end
end

function PANEL:Paint(w, h)
    Derma_DrawBackgroundBlur(self) -- this exists - mind blown

    draw.NoTexture()
    surface.SetDrawColor(bg_color)

    surface.DrawRect(0, h*0.9, w, h)
end

vgui.Register("DMU_TeamSelection", PANEL, "DPanel")

net.Receive("DMU_ShowTeamMenu", function()
    if !IsValid(DMU.TeamMenu) then
        DMU.TeamMenu = vgui.Create("DMU_TeamSelection")
    else
        DMU.TeamMenu:Remove()
    end
end)