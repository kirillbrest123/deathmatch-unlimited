util.AddNetworkString("DMU_StartVotes")
util.AddNetworkString("DMU_SyncVotes")
util.AddNetworkString("DMU_SendVote")
util.AddNetworkString("DMU_EndVote")

local votes = {}
local vote_options = {}
local chosen_playlist

net.Receive("DMU_SendVote", function(len, ply)
    ply.Vote = net.ReadUInt(4)

    votes = {}

    for k, ply in ipairs(player.GetHumans()) do
        if !ply.Vote then continue end
        if !votes[ply.Vote] then votes[ply.Vote] = 0 end
        votes[ply.Vote] = votes[ply.Vote] + 1
    end

    net.Start("DMU_SyncVotes")
        net.WriteTable(votes)
    net.Broadcast()
end)

local function start_map_votes()

    vote_options = {}
    votes = {}
    for k, ply in ipairs(player.GetHumans()) do
        ply.Vote = nil
    end

    local maps = DMU.PlayLists[chosen_playlist]["maps"]

    if !maps or table.IsEmpty(maps) or maps[1] == "" then
        local installed_maps = file.Find( "maps/*.bsp", "GAME")

        maps = {}

        for k, map in ipairs( installed_maps ) do
            map = map:sub(1, -5)
            maps[k] = map
        end
    end

    for i = 1, GetConVar("dmu_server_num_of_map_choices"):GetInt() do
        local game_mode = DMU.PlayLists[chosen_playlist]["modes"][math.random(1, #DMU.PlayLists[chosen_playlist]["modes"])]
        game_mode = string.lower(game_mode)
        vote_options[i] = {
            mode = game_mode,
            map = maps[math.random(#maps)]
        }
    end

    table.insert(vote_options, {map = "Random"})

    net.Start("DMU_StartVotes")
        net.WriteTable(vote_options)
    net.Broadcast()

    timer.Simple(15, function()
        local winner = table.GetWinningKey(votes) or GetConVar("dmu_server_num_of_map_choices"):GetInt() + 1

        net.Start("DMU_EndVote")
            net.WriteUInt(winner, 4)
        net.Broadcast()

        if winner == GetConVar("dmu_server_num_of_map_choices"):GetInt() + 1 then
            timer.Simple(5, function()
                GetConVar("dmu_server_mode"):SetString(DMU.PlayLists[chosen_playlist]["modes"][math.random(1, #DMU.PlayLists[chosen_playlist]["modes"])])
                RunConsoleCommand("changelevel", maps[math.random(#maps)])
            end)
            return
        end

        timer.Simple(5, function()
            GetConVar("dmu_server_mode"):SetString(vote_options[winner]["mode"])
            RunConsoleCommand("changelevel", vote_options[winner]["map"])
        end)
    end)
end

function DMU.StartVotes()
    for k,playlist in ipairs(DMU.PlayLists) do
        vote_options[k] = {map = playlist.name, thumbnail = playlist.thumbnail}
    end

    table.insert(vote_options, {map = "Keep playing"})

    net.Start("DMU_StartVotes")
        net.WriteTable(vote_options)
    net.Broadcast()    

    timer.Simple(15, function()
        chosen_playlist = table.GetWinningKey(votes) or #DMU.PlayLists + 1

        net.Start("DMU_EndVote")
            net.WriteUInt(chosen_playlist,4)
        net.Broadcast()

        if chosen_playlist == #DMU.PlayLists + 1 then
            timer.Simple(5, function()
                RunConsoleCommand("changelevel", game.GetMap())
            end)
            return
        end

        timer.Simple(5, function()
            start_map_votes()
        end)
    end)
end