function DMU.AddBotObjective(entity)
    if !IsValid(entity) then return end
    DMU.BotObjectives[entity] = true
end

function DMU.RemoveBotObjective(entity)
    DMU.BotObjectives[entity] = nil
end

function DMU.AddBotTeamObjective(team_i, entity)
    if !IsValid(entity) then return end
    DMU.BotTeamObjectives[team_i][entity] = true
end

function DMU.RemoveBotTeamObjective(team_i, entity)
    DMU.BotTeamObjectives[team_i][entity] = nil
end

function DMU.AddBotPersonalObjective(ply, entity)
    if !IsValid(ply) or !ply:IsLBot() or !IsValid(entity) then return end
    ply.Objectives[entity] = true
end

function DMU.RemoveBotPersonalObjective(ply, entity)
    if !IsValid(ply) or !ply:IsLBot() then return end
    ply.Objectives[entity] = nil
end