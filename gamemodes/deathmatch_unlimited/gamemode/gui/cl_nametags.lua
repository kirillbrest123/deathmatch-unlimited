local offset = Vector(0,0,16)

local draw_SimpleTextOutlined = draw.SimpleTextOutlined
team_GetColor = team.GetColor
local _EyeAngles = EyeAngles

//local min_distance = 589824
//local max_distance = 2359296

local should_draw = CreateClientConVar("dmu_client_name_tags_enabled", "1", true, false, "Enables/disable name tags above your teammates.", 0, 1)
local scale = CreateClientConVar("dmu_client_name_tags_scale", "1", true, false)

local function render(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
    if !should_draw:GetBool() then return end
    local my_team = LocalPlayer():Team()
    if my_team == TEAM_UNASSIGNED then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() != my_team or !ply:Alive() or ply == LocalPlayer() then continue end
        local pos = ply:EyePos() + offset
        local ang = _EyeAngles()
        ang:RotateAroundAxis(ang:Right(),90)
        ang:RotateAroundAxis(-ang:Up(),90)

        //local alpha = 1 - math.Clamp((pos:DistToSqr(LocalPlayer():GetPos()) - min_distance) / max_distance, 0, 1)
        local color = team_GetColor(ply:Team())
        //color.a = 255 * alpha

        cam.Start3D2D(pos, ang, scale:GetFloat() * 0.2)
            draw_SimpleTextOutlined( ply:Name(), "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
            draw_SimpleTextOutlined( ply:Health() .. "% | " .. ply:Armor() .. "%", "DermaLarge", 0, 24, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
        cam.End3D2D()
    end
end

hook.Add("PostDrawTranslucentRenderables", "DMU_DrawNameTags", render)