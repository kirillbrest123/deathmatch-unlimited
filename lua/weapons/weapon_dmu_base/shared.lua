if CLIENT then
    surface.CreateFont( "CSTypeDeath", {
        font = "csd",
        size = 80,
        weight = 0,
        antialias = true,
        additive = true,
    } )
end

SWEP.Base = "weapon_base"
SWEP.Scoped = false
SWEP.ADSFov = 56
SWEP.ADSZoom = -1
SWEP.BounceWeaponIcon = false

function SWEP:CSetupDataTables()

end

function SWEP:SetupDataTables()
    self:NetworkVar( "Float", 31, "ReloadTimer" ) -- I LOVE DATA TABLES
    self:NetworkVar( "Bool", 30, "Reloading" )
    self:NetworkVar( "Bool", 31, "ADS" )

    self:CSetupDataTables()
end

function SWEP:CInitialize()

end

function SWEP:Initialize()

    self:CInitialize()

    if CLIENT then

        // Create a new table for every weapon instance
        self.VElements = table.FullCopy( self.VElements )
        self.WElements = table.FullCopy( self.WElements )
        self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

        self:CreateModels(self.VElements) // create viewmodels
        self:CreateModels(self.WElements) // create worldmodels

        // init view model bone build function
        if IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                self:ResetBonePositions(vm)

                // Init viewmodel visibility
                if (self.ShowViewModel == nil or self.ShowViewModel) then
                    vm:SetColor(Color(255,255,255,255))
                else
                    // we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
                    vm:SetColor(Color(255,255,255,1))
                    // ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
                    // however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
                    -- vm:SetMaterial("Models/effects/vol_light001") -- debug/Hsv doensn't seem to work, but this is good enough
                    -- ^ nvm. all weapons use the same viewmodel, changing its material will cause all viewmodels to be invisible and i cba to fix it
                end
            end
        end

    end

end

function SWEP:CDeploy()

end

function SWEP:Deploy()
    self:CDeploy()

    if self.Scoped then -- why is holster() not enough
        self:SetADS( false )
    end

    return true
end

function SWEP:COnRemove()

end

function SWEP:OnRemove()

    self:COnRemove()

    self:Holster()

end

function SWEP:CanPrimaryAttack()

    if ( self:Clip1() <= 0 ) and !self:GetReloading() then

        self:EmitSound( "Weapon_Pistol.Empty" )
        self:SetNextPrimaryFire( CurTime() + 0.2 )
        self:Reload()
        return false

    end

    if self:GetReloading() then
        return false
    end

    return true

end

function SWEP:Reload()
    if self:GetReloading() or self:Clip1() == self:GetMaxClip1() or self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then return end

    local owner = self:GetOwner()
    local vm = owner:GetViewModel()

    self:SendWeaponAnim( ACT_VM_RELOAD )
    owner:SetAnimation( PLAYER_RELOAD )

    self:SetReloading(true)
    self:SetReloadTimer( CurTime() + vm:SequenceDuration() )
end

function SWEP:CHolster()

end


function SWEP:Holster()

    if self.Scoped then
        self:SetADS( false )
    end

    -- if SERVER and IsValid(self:GetOwner()) then -- "Before WEAPON:OnRemove is called, this function is only called serverside." - FUCK YOU
    --     self:CallOnClient("Holster")
    -- end

    if CLIENT and IsValid(self:GetOwner()) then
        local vm = self:GetOwner():GetViewModel()
        if IsValid(vm) then
            self:ResetBonePositions(vm)
        end
    end

    self:SetReloading(false)
    local ret = self:CHolster()
    return ret == nil or ret
end

function SWEP:OwnerChanged()
    self:SetReloading(false)
end

function SWEP:SecondaryAttack()

end

function SWEP:CThink()

end

function SWEP:Think()

    self:CThink()

    local owner = self:GetOwner()

    if self:GetReloading() and CurTime() >= self:GetReloadTimer() then
        self:SetReloading(false)

        local num = math.min(owner:GetAmmoCount(self:GetPrimaryAmmoType()), self:GetMaxClip1() - self:Clip1())

        self:SetClip1( self:Clip1() + num )
        owner:RemoveAmmo( num, self:GetPrimaryAmmoType() )

    end

    if !self.Scoped then return end

    if owner:KeyPressed( IN_ATTACK2) then
        self:SetADS( true )
        owner:SetFOV( self.ADSZoom != -1 and owner:GetFOV() * self.ADSZoom or self.ADSFov, 0.13)
        if CLIENT and IsFirstTimePredicted() and self.ADSZoom == -1 then
            surface.PlaySound("weapons/sniper/sniper_zoomin.wav")
        end
    end

    if !owner:KeyDown( IN_ATTACK2 ) and owner:KeyDownLast( IN_ATTACK2 ) then
        self:SetADS( false )
        owner:SetFOV(0, 0.1)
    end
end

function SWEP:ShootEffects()

    local owner = self:GetOwner()
    if !IsValid(owner) then return end -- because that can happen

    self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
    owner:MuzzleFlash()
    owner:SetAnimation( PLAYER_ATTACK1 )

end

if CLIENT then

    function SWEP:AdjustMouseSensitivity()
        if not self:GetADS() then return end
        return self.ADSZoom != -1 and self.ADSZoom or self.ADSFov / 90 -- assumes that your fov is 90, so it doesn't scale perfectly, but i cba to think of a better solution for now
    end

    SWEP.vRenderOrder = nil
    function SWEP:ViewModelDrawn()

        local owner = self:GetOwner()
        if !IsValid(owner) then return end
        local vm = owner:GetViewModel()
        if !IsValid(vm) then return end

        if (!self.VElements) then return end

        self:UpdateBonePositions(vm)

        if (!self.vRenderOrder) then

            // we build a render order because sprites need to be drawn after models
            self.vRenderOrder = {}

            for k, v in pairs( self.VElements ) do
                if (v.type == "Model") then
                    table.insert(self.vRenderOrder, 1, k)
                elseif (v.type == "Sprite" or v.type == "Quad") then
                    table.insert(self.vRenderOrder, k)
                end
            end

        end

        for k, name in ipairs( self.vRenderOrder ) do

            local v = self.VElements[name]
            if (!v) then self.vRenderOrder = nil break end
            if (v.hide) then continue end

            local model = v.modelEnt
            local sprite = v.spriteMaterial

            if (!v.bone) then continue end

            local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )

            if (!pos) then continue end

            if (v.type == "Model" and IsValid(model)) then

                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                model:SetAngles(ang)
                //model:SetModelScale(v.size)
                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix( "RenderMultiply", matrix )

                if (v.material == "") then
                    model:SetMaterial("")
                elseif (model:GetMaterial() != v.material) then
                    model:SetMaterial( v.material )
                end

                if (v.skin and v.skin != model:GetSkin()) then
                    model:SetSkin(v.skin)
                end

                if (v.bodygroup) then
                    for k, v in pairs( v.bodygroup ) do
                        if (model:GetBodygroup(k) != v) then
                            model:SetBodygroup(k, v)
                        end
                    end
                end

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(true)
                end

                render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
                render.SetBlend(v.color.a/255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(false)
                end

            elseif (v.type == "Sprite" and sprite) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial(sprite)
                render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

            elseif (v.type == "Quad" and v.draw_func) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                cam.Start3D2D(drawpos, ang, v.size)
                    v.draw_func( self )
                cam.End3D2D()

            end

        end

    end

    SWEP.wRenderOrder = nil

    function SWEP:CDrawWorldModel()

    end

    function SWEP:DrawWorldModel()

        if (self.ShowWorldModel == nil or self.ShowWorldModel) then
            self:DrawModel()
        end

        self:CDrawWorldModel()

        if (!self.WElements) then return end

        if (!self.wRenderOrder) then

            self.wRenderOrder = {}

            for k, v in pairs( self.WElements ) do
                if (v.type == "Model") then
                    table.insert(self.wRenderOrder, 1, k)
                elseif (v.type == "Sprite" or v.type == "Quad") then
                    table.insert(self.wRenderOrder, k)
                end
            end

        end

        if (IsValid(self.Owner)) then
            bone_ent = self.Owner
        else
            // when the weapon is dropped
            bone_ent = self
        end

        for k, name in pairs( self.wRenderOrder ) do

            local v = self.WElements[name]
            if (!v) then self.wRenderOrder = nil break end
            if (v.hide) then continue end

            local pos, ang

            if (v.bone) then
                pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
            else
                pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
            end

            if (!pos) then continue end

            local model = v.modelEnt
            local sprite = v.spriteMaterial

            if (v.type == "Model" and IsValid(model)) then

                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                model:SetAngles(ang)
                //model:SetModelScale(v.size)
                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix( "RenderMultiply", matrix )

                if (v.material == "") then
                    model:SetMaterial("")
                elseif (model:GetMaterial() != v.material) then
                    model:SetMaterial( v.material )
                end

                if (v.skin and v.skin != model:GetSkin()) then
                    model:SetSkin(v.skin)
                end

                if (v.bodygroup) then
                    for k, v in pairs( v.bodygroup ) do
                        if (model:GetBodygroup(k) != v) then
                            model:SetBodygroup(k, v)
                        end
                    end
                end

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(true)
                end

                render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
                render.SetBlend(v.color.a/255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(false)
                end

            elseif (v.type == "Sprite" and sprite) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial(sprite)
                render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

            elseif (v.type == "Quad" and v.draw_func) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                cam.Start3D2D(drawpos, ang, v.size)
                    v.draw_func( self )
                cam.End3D2D()

            end

        end

    end

    function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )

        local bone, pos, ang
        if (tab.rel and tab.rel != "") then

            local v = basetab[tab.rel]

            if (!v) then return end

            // Technically, if there exists an element with the same name as a bone
            // you can get in an infinite loop. Let's just hope nobody's that stupid.
            pos, ang = self:GetBoneOrientation( basetab, v, ent )

            if (!pos) then return end

            pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)

        else

            bone = ent:LookupBone(bone_override or tab.bone)

            if (!bone) then return end

            pos, ang = Vector(0,0,0), Angle(0,0,0)
            local m = ent:GetBoneMatrix(bone)
            if (m) then
                pos, ang = m:GetTranslation(), m:GetAngles()
            end

            if (IsValid(self.Owner) and self.Owner:IsPlayer() and
                ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
                ang.r = -ang.r // Fixes mirrored models
            end

        end

        return pos, ang
    end

    function SWEP:CreateModels( tab )

        if (!tab) then return end

        // Create the clientside models here because Garry says we can't do it in the render hook
        for k, v in pairs( tab ) do
            if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and
                    string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then

                v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
                if (IsValid(v.modelEnt)) then
                    v.modelEnt:SetPos(self:GetPos())
                    v.modelEnt:SetAngles(self:GetAngles())
                    v.modelEnt:SetParent(self)
                    v.modelEnt:SetNoDraw(true)
                    v.createdModel = v.model
                else
                    v.modelEnt = nil
                end

            elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite)
                and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then

                local name = v.sprite.."-"
                local params = { ["$basetexture"] = v.sprite }
                // make sure we create a unique name based on the selected options
                local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
                for i, j in pairs( tocheck ) do
                    if (v[j]) then
                        params["$"..j] = 1
                        name = name.."1"
                    else
                        name = name.."0"
                    end
                end

                v.createdSprite = v.sprite
                v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)

            end
        end

    end

    local allbones
    local hasGarryFixedBoneScalingYet = false

    function SWEP:UpdateBonePositions(vm)

        if self.ViewModelBoneMods then

            if (!vm:GetBoneCount()) then return end

            // !! WORKAROUND !! //
            // We need to check all model names :/
            local loopthrough = self.ViewModelBoneMods
            if (!hasGarryFixedBoneScalingYet) then
                allbones = {}
                for i=0, vm:GetBoneCount() do
                    local bonename = vm:GetBoneName(i)
                    if (self.ViewModelBoneMods[bonename]) then
                        allbones[bonename] = self.ViewModelBoneMods[bonename]
                    else
                        allbones[bonename] = {
                            scale = Vector(1,1,1),
                            pos = Vector(0,0,0),
                            angle = Angle(0,0,0)
                        }
                    end
                end

                loopthrough = allbones
            end
            // !! ----------- !! //

            for k, v in pairs( loopthrough ) do
                local bone = vm:LookupBone(k)
                if (!bone) then continue end

                // !! WORKAROUND !! //
                local s = Vector(v.scale.x,v.scale.y,v.scale.z)
                local p = Vector(v.pos.x,v.pos.y,v.pos.z)
                local ms = Vector(1,1,1)
                if (!hasGarryFixedBoneScalingYet) then
                    local cur = vm:GetBoneParent(bone)
                    while(cur >= 0) do
                        local pscale = loopthrough[vm:GetBoneName(cur)].scale
                        ms = ms * pscale
                        cur = vm:GetBoneParent(cur)
                    end
                end

                s = s * ms
                // !! ----------- !! //

                if vm:GetManipulateBoneScale(bone) != s then
                    vm:ManipulateBoneScale( bone, s )
                end
                if vm:GetManipulateBoneAngles(bone) != v.angle then
                    vm:ManipulateBoneAngles( bone, v.angle )
                end
                if vm:GetManipulateBonePosition(bone) != p then
                    vm:ManipulateBonePosition( bone, p )
                end
            end
        else
            self:ResetBonePositions(vm)
        end

    end

    function SWEP:ResetBonePositions(vm)

        if (!vm:GetBoneCount()) then return end
        for i=0, vm:GetBoneCount() do
            vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
            vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
            vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
        end

    end

    /**************************
        Global utility code
    **************************/

    // Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
    // Does not copy entities of course, only copies their reference.
    // WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
    function table.FullCopy( tab )

        if (!tab) then return nil end

        local res = {}
        for k, v in pairs( tab ) do
            if (type(v) == "table") then
                res[k] = table.FullCopy(v) // recursion ho!
            elseif (type(v) == "Vector") then
                res[k] = Vector(v.x, v.y, v.z)
            elseif (type(v) == "Angle") then
                res[k] = Angle(v.p, v.y, v.r)
            else
                res[k] = v
            end
        end

        return res

    end

end