util.AddNetworkString("DMU_SendPlayLists")
util.AddNetworkString("DMU_SavePlayLists")

function DMU.LoadDefaultPlayLists()
    DMU.PlayLists = table.Copy(DMU.DefaultPlayLists)
end

function DMU.LoadPlayLists()
    if not file.IsDir("dmu", "DATA") then
        file.CreateDir("dmu")
    end

    if file.Read("dmu/playlists.txt", "DATA") then
        DMU.PlayLists = util.JSONToTable(file.Read("dmu/playlists.txt", "DATA"))   
    else
        print("[DMU] Playlist file not found! Loading default playlists...")
        DMU.LoadDefaultPlayLists()
    end
end

function DMU.SavePlayLists()
    if not file.IsDir("dmu", "DATA") then
        file.CreateDir("dmu")
        return
    end

    file.Write("dmu/playlists.txt", util.TableToJSON(DMU.PlayLists))
end

net.Receive("DMU_SavePlayLists", function(len, ply)
    if !ply:IsSuperAdmin() then return end
    DMU.PlayLists = net.ReadTable()
    DMU.SavePlayLists()
    DMU.SendNotification("Playlists saved!", ply)
end)

DMU.LoadPlayLists()