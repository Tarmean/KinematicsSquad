local m = {}
function m.SafeDamage(pos, amount)
    local dam = SpaceDamage(pos, amount)
    if not Board:IsFire(pos) then
        dam.iFire = EFFECT_REMOVE
    end
    if not Board:IsSmoke(pos) then
        dam.iSmoke = EFFECT_REMOVE
    end
    dam.iTerrain = Board:GetTerrain(pos)

    return dam
end
return m
