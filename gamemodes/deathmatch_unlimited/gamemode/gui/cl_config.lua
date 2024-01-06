local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
    self:DockPadding(16,16,16,16)

    local div = vgui.Create("DHorizontalDivider", self)
    div:Dock(FILL)

    -- PLAYLIST SELECTION --

    local playlist_holder = vgui.Create("EditablePanel", self)
    div:SetLeftWidth( 384 )
    div:SetLeft(playlist_holder)

    self.Playlists = vgui.Create("DListView", playlist_holder)
    self.Playlists:Dock(FILL)
    self.Playlists:SetSortable(false)
    self.Playlists:SetMultiSelect(false)
    self.Playlists:AddColumn("Playlists", 1)
    self:RedrawPlaylists()

    self.Playlists.OnRowSelected = function( panel, row_index, row )
        self.SelectedPlaylist = row_index
        self.Name:SetValue(DMU.PlayLists[row_index].name)
        self.Thumbnail:SetValue(DMU.PlayLists[row_index].thumbnail or "")

        local modes = ""
        if DMU.PlayLists[row_index].modes then
            for _, mode in ipairs(DMU.PlayLists[row_index].modes) do
                modes = modes .. mode .. ","
            end
        end

        modes = modes:sub(1, -2)

        self.Modes:SetValue(modes)

        local maps = ""
        if DMU.PlayLists[row_index].maps then
            for _, map in ipairs(DMU.PlayLists[row_index].maps) do
                maps = maps .. map .. ","
            end
        end

        maps = maps:sub(1, -2)

        self.Maps:SetValue(maps)
    end

    local playlist_button_holder = vgui.Create("EditablePanel", playlist_holder)
    playlist_button_holder:SetTall(16)
    playlist_button_holder:Dock(TOP)

    local playlist_button_reset = vgui.Create("DImageButton", playlist_button_holder)
    playlist_button_reset:SetImage("icon16/stop.png")
    playlist_button_reset:SetSize(16,16)
    playlist_button_reset:Dock(RIGHT)
    playlist_button_reset:SetTooltip("RESET ALL PLAYLISTS to default.")
    playlist_button_reset.DoClick = function(panel)
        DMU.PlayLists = table.Copy(DMU.DefaultPlayLists)
        self:RedrawPlaylists()
    end

    local playlist_button_duplicate = vgui.Create("DImageButton", playlist_button_holder)
    playlist_button_duplicate:SetImage("icon16/page_copy.png")
    playlist_button_duplicate:SetSize(16,16)
    playlist_button_duplicate:Dock(RIGHT)
    playlist_button_duplicate:SetTooltip("Duplicate selected playlist.")
    playlist_button_duplicate.DoClick = function(panel)
        if self.SelectedPlaylist then
            table.insert( DMU.PlayLists, table.Copy( DMU.PlayLists[self.SelectedPlaylist] ) )
        end
        self:RedrawPlaylists()
    end

    local playlist_button_movedown = vgui.Create("DImageButton", playlist_button_holder)
    playlist_button_movedown:SetImage("icon16/arrow_down.png")
    playlist_button_movedown:SetSize(16,16)
    playlist_button_movedown:Dock(RIGHT)
    playlist_button_movedown:SetTooltip("Move selected playlist down.")
    playlist_button_movedown.DoClick = function(panel)
        if self.SelectedPlaylist and DMU.PlayLists[self.SelectedPlaylist + 1] then
            DMU.PlayLists[self.SelectedPlaylist], DMU.PlayLists[self.SelectedPlaylist + 1] = DMU.PlayLists[self.SelectedPlaylist + 1], DMU.PlayLists[self.SelectedPlaylist]
            self.SelectedPlaylist = self.SelectedPlaylist + 1
        end
        self:RedrawPlaylists()
    end

    local playlist_button_moveup = vgui.Create("DImageButton", playlist_button_holder)
    playlist_button_moveup:SetImage("icon16/arrow_up.png")
    playlist_button_moveup:SetSize(16,16)
    playlist_button_moveup:Dock(RIGHT)
    playlist_button_moveup:SetTooltip("Move selected playlist up.")
    playlist_button_moveup.DoClick = function(panel)
        if self.SelectedPlaylist and DMU.PlayLists[self.SelectedPlaylist - 1] then
            DMU.PlayLists[self.SelectedPlaylist], DMU.PlayLists[self.SelectedPlaylist - 1] = DMU.PlayLists[self.SelectedPlaylist - 1], DMU.PlayLists[self.SelectedPlaylist]
            self.SelectedPlaylist = self.SelectedPlaylist - 1
        end
        self:RedrawPlaylists()
    end

    local playlist_button_remove = vgui.Create("DImageButton", playlist_button_holder)
    playlist_button_remove:SetImage("icon16/delete.png")
    playlist_button_remove:SetSize(16,16)
    playlist_button_remove:Dock(RIGHT)
    playlist_button_remove:SetTooltip("Remove selected playlist.")
    playlist_button_remove.DoClick = function(panel)
        if self.SelectedPlaylist then
            table.remove(DMU.PlayLists, self.SelectedPlaylist)
            self.SelectedPlaylist = nil
        end
        self:RedrawPlaylists()
    end

    local playlist_button_add = vgui.Create("DImageButton", playlist_button_holder)
    playlist_button_add:SetImage("icon16/add.png")
    playlist_button_add:SetSize(16,16)
    playlist_button_add:Dock(RIGHT)
    playlist_button_add:SetTooltip("Add new playlist.")
    playlist_button_add.DoClick = function(panel)
        local new_playlist = {}
        new_playlist.name = "new playlist"
        new_playlist.modes = {}
        new_playlist.maps = {}

        table.insert(DMU.PlayLists, new_playlist)
        self:RedrawPlaylists()
    end

    -- PLAYLIST OPTIONS --

    local options_holder = vgui.Create("EditablePanel", self)
    div:SetRight(options_holder)

    local name_label = vgui.Create("DLabel", options_holder)
    name_label:Dock(TOP)
    name_label:SetTextColor(color_black)
    name_label:SetText("Name")

    self.Name = vgui.Create("DTextEntry", options_holder)
    self.Name:Dock(TOP)
    self.Name:SetUpdateOnType(true)
    self.Name.OnValueChange = function(panel, value)
        if !self.SelectedPlaylist then return end
        DMU.PlayLists[self.SelectedPlaylist].name = value
        self:RedrawPlaylists()
    end

    local thumb_label = vgui.Create("DLabel", options_holder)
    thumb_label:Dock(TOP)
    thumb_label:SetTextColor(color_black)
    thumb_label:SetText("Thumbnail path")

    self.Thumbnail = vgui.Create("DTextEntry", options_holder)
    self.Thumbnail:Dock(TOP)
    self.Thumbnail:SetUpdateOnType(true)
    self.Thumbnail.OnValueChange = function(panel, value)
        if !self.SelectedPlaylist then return end
        DMU.PlayLists[self.SelectedPlaylist].thumbnail = value
    end

    local modes_label = vgui.Create("DLabel", options_holder)
    modes_label:Dock(TOP)
    modes_label:SetTextColor(color_black)
    modes_label:SetText("Game Modes (separate with commas)")

    self.Modes = vgui.Create("DTextEntry", options_holder)
    self.Modes:Dock(TOP)
    self.Modes:SetUpdateOnType(true)
    self.Modes.OnValueChange = function(panel, value)
        if !self.SelectedPlaylist then return end
        value = string.Split(value, ",")

        DMU.PlayLists[self.SelectedPlaylist].modes = value
    end

    local maps_label = vgui.Create("DLabel", options_holder)
    maps_label:Dock(TOP)
    maps_label:SetTextColor(color_black)
    maps_label:SetText("Maps (separate with commas)")

    self.Maps = vgui.Create("DTextEntry", options_holder)
    self.Maps:Dock(TOP)
    self.Maps.OnValueChange = function(panel, value)
        if !self.SelectedPlaylist then return end
        value = string.Split(value, ",")

        DMU.PlayLists[self.SelectedPlaylist].maps = value
    end

    local apply = vgui.Create("DButton", options_holder)
    apply:SetTall(64)
    apply:Dock(BOTTOM)
    apply:SetText("Save & Apply")
    apply.DoClick = function()
        net.Start("DMU_SavePlayLists")
            net.WriteTable(DMU.PlayLists)
        net.SendToServer()
        DMU.ConfigMenu:Close()
    end
end

function PANEL:RedrawPlaylists()
    for _,line in ipairs(self.Playlists:GetLines()) do
        self.Playlists:RemoveLine(line:GetID())
    end

    for k,v in ipairs(DMU.PlayLists) do
        self.Playlists:AddLine(v.name)
    end
end

vgui.Register("DMU_PlaylistMenu", PANEL, "DPanel")



local PANEL = {}

function PANEL:Init()

    local starter = GetConVar("dmu_weapons_starter"):GetString()
    local common = GetConVar("dmu_weapons_common"):GetString()
    local uncommon = GetConVar("dmu_weapons_uncommon"):GetString()
    local rare = GetConVar("dmu_weapons_rare"):GetString()
    local very_rare = GetConVar("dmu_weapons_very_rare"):GetString()

    self:DockPadding(16,16,16,16)

    local starter_weapons_label = vgui.Create("DLabel", self)
    starter_weapons_label:Dock(TOP)
    starter_weapons_label:SetTextColor(color_black)
    starter_weapons_label:SetText("Starter Weapons (separate with commas)")

    self.StarterWeapons = vgui.Create("DTextEntry", self)
    self.StarterWeapons:Dock(TOP)
    self.StarterWeapons:SetValue(starter)
    self.StarterWeapons:SetUpdateOnType(true)
    self.StarterWeapons.OnValueChange = function(panel, value)
        starter = value
    end

    local common_weapons_label = vgui.Create("DLabel", self)
    common_weapons_label:Dock(TOP)
    common_weapons_label:SetTextColor(color_black)
    common_weapons_label:SetText("Commom Weapons (separate with commas)")

    self.CommonWeapons = vgui.Create("DTextEntry", self)
    self.CommonWeapons:Dock(TOP)
    self.CommonWeapons:SetValue(common)
    self.CommonWeapons:SetUpdateOnType(true)
    self.CommonWeapons.OnValueChange = function(panel, value)
        common = value
    end

    local uncommon_weapons_label = vgui.Create("DLabel", self)
    uncommon_weapons_label:Dock(TOP)
    uncommon_weapons_label:SetTextColor(color_black)
    uncommon_weapons_label:SetText("Uncommon Weapons (separate with commas)")

    self.UncommonWeapons = vgui.Create("DTextEntry", self)
    self.UncommonWeapons:Dock(TOP)
    self.UncommonWeapons:SetUpdateOnType(true)
    self.UncommonWeapons:SetValue(uncommon)
    self.UncommonWeapons.OnValueChange = function(panel, value)
        uncommon = value
    end

    local rare_weapons_label = vgui.Create("DLabel", self)
    rare_weapons_label:Dock(TOP)
    rare_weapons_label:SetTextColor(color_black)
    rare_weapons_label:SetText("Rare Weapons (separate with commas)")

    self.RareWeapons = vgui.Create("DTextEntry", self)
    self.RareWeapons:Dock(TOP)
    self.RareWeapons:SetUpdateOnType(true)
    self.RareWeapons:SetValue(rare)
    self.RareWeapons.OnValueChange = function(panel, value)
        rare = value
    end

    local very_rare_weapons_label = vgui.Create("DLabel", self)
    very_rare_weapons_label:Dock(TOP)
    very_rare_weapons_label:SetTextColor(color_black)
    very_rare_weapons_label:SetText("Very Rare Weapons (separate with commas)")

    self.VeryRareWeapons = vgui.Create("DTextEntry", self)
    self.VeryRareWeapons:Dock(TOP)
    self.VeryRareWeapons:SetUpdateOnType(true)
    self.VeryRareWeapons:SetValue(very_rare)
    self.VeryRareWeapons.OnValueChange = function(panel, value)
        very_rare = value
    end

    local apply = vgui.Create("DButton", self)
    apply:SetTall(64)
    apply:Dock(BOTTOM)
    apply:SetText("Save & Apply")
    apply.DoClick = function()
        net.Start("DMU_SaveConfig")
            net.WriteString(starter)
            net.WriteString(common)
            net.WriteString(uncommon)
            net.WriteString(rare)
            net.WriteString(very_rare)
        net.SendToServer()
        DMU.ConfigMenu:Close()
    end

    local reset = vgui.Create("DButton", self)
    reset:SetTall(32)
    reset:Dock(BOTTOM)
    reset:SetText("Reset to default")
    reset.DoClick = function()
        starter = "dmu_pistol,dmu_carbine"
        common = "dmu_pistol,dmu_carbine"
        uncommon = "dmu_assault_rifle,dmu_battle_rifle"
        rare = "dmu_smg,dmu_sniper_rifle,dmu_plasma_rifle"
        very_rare = "dmu_railgun,dmu_rocket_launcher,dmu_shotgun,dmu_bfb"
        self.StarterWeapons:SetValue(starter)
        self.CommonWeapons:SetValue(common)
        self.UncommonWeapons:SetValue(uncommon)
        self.RareWeapons:SetValue(rare)
        self.VeryRareWeapons:SetValue(very_rare)
    end
end

vgui.Register("DMU_ConfigMenu", PANEL, "DPanel")

net.Receive("DMU_ShowConfigMenu", function()

    if !IsValid(DMU.ConfigMenu) then
        DMU.ConfigMenu = vgui.Create("DFrame")
        DMU.ConfigMenu:SetSize(ScrW()*0.875, ScrH()*0.875)
        DMU.ConfigMenu:Center()

        local sheets = vgui.Create("DPropertySheet", DMU.ConfigMenu)
        sheets:Dock(FILL)

        local playlists = vgui.Create("DMU_PlaylistMenu", sheets)
        local config = vgui.Create("DMU_ConfigMenu", sheets)

        sheets:AddSheet("Playlists", playlists, "icon16/brick.png")
        sheets:AddSheet("Weapons", config, "icon16/bomb.png")
        DMU.ConfigMenu:MakePopup()
    end
end)

net.Receive("DMU_SendPlayLists", function()
    DMU.PlayLists = net.ReadTable()
end)