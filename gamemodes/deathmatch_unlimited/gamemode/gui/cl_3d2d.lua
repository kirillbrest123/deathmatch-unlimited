local _3D2D_entities = {

}
local _3D2D_positions = {

}

net.Receive("DMU_Sync3D2DEnt", function()
    _3D2D_entities = net.ReadTable()
    for _, tbl in ipairs(_3D2D_entities) do
        tbl.mat = Material(tbl.mat)
    end
end)

net.Receive("DMU_Sync3D2DPos", function()
    _3D2D_positions = net.ReadTable()
    for _, tbl in ipairs(_3D2D_positions) do
        tbl.mat = Material(tbl.mat)
    end
end)

local function render(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)

    local render_ang = EyeAngles()
    render_ang:RotateAroundAxis(render_ang:Right(),90)
    render_ang:RotateAroundAxis(-render_ang:Up(),90)


    cam.IgnoreZ(true)
    for _, tbl in ipairs(_3D2D_entities) do
        if tbl.entity != NULL then -- sometimes entities get networked to client with a delay???? or maybe they don't get networked until they are in PVS??
            cam.Start3D2D(tbl.entity:GetPos(), render_ang, 0.5)
                surface.SetMaterial(tbl.mat)
                surface.SetDrawColor(tbl.color or color_white)
                surface.DrawTexturedRect(-32, -32, 64, 64)
            cam.End3D2D()
        end
    end

    for _, tbl in ipairs(_3D2D_positions) do
        cam.Start3D2D(tbl.pos, render_ang, 0.5)
            surface.SetMaterial(tbl.mat)
            surface.SetDrawColor(tbl.color or color_white)
            surface.DrawTexturedRect(-32, -32, 64, 64)
        cam.End3D2D()
    end
    cam.IgnoreZ(false)
end

hook.Add("PostDrawTranslucentRenderables", "dmu_Render3d2d", render)