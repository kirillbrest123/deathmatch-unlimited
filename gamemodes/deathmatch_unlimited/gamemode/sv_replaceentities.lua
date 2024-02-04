local ents_to_delete = {
    item_ammo_pistol = true,
    item_box_buckshot = true,
    item_ammo_357 = true,
    item_ammo_ar2 = true,
    item_rpg_round = true,
    item_ammo_crossbow = true,
    item_ammo_smg1 = true,
    item_ammo_smg1_grenade = true,
    item_ammo_ar2_altfire = true,
}

local ents_to_replace_common = {
    weapon_pistol = true,
    weapon_frag = true,
    weapon_crowbar = true,
    weapon_stunstick = true,
}

local ents_to_replace_uncommon = {
    weapon_smg1 = true,
    weapon_shotgun = true,
    weapon_physcannon = true,
}

local ents_to_replace_rare = {
    weapon_ar2 = true,
    weapon_357 = true,
    weapon_slam = true
}

local ents_to_replace_very_rare = {
    weapon_crossbow = true,
    weapon_rpg = true
}

function DMU.ReplaceMapEntities()
    local replace_weapons = GetConVar("dmu_server_replace_weapons"):GetBool()
    local replace_items = GetConVar("dmu_server_replace_items"):GetBool()

    for _, ent in ipairs(ents.GetAll()) do

        local class = ent:GetClass()
        local pos = ent:GetPos()

        if ents_to_delete[class] then
            ent:Remove()
        end

        if not replace_weapons then goto cont end

        if ents_to_replace_common[class] then
            ent:Remove()
            if DMU.Mode.WeaponSpawnsDisabled then continue end
            local new_ent = ents.Create("dmu_weapon_spawner")
            new_ent:SetPos(pos)
             
            new_ent:Spawn()
            new_ent:SetFallbackRarity(1)
            continue
        end

        if ents_to_replace_uncommon[class] then
            ent:Remove()
            if DMU.Mode.WeaponSpawnsDisabled then continue end
            local new_ent = ents.Create("dmu_weapon_spawner")
            new_ent:SetPos(pos)
             
            new_ent:Spawn()
            new_ent:SetFallbackRarity(2)
            continue
        end

        if ents_to_replace_rare[class] then
            ent:Remove()
            if DMU.Mode.WeaponSpawnsDisabled then continue end
            local new_ent = ents.Create("dmu_weapon_spawner")
            new_ent:SetPos(pos)
            
            new_ent:Spawn()
            new_ent:SetFallbackRarity(3)
            continue
        end

        if ents_to_replace_very_rare[class] then
            ent:Remove()
            if DMU.Mode.WeaponSpawnsDisabled then continue end
            local new_ent = ents.Create("dmu_weapon_spawner")
            new_ent:SetPos(pos)
            
            new_ent:Spawn()
            new_ent:SetFallbackRarity(4)
            continue
        end

        ::cont::

        if not replace_items then return end

        if class == "item_healthkit" then
            ent:Remove()
            local new_ent = ents.Create("dmu_pickup_medkit")
            new_ent:SetPos(pos)  
            new_ent:Spawn()
            continue
        end

        if class == "item_healthvial" then
            ent:Remove()
            local new_ent = ents.Create("dmu_pickup_healthvial")
            new_ent:SetPos(pos)  
            new_ent:Spawn()
            continue
        end

        if class == "item_battery" then
            ent:Remove()
            local new_ent = ents.Create("dmu_pickup_battery")
            new_ent:SetPos(pos)  
            new_ent:Spawn()
            continue
        end
    end
end

hook.Add("InitPostEntity", "dmu_ReplaceMapEntities", DMU.ReplaceMapEntities)