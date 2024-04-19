local plymeta = FindMetaTable("Player")

function plymeta:VoteEndMatch()
    if DMU.GameEnded then return end
    self.EndMatch = true

    local votes = 0
    local required_votes = math.floor(#player.GetHumans() / 2 + 1)

    for k,v in ipairs(player.GetHumans()) do
        if v.EndMatch then
            votes = votes + 1
        end
    end

    DMU.SendNotification(self:Nick() .. " wants to end the match (" .. votes .. "/" .. required_votes .. ")")

    if votes >= required_votes then
        DMU.EndGame()
    end
end

function plymeta:VoteEndRound()
    if DMU.RoundEnded or !DMU.Mode.RoundBased then return end
    self.EndRound = true

    local votes = 0
    local required_votes = math.floor(#player.GetHumans() / 2 + 1)

    for k,v in ipairs(player.GetHumans()) do
        if v.EndRound then
            votes = votes + 1
        end
    end

    DMU.SendNotification(self:Nick() .. " wants to end the round (" .. votes .. "/" .. required_votes .. ")")

    if votes >= required_votes then
        for k,v in ipairs(player.GetHumans()) do
            v.EndRound = false
        end
        DMU.EndRound()
    end
end

local skill_to_text = {
    [0] = "Easy",
    [1] = "Medium",
    [2] = "Hard",
    [3] = "Aggressive"
}

function plymeta:VoteBotSkill(skill)
    skill = tonumber(skill)
    local leadbot_skill = GetConVar("leadbot_skill")

    if !skill then DMU.SendNotification("Current bot skill is " .. skill_to_text[leadbot_skill:GetInt()] .. ".", self) return end
    if !skill_to_text[skill] then DMU.SendNotification("Invalid skill!", self) return end -- uhhhhh
    if leadbot_skill:GetInt() == skill then DMU.SendNotification("Bot skill is already " .. skill_to_text[skill] .. "!", self) return end
    self.BotSkill = skill

    local votes = 0
    local required_votes = math.floor(#player.GetHumans() / 2 + 1)

    for k,v in ipairs(player.GetHumans()) do
        if v.BotSkill == skill then
            votes = votes + 1
        end
    end

    DMU.SendNotification(self:Nick() .. " wants to change bot skill to " .. skill_to_text[skill] .. " (" .. votes .. "/" .. required_votes .. ")")

    if votes >= required_votes then
        leadbot_skill:SetInt(skill)
        DMU.SendNotification("Bot skill changed to " .. skill_to_text[skill] .. "!")
    end
end

-- hey uhhh english is not my first language so if you have a suggestion on how to make things more clear lmk ty
function plymeta:VoteBotQuota(max_bots)
    max_bots = tonumber(max_bots)
    local leadbot_quota = GetConVar("leadbot_quota")

    if !max_bots or max_bots < 0 or max_bots > math.min(12, game.MaxPlayers() - 1) then DMU.SendNotification("Invalid argument!", self) return end
    if leadbot_quota:GetInt() == max_bots then DMU.SendNotification("Bot quota is already " .. max_bots .. "!", self) return end
    self.BotQuota = max_bots

    local votes = 0
    local required_votes = math.floor(#player.GetHumans() / 2 + 1)

    for k,v in ipairs(player.GetHumans()) do
        if v.BotQuota == max_bots then
            votes = votes + 1
        end
    end

    DMU.SendNotification(self:Nick() .. " wants to change the max number of bots to " .. max_bots .. " (" .. votes .. "/" .. required_votes .. ")")

    if votes >= required_votes then
        leadbot_quota:SetInt(max_bots)
        DMU.SendNotification("Bot quota changed to " .. max_bots .. "!")
    end
end

function plymeta:VoteMap(msg)
    local map
    local mode

    for i = 10, #msg do
        if msg[i] == " " then
            map = string.sub(msg, 10, i - 1)
            mode = string.sub(msg, i + 1)
            break
        end
    end

    if !map or !mode then DMU.SendNotification("Invalid argument!", self) return end

    mode = string.lower(mode)

    local playlist = DMU.ModeToPlaylist[mode]
    local print_name = DMU.Modes[mode] and (DMU.Modes[mode].PrintName or DMU.Modes[mode].Name)

    if !print_name then DMU.SendNotification("Invalid game mode!", self) return end

    local map_is_valid = false

    if DMU.PlayLists[playlist].maps and !table.IsEmpty(DMU.PlayLists[playlist].maps) and DMU.PlayLists[playlist].maps[1] != "" then
        for _, v in ipairs(DMU.PlayLists[playlist].maps) do
            if v == map then map_is_valid = true break end
        end
    else
        for _, v in ipairs(file.Find( "maps/*.bsp", "GAME")) do
            v = v:sub(1, -5)
            if v == map then map_is_valid = true break end
        end
    end

    if !map_is_valid then DMU.SendNotification("Invalid map!", self) return end

    local players = player.GetHumans()

    local votes = 0
    local required_votes = math.floor(#players / 2 + 1)

    self.VotedMap = map .. ";" .. mode

    for k,v in ipairs(player.GetHumans()) do
        if v.VotedMap == self.VotedMap then
            votes = votes + 1
        end
    end

    DMU.SendNotification(self:Nick() .. " wants to change map to "  .. map .. " - " .. print_name  .. " (" .. votes .. "/" .. required_votes .. ")")

    if votes >= required_votes then
        DMU.SendNotification("Changing map to " .. map .. " - " .. print_name  .. " in 10 seconds!")

        timer.Simple(10, function()
            GetConVar("dmu_server_mode"):SetString(mode)
            RunConsoleCommand("changelevel", map)
        end)
    end
end

hook.Add("PlayerSay", "DMU_Commands", function(ply, input, teamChat)
    local text = string.Split(input, " ")
    local command = string.lower(text[1])

    if command == "!help" then
        timer.Simple( 0, function()
            ply:PrintMessage(HUD_PRINTTALK, "'!endmatch' - Initiate a vote to end match early")
            ply:PrintMessage(HUD_PRINTTALK, "'!endround' - Initiate a vote to end round early")
            ply:PrintMessage(HUD_PRINTTALK, "'!votemap <map> <game mode>' - Initiate a vote to change map and game mode")
            if ply:IsSuperAdmin() then
                ply:PrintMessage(HUD_PRINTTALK, "'!config' - Open config menu")
            end
            if LeadBot then
                ply:PrintMessage(HUD_PRINTTALK, "'!botskill [0-3]' - Initiate a vote to change bots' skill level")
                ply:PrintMessage(HUD_PRINTTALK, "'!botquota [0-" .. math.min(12, game.MaxPlayers() - 1) .. "]' - Initiate a vote to change bot quota")
            end

            ply:PrintMessage(HUD_PRINTTALK, "Current Game Mode: " .. (DMU.Mode.PrintName or DMU.Mode.Name))

            if DMU.Mode.Instructions then
                ply:PrintMessage(HUD_PRINTTALK, DMU.Mode.Instructions)
            end
        end)

        -- return ""
    elseif command == "!endmatch" then
        ply:VoteEndMatch()
        return ""
    elseif command == "!endround" then
        ply:VoteEndRound()
        return ""
    elseif command == "!votemap" then
        ply:VoteMap(input)
        return ""
    elseif command == "!config" and ply:IsSuperAdmin() then
        net.Start("DMU_SendPlayLists")
            net.WriteTable(DMU.PlayLists)
        net.Send(ply)

        DMU.ShowConfigMenu(ply)
        return ""
    elseif command == "!botskill" and LeadBot then
        ply:VoteBotSkill(text[2])
        return ""
    elseif command == "!botquota" and LeadBot then
        ply:VoteBotQuota(text[2])
        return ""
    end
end)