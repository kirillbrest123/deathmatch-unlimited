util.AddNetworkString("DMU_SyncRound")
util.AddNetworkString("DMU_SyncTimeLeft")
util.AddNetworkString("DMU_RoundVictoryAnnouncement")

function DMU.StartNextRound()
    DMU.Round = DMU.Round + 1

    net.Start("DMU_SyncRound")
        net.WriteUInt(DMU.Round,8)
    net.Broadcast()

    game.CleanUpMap( false, { "env_fire", "entityflame", "_firesmoke" } )
    DMU.ReplaceMapEntities()

    hook.Run("DMU_PreRoundStart")

    for _, ply in ipairs(player.GetAll()) do
        if !DMU.Mode.FFA and ply:Team() == TEAM_UNASSIGNED then continue end -- don't respawn players who didn't choice their team yet
        ply:StripWeapons() -- maybe we need to use DMU.Mode.Teams here?
        ply:RemoveAllAmmo() -- i'm a bit confused. it can potentially cause problems with game modes like round-based juggernaut or smth
        ply:Spawn() -- does it even matter??
        ply:Freeze(true)
    end

    timer.Simple(1, function()
        DMU.SendAnnouncement("Round starting", 2, "fvox/bell.wav")
    end)
    timer.Simple(3, function()
        DMU.SendAnnouncement("3", 1, "fvox/three.wav")
    end)
    timer.Simple(4, function()
        DMU.SendAnnouncement("2", 1, "fvox/two.wav")
    end)
    timer.Simple(5, function()
        DMU.SendAnnouncement("1", 1, "fvox/one.wav")
    end)


    timer.Simple(6, function()
        DMU.RoundEnded = false

        for _, ply in ipairs(player.GetAll()) do
            ply:Freeze(false)
        end

        if DMU.Mode.TimeLimit then
            DMU.CurTimeLimit = DMU.Mode.TimeLimit + CurTime()
            net.Start("DMU_SyncTimeLeft")
                net.WriteUInt(DMU.CurTimeLimit, 32)
            net.Broadcast()
        end

        hook.Run("DMU_RoundStart")
    end)
end

function DMU.EndRound(winner)

    DMU.RoundEnded = true

    if !winner then
        net.Start("DMU_RoundVictoryAnnouncement")
            net.WriteUInt(0, 13)
        net.Broadcast()
    else
        if isentity(winner) then
            winner = winner:EntIndex()
        end

        net.Start("DMU_RoundVictoryAnnouncement")
            net.WriteUInt(winner + 1, 13)
        net.Broadcast()
    end

    hook.Run("DMU_RoundEnd", winner)

    timer.Simple(10, function()
        if DMU.Round >= DMU.Mode.RoundLimit and !DMU.GameEnded then
            DMU.EndGame()
            return
        end
        DMU.StartNextRound()
    end)
end

hook.Add("player_activate", "DMU_InitialRoundSync", function(ply)
    timer.Simple(1, function()
        if DMU.Round then
            net.Start("DMU_SyncRound")
                net.WriteUInt(DMU.Round,8)
            net.Send(ply)
        end
        if DMU.Mode.TimeLimit then
            net.Start("DMU_SyncTimeLeft")
                net.WriteUInt(DMU.CurTimeLimit, 32)
            net.Send(ply)
        end
    end)
end)