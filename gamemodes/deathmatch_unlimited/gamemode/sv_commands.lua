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

hook.Add("PlayerSay", "DMU_Commands", function(ply, input, teamChat)
    local text = string.Split(input, " ")
    local command = string.lower(text[1])

    if command == "!help" then
        ply:PrintMessage(HUD_PRINTTALK, "'!endmatch' - Initiate a vote to end match early")
        ply:PrintMessage(HUD_PRINTTALK, "'!endround' - Initiate a vote to end round early")
        if ply:IsSuperAdmin() then
            ply:PrintMessage(HUD_PRINTTALK, "'!config' - Open config menu")
        end
        if LeadBot then
            ply:PrintMessage(HUD_PRINTTALK, "'!botskill [0-3]' - Initiate a vote to change bots' skill level")
            ply:PrintMessage(HUD_PRINTTALK, "'!botquota [0-" .. math.min(12, game.MaxPlayers() - 1) .. "]' - Initiate a vote to change bot quota")
        end

        ply:PrintMessage(HUD_PRINTTALK, "Current Game Mode: " .. DMU.Mode.PrintName)

        if !DMU.Mode.Tips then return "" end

        for k,v in ipairs(DMU.Mode.Tips) do
            ply:PrintMessage(HUD_PRINTTALK, v)
        end

        return ""
    elseif command == "!endmatch" then
        ply:VoteEndMatch()
        return ""
    elseif command == "!endround" then
        ply:VoteEndRound()
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