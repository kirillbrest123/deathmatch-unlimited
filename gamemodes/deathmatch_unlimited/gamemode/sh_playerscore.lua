local plymeta = FindMetaTable("Player")

function plymeta:GetScore()
    return self:GetNWInt("score", 0)
end

function plymeta:SetScore(new_score)
    self:SetNWInt("score", score)
end

function plymeta:AddScore(increment)
    local score = self:GetScore() + increment
    self:SetNWInt("score", score)
end