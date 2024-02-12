// NOTE: THIS CODE IS A bit of a MESS (mostly because of weird naming now that i think of it)
// NOTE-TO-SELF: i should either reduce the base size, convert everything to a fraction of screen width, or make it so there's multiple floors of vote options somehow
// oh wait that also means fucking around with fonts fuck god dammit
// i hate derma
// okay idid it thankgod
// i should actually do it with horizontal scrollers. why didn't i think of this before

local function get_thumb(name)
    if file.Exists("maps/thumb/" .. name .. ".png", "GAME") then
        return Material("maps/thumb/" .. name .. ".png", "no_clamp")
    elseif file.Exists("maps/" .. name .. ".png", "GAME") then
        return Material("maps/" .. name .. ".png", "no_clamp")
    else
        return Material("gui/noicon.png")
    end
end

surface.CreateFont( "dmu_vote_result_font", {
	font = "Roboto Lt", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 54,
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

local tall = ScrH() * 0.3555
local item_wide = math.ceil(math.max(64, ScrW() * 0.0666))

local PANEL = {}

function PANEL:Init()
    self:SetSize( 196 , tall)
    self:Center()
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:ParentToHUD()

    self.items = {}
end

local panel_color = Color(0,0,0,200)

function PANEL:Paint(w,h)
    draw.RoundedBox(8,0,0,w,h,panel_color)
    draw.DrawText(math.ceil(self.Timer - CurTime()), "CloseCaption_Bold", w/2, h*0.875, color_white, TEXT_ALIGN_CENTER)
    if self.WinningVote then
        draw.DrawText("Winning vote", "DermaLarge", w/2, h/2-32, DMU.color_crimson, TEXT_ALIGN_CENTER)
        draw.DrawText(self.WinningVote, "dmu_vote_result_font", w/2, h/2, color_white, TEXT_ALIGN_CENTER)
    end
end

function PANEL:UpdateItems()
    self.Timer = CurTime() + 15
    self.WinningVote = nil

    local gap = math.ceil(item_wide * 0.375)

    self:SetWide(#self.VoteOptions * item_wide + gap * (#self.VoteOptions - 1) + item_wide/2)

    local item_x = self:GetWide()/2 - ( item_wide * #self.VoteOptions + gap * (#self.VoteOptions - 1) )/2

    for k,v in ipairs(self.items) do
        v:Remove()
    end
    self.items = {}

    local playlist_vote = true

    for k, item in ipairs(self.VoteOptions) do
        self.items[k] = vgui.Create("DMU_VoteItem", self)

        self.items[k].Name = item.map
        if item.mode then
            self.items[k].Mode = DMU.Modes[item.mode].PrintName or DMU.Modes[item.mode].Name
        end

        local mat = Material(item.thumbnail or "")

        if mat then
            self.items[k].NoResizing = true
            self.items[k].Material = mat
        else
            self.items[k].Material = get_thumb(item.map)
        end

        self.items[k]:SetPos(item_x, self:GetTall()/2 - item_wide)
        item_x = item_x + item_wide + gap

        self.items[k].DoClick = function(self)
            for _, v in ipairs(self:GetParent().items) do
                v.Selected = false
            end
            self.Selected = true
            surface.PlaySound("UI/buttonclick.wav")

            net.Start("DMU_SendVote")
                net.WriteUInt(k,4)
            net.SendToServer()
        end
    end

    self:SetPos(ScrW()/2-self:GetWide()/2, ScrH()-self:GetTall()-item_wide/2)
end

function PANEL:ShowVoteResults(winning_vote)
    self:SetWide(768)
    self:SetPos(ScrW()/2-self:GetWide()/2, ScrH()-self:GetTall()-item_wide/2)

    for k,v in ipairs(self.items) do
        v:Remove()
    end
    self.items = {}

    self.Timer = CurTime() + 5


    if self.VoteOptions[winning_vote].mode then
        self.WinningVote = DMU.Modes[self.VoteOptions[winning_vote].mode]["PrintName"] .. " - " .. self.VoteOptions[winning_vote].map
    else
        self.WinningVote = self.VoteOptions[winning_vote].map
    end
end

vgui.Register("DMU_VotingMenu", PANEL, "EditablePanel")

net.Receive("DMU_StartVotes", function()
    if !IsValid(DMU.VotingMenu) then DMU.VotingMenu = vgui.Create("DMU_VotingMenu") end
    DMU.VotingMenu.VoteOptions = net.ReadTable()
    DMU.VotingMenu:UpdateItems()
end)

net.Receive("DMU_SyncVotes", function()
    local votes = net.ReadTable()
    for k, item in ipairs(DMU.VotingMenu.items) do
        item.Votes = votes[k]
    end
end)

net.Receive("DMU_EndVote", function()
    DMU.VotingMenu:ShowVoteResults(net.ReadUInt(4))
end)