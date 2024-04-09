DMU.Medals = {}

function DMU.RegisterMedal(name, printname, material)
    local medal = {}
    medal.PrintName = printname
    medal.Material = Material(material)

    DMU.Medals[name] = medal
end

DMU.RegisterMedal("first_blood", "First Blood", "medals/firstblood.png")
DMU.RegisterMedal("headshot", "Headshot", "medals/headshot.png")
DMU.RegisterMedal("premature_burial", "Premature Burial", "medals/premature_burial.png")
DMU.RegisterMedal("king_slayer", "King Slayer", "medals/kingslayer.png")
DMU.RegisterMedal("collateral", "Collateral", "medals/collateral.png")
DMU.RegisterMedal("mvp", "MVP", "medals/star_yellow.png")

DMU.RegisterMedal("double_kill", "Double Kill", "medals/killstreak1.png")
DMU.RegisterMedal("triple_kill", "Triple Kill", "medals/killstreak2.png")
DMU.RegisterMedal("quad_kill", "Quad Kill!", "medals/killstreak3.png")
DMU.RegisterMedal("penta_kill", "Penta Kill!", "medals/killstreak4.png")
DMU.RegisterMedal("killsanity", "Killsanity!", "medals/killstreak5.png")

DMU.RegisterMedal("killing_spree_5", "Killing Spree", "medals/killing_spree_5.png")
DMU.RegisterMedal("killing_spree_10", "Rampage", "medals/killing_spree_10.png")
DMU.RegisterMedal("killing_spree_15", "Fragtastic", "medals/killing_spree_15.png")
DMU.RegisterMedal("killing_spree_20", "God Mode", "medals/killing_spree_20.png")
DMU.RegisterMedal("killing_spree_25", "Frenetic", "medals/killing_spree_25.png")

if SERVER then
    util.AddNetworkString("DMU_Medal")

    function DMU.GiveMedal(ply, medal)
        net.Start("DMU_Medal")
            net.WriteString(medal)
        net.Send(ply)
        hook.Run("DMU_PlayerReceivedMedal", ply, medal)
    end

    hook.Add("PlayerDeath", "DMU_KillMedals", function(victim, inflictor, attacker)
        victim.KillingSpree = nil

        if !attacker:IsPlayer() then return end
        if attacker == victim then return end
        if DMU.Mode.FriendlyFire and victim:Team() == attacker:Team() then return end

        -- First Blood
        if !DMU.FirstBloodHappened then
            DMU.GiveMedal(attacker, "first_blood")
            DMU.FirstBloodHappened = true
        end

        -- Headshot
        if victim:LastHitGroup() == HITGROUP_HEAD then
            DMU.GiveMedal(attacker, "headshot")
        end

        -- King Slayer
        local players

        if DMU.Mode.FFA then
            players = player.GetAll()
        else
            players = team.GetPlayers(victim:Team())
        end

        local best_player = players[1]
        for k,v in ipairs(players) do
            if v:Frags() > best_player:Frags() then best_player = v end
        end

        if victim == best_player then
            DMU.GiveMedal(attacker, "king_slayer")
        end

        -- Kill Streaks
        attacker.KillStreak = (attacker.KillStreak or 0) + 1

        timer.Create(attacker:Name() .. "killstreak_timer", 5, 1, function()
            if !IsValid(attacker) then return end
            attacker.KillStreak = nil
        end)

        if attacker.KillStreak > 5 then
            DMU.GiveMedal(attacker, "killsanity")
        elseif attacker.KillStreak == 5 then
            DMU.GiveMedal(attacker, "penta_kill")
        elseif attacker.KillStreak == 4 then
            DMU.GiveMedal(attacker, "quad_kill")
        elseif attacker.KillStreak == 3 then
            DMU.GiveMedal(attacker, "triple_kill")
        elseif attacker.KillStreak == 2 then
            DMU.GiveMedal(attacker, "double_kill")
        end

        -- Killing Sprees
        attacker.KillingSpree = (attacker.KillingSpree or 0) + 1

        if attacker.KillingSpree == 5 then
            DMU.GiveMedal(attacker, "killing_spree_5")
        elseif attacker.KillingSpree == 10 then
            DMU.GiveMedal(attacker, "killing_spree_10")
        elseif attacker.KillingSpree == 15 then
            DMU.GiveMedal(attacker, "killing_spree_15")
        elseif attacker.KillingSpree == 20 then
            DMU.GiveMedal(attacker, "killing_spree_20")
        elseif attacker.KillingSpree == 25 then
            DMU.GiveMedal(attacker, "killing_spree_25")
        end

        -- Premature Burial
        if !attacker:Alive() then
            DMU.GiveMedal(attacker, "premature_burial")
        end

        -- Collateral
        if attacker.Collateral then
            DMU.GiveMedal(attacker, "collateral")
        end

        attacker.Collateral = true

        timer.Simple(0, function()
            attacker.Collateral = nil
        end)
    end)
end

if CLIENT then
    local show_medals = CreateClientConVar("dmu_client_medals_enabled", "1", true, false, "", 0, 1)
    local medal_alpha = CreateClientConVar("dmu_client_medals_alpha", "225", true, false, "", 0, 255)
    local medal_scale = CreateClientConVar("dmu_client_medals_scale", "1", true, false, "")

    surface.CreateFont( "MedalFont", {font = "Roboto", size = 24 * medal_scale:GetFloat()})

    cvars.AddChangeCallback("dmu_client_medals_scale", function(convar, old_value, new_value)
        surface.CreateFont( "MedalFont", {font = "Roboto", size = 24 * tonumber(new_value)})
    end)

    local medals_to_display = {}

    local medal_fadein_timer = 0

    net.Receive("DMU_Medal", function()
        if not show_medals:GetBool() then return end
        local medal = net.ReadString()

        hook.Run("DMU_PlayerReceivedMedal", LocalPlayer(), medal)

        table.insert(medals_to_display, medal)

        timer.Simple(5, function()
            table.remove(medals_to_display, 1)
        end)

        medal_fadein_timer = CurTime() + 0.15
        surface.PlaySound("buttons/button9.wav")
    end)

    hook.Add("HUDPaint", "DMU_DrawMedals", function ()
        local alpha = medal_alpha:GetInt() * math.min(1, 1 - (medal_fadein_timer - CurTime()) / 0.15 )
        local color = ColorAlpha(color_white, alpha)
        local scale = medal_scale:GetFloat()

        local x = ScrW() / 2 - ((#medals_to_display-1) * 128 * scale) / 2
        local y = ScrH() / 5

        for k, v in ipairs(medals_to_display) do

            surface.SetDrawColor(color)
            surface.SetMaterial(DMU.Medals[v].Material)
            surface.DrawTexturedRect(x-40 * scale, y, 80 * scale, 80 * scale)


                draw.TextShadow({text = DMU.Medals[v].PrintName, font = "MedalFont", pos = {x, y + 96 * scale}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = color}, 2)


            x = x + 128 * scale
        end
    end)

end