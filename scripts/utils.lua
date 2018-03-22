local m = {}
function m.SafeDamage(pos, amount)
    local dam = SpaceDamage(pos, amount)
    local modTerrain = false
    if not Board:IsFire(pos) then
        dam.iFire = EFFECT_REMOVE
        modTerrain = true
    end
    if not Board:IsSmoke(pos) then
        dam.iSmoke = EFFECT_REMOVE
        modTerrain = true
    end
    if modTerrain then
        dam.iTerrain = Board:GetTerrain(pos)
    end

    return dam
end
return m
