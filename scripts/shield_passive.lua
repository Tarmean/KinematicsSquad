-- local inspect = require("inspect")
local Attack = Kinematics:require("curattack_tracker")
local utils = Kinematics:require("utils")
local Simulation = Kinematics:require("matrix")
Kinematics_Shield_Passive = Skill:new {
    Name = "Shield Stabilizer",
    Passive = "Kinematics_Shield_Passive",
    Icon = "weapons/kinematics_shield_stabilizer.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {2, 3},
    CustomTipImage = "Kinematics_Shield_Passive_Tooltip",
}
Kinematics_Shield_Passive_A = Kinematics_Shield_Passive:new {
    Passive = "Kinematics_Shield_Passive_A"
}
Kinematics_Shield_Passive_B = Kinematics_Shield_Passive:new {
    Passive = "Kinematics_Shield_Passive_B"
}
Kinematics_Shield_Passive_AB = Kinematics_Shield_Passive:new {
    Passive = "Kinematics_Shield_Passive_AB"
}
Kinematics_Shield_Passive_Tooltip = Skill:new {
    TipImage = {
        Unit = Point(2,3),
        Enemy = Point(2,1),
        Target=Point(2,1),
		CustomPawn = "ScienceMech"
    }
}


local function PassiveType()
    if IsPassiveSkill("Kinematics_Shield_Passive_AB") then
        return "Kinematics_PawnShield_AB"
    elseif IsPassiveSkill("Kinematics_Shield_Passive_A") then
        return "Kinematics_PawnShield_A"
    elseif IsPassiveSkill("Kinematics_Shield_Passive_B") then
        return "Kinematics_PawnShield_B"
    elseif IsPassiveSkill("Kinematics_Shield_Passive") then
        return "Kinematics_PawnShield"
    end
    return nil
end
function Kinematics_Shield_Passive.Activate(tiles, ret, source)
    local kind = PassiveType()

    if kind then
        Kinematics_Shield_Passive.SpawnShields(tiles, ret, kind, source)
    else
        Kinematics_Shield_Passive.ApplyShields(tiles, ret)
    end

end

function Kinematics_Shield_Passive.ApplyShields(tiles, ret)
    local damage = SpaceDamage()
    damage.iShield = 1
    for _, s in ipairs(tiles) do
        for _, t in ipairs(s) do
            damage.loc = t.Space
            ret:AddDamage(damage)
        end
    end
end
local hash_point = function (point)
    return point.x + 128 * point.y
end
function Kinematics_Shield_Passive.SpawnShields(tiles, ret, shield, source)
    local affected_tiles = {}
    local sim = Simulation:new()
    for _, s in ipairs(tiles) do
        for _, t in ipairs(s) do
            local new_space = t.Space + (DIR_VECTORS[t.Dir] or Point(0,0))
            if affected_tiles[hash_point(t.Space)] or affected_tiles[hash_point(new_space)] then
                affected_tiles = {}
                ret:AddDelay(FULL_DELAY)
            end
            local p = sim:PawnAt(t.Space)
            if p then
                affected_tiles[hash_point(t.Space)] = true
                affected_tiles[hash_point(new_space)] = true
                p:Shove(t.Dir)
                if p:GetSpace() ~= t.Space then
                    ret:AddCharge(Board:GetSimplePath(t.Space, p:GetSpace()), NO_DELAY)
                end
            end
            local damage = SpaceDamage(t.Space, DAMAGE_ZERO)
            if (t.Dir ~= DIR_NONE) then 
                damage.sAnimation = "airpush_"..t.Dir
            end
            if Board:IsValid(t.Space) then 
                ret:AddDamage(damage)
            end
        end
    end


    ret:AddDelay(FULL_DELAY)
    for _, s in ipairs(tiles) do
        local none_shielded = true
        for _, t in ipairs(s) do
            if Board:IsValid(t.Space) then 
                local dir = t.Dir
                if pawn_at_loc and pawn_at_loc:HasMoved() then
                    dir = DIR_NONE
                end
                local damage = SpaceDamage(t.Space, DAMAGE_ZERO, dir)
                local pawn_at_loc = sim:PawnAt(t.Space)

                local trigger_shield
                if sim:CheckSpaceFree(t.Space, PATH_GROUND) == Simulation.VALID then
                    -- SPAWN shield pawn
                    damage.sPawn = shield
                    trigger_shield = true
                    none_shielded = false
                elseif pawn_at_loc and (pawn_at_loc:GetType() == shield) then
                    -- HEAL already existing shield pawn
                    damage.iDamage = -2
                    damage.bHide = true
                    none_shielded = false
                elseif not pawn_at_loc or (pawn_at_loc:IsGuarding() and pawn_at_loc:IsPlayer()) then
                    -- SHIELD building/mountain or interactive 'building'
                    damage.iShield = EFFECT_CREATE
                    none_shielded = false
                end
                damage.sSound = "/props/shield_activated"
                ret:AddDamage(damage)
                if trigger_shield then
                    ret:AddScript("Kinematics_Shield_Passive.DoSpawn("..t.Space:GetString() .. ")")
                end
                ret:AddBounce(t.Space, -3)
            end
        end
        ret:AddDelay(none_shielded and NO_DELAY or FULL_DELAY)
    end
end

function Kinematics_Shield_Passive.DoSpawn(p)
    local pawn = Board:GetPawn(p)
    pawn:FireWeapon(p, 1)
end
function Kinematics_Shield_Passive_Tooltip:GetSkillEffect(p1, p2)
    return Science_Shield:GetSkillEffect(p1, p2)

end
function Kinematics_Shield_Passive_Tooltip:GetTargetArea(p1, p2)
    local ret = PointList()
    ret:push_back(Point(2,1))
    return ret
end

