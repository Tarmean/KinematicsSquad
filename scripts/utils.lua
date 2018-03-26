-- TERRAIN_ACID     12
-- TERRAIN_BUILDING 1
-- TERRAIN_FIRE     11
-- TERRAIN_FOREST   6
-- TERRAIN_HOLE     9
-- TERRAIN_ICE      5
-- TERRAIN_LAVA     14
-- TERRAIN_MOUNTAIN 4
-- TERRAIN_ROAD     0
-- TERRAIN_RUBBLE   2
-- TERRAIN_SAND     7
-- TERRAIN_WATER    3

local DamageableTerrain = {[TERRAIN_ICE] = true, [TERRAIN_MOUNTAIN] = true, [TERRAIN_SAND] = true, [TERRAIN_FOREST]=true}
function SafeBase(pos, amount, hide)
    local result = {}

    if amount == DAMAGE_ZERO or amount == 0 then
        return result
    end

    local terrain = Board:GetTerrain(pos)
    if terrain == TERRAIN_BUILDING then
        -- buildings don't reset health when re-setting iterrain 
        -- but they shouldn't overlap with units anyway
        return result
    end

    local damaged = Board:IsDamaged(pos)
    if damaged then
        -- damaged ice/mountains are healed BEFORE we attack
        -- then our damage triggers and brings them back down to 1 health
        local dam = SpaceDamage(pos, DAMAGE_ZERO)
        dam.bHide= true
        dam.bHidePath= true
        dam.iTerrain = Board:GetTerrain(pos)
        result = {dam}
    end

    local dam = SpaceDamage(pos, amount)
    if hide then
        dam.bHide= true
        dam.bHidePath= true
    end
    -- iTerrain doesn't remove the cloud
    if not Board:IsSmoke(pos) then
        dam.iSmoke = EFFECT_REMOVE
    end
    -- If a pawn stands on a forest we have to extinguish them as well
    if not Board:IsFire(pos) then
        dam.iFire = EFFECT_REMOVE
    end
    if  (not damaged) and DamageableTerrain[terrain] then
        -- this heals damageable terrain back up. This includes sand
        dam.iTerrain = terrain
    end
    result[#result+1] = dam

    return result
end


-- Is there a less ugly way? cps everything? use coroutines?
function SafeDamage(pos, amount, hide, ret)
    for _, d in ipairs(SafeBase(pos, amount, hide)) do
        ret:AddDamage(d)
    end
end
function QueuedSafeDamage(pos, amount, hide, ret)
    for _, d in ipairs(SafeBase(pos, amount, hide)) do
        ret:AddQueuedDamage(d)
    end
end
