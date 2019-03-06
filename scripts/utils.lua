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

local mod = {}
function mod.Pawns()
    local pawns = extract_table(Board:GetPawns(TEAM_ANY))
    for _, id in ipairs(pawns) do
        local pawn = Board:GetPawn(id)
        local output = string.format("%s: %x", pawn:GetSpace():GetString(), test.GetPawnAddr(pawn))
        LOG(output)
    end
end
local DamageableTerrain = {[TERRAIN_ICE] = true, [TERRAIN_MOUNTAIN] = true, [TERRAIN_SAND] = true, [TERRAIN_FOREST]=true}
function mod.SafeBase(pos, amount, hide)
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
    if not damaged and  DamageableTerrain[terrain] then
        local set_road = SpaceDamage(pos)
        set_road.iTerrain = TERRAIN_ROAD
        result[#result+1] = set_road
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
function mod.SafeDamage(pos, amount, hide, ret)
    for _, d in ipairs(mod.SafeBase(pos, amount, hide)) do
        ret:AddDamage(d)
    end
end
function mod.QueuedSafeDamage(pos, amount, ret)
    ret:AddQueuedScript("Kinematics.DamagePawnAt("..pos:GetString()..","..amount..")")
end
function Kinematics.DamagePawnAt(pos, amount)
    local pawn = Board:GetPawn(pos)
    if pawn then
        local oldHealth = pawn:GetHealth()
        if not pawn:IsShield() and not pawn:IsFrozen() and oldHealth <= amount then
            pawn:Kill(true)
        else
            test.SetHealth(pawn, oldHealth - amount)
        end
    end
end

local function ActiveWeapons_co()
    local ids = extract_table(Board:GetPawns(TEAM_PLAYER))
    for _, id in ipairs(ids) do
        if Board:IsPawnAlive(id) then
            local pawn = Board:GetPawn(id)
            local idx = 1
            local next_weapon = test.GetWeaponName(pawn, idx)
            while next_weapon do
                coroutine.yield(next_weapon)
                idx = idx + 1
                next_weapon = test.GetWeaponName(pawn, idx)
            end
        end
    end
end

-- yield all weapons of all player mechs
-- ignores movement (idx 0) and repair (idx 50)
function mod.ActiveWeapons()
    local co = coroutine.create(ActiveWeapons_co)
    return function()
        local code, res = coroutine.resume(co)
        return res
    end
end
return mod
