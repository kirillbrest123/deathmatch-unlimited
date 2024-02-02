util.AddNetworkString("DMU_Sync3D2DEnt")
util.AddNetworkString("DMU_Sync3D2DPos")


DMU._3D2D_positions = {}
DMU._3D2D_entities = {}

function DMU.Add3D2DEnt(ent, mat, color)
    for k,v in ipairs(DMU._3D2D_entities) do
        if v.entity == ent then
            v.mat = mat
            v.color = color
            DMU.Sync3D2DEnt()
            return
        end
    end
    table.insert(DMU._3D2D_entities, {["entity"] = ent, ["mat"] = mat, ["color"] = color})
    DMU.Sync3D2DEnt()
end

function DMU.Remove3D2DEnt(ent)
    for k,v in ipairs(DMU._3D2D_entities) do -- i'd rather have this instead of having to use pairs() in rendering hooks
        if v.entity == ent then
            table.remove(DMU._3D2D_entities, k)
            break
        end
    end
    DMU.Sync3D2DEnt()
end

-- index will probably be the entity index. I mean, the only reason why this function exists is so you can do the thing with server-side only entities like brushes and stuff
function DMU.Add3D2DPos(index, pos, mat, color)
    for k,v in ipairs(DMU._3D2D_positions) do
        if v.index == index then
            v.mat = mat
            v.color = color
            DMU.Sync3D2DPos()
            return
        end
    end
    table.insert(DMU._3D2D_positions, {["index"] = index, ["pos"] = pos, ["mat"] = mat, ["color"] = color} )
    DMU.Sync3D2DPos()
end

function DMU.Remove3D2DPos(index)
    for k,v in ipairs(DMU._3D2D_positions) do
        if v.index == index then
            table.remove(DMU._3D2D_positions, k)
            break
        end
    end
    DMU.Sync3D2DPos()
end

function DMU.Sync3D2DEnt()
    net.Start("DMU_Sync3D2DEnt")
        net.WriteTable(DMU._3D2D_entities)
    net.Broadcast()
end

function DMU.Sync3D2DPos()
    net.Start("DMU_Sync3D2DPos")
        net.WriteTable(DMU._3D2D_positions)
    net.Broadcast()
end

hook.Add("player_activate", "DMU_Initial3D2DSync",function()
    timer.Simple(1, function() -- networking is hell
        DMU.Sync3D2DEnt()
        DMU.Sync3D2DPos()
    end)
end)