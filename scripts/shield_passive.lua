-- local inspect = require("inspect")
local utils = Kinematics:require("utils")
local Simulation = Kinematics:require("matrix")
Kinematics_Shield_Passive = Skill:new {
    Name = "Shield Stabilizer",
    Passive = "Flame_Immune",
    Icon = "weapons/kinematics_shield_stabilizer.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {2, 3},
    CustomTipImage = "Kinematics_Shield_Passive_Tooltip",
}
Kinematics_Shield_Passive_A = Kinematics_Shield_Passive:new {}
Kinematics_Shield_Passive_B = Kinematics_Shield_Passive:new {}
Kinematics_Shield_Passive_AB = Kinematics_Shield_Passive:new {}
Kinematics_Shield_Passive_Tooltip = Skill:new {
    TipImage = {
        Unit = Point(2,3),
        Enemy = Point(2,1),
        Target=Point(2,1),
		CustomPawn = "ScienceMech"
    }
}


local function PassiveType()
    for s in utils.ActiveWeapons() do
        if s == "Kinematics_Shield_Passive" then
            return "Kinematics_PawnShield"
        elseif s == "Kinematics_Shield_Passive_A" then
            return "Kinematics_PawnShield_A"
        elseif s == "Kinematics_Shield_Passive_B" then
            return "Kinematics_PawnShield_B"
        elseif s == "Kinematics_Shield_Passive_AB" then
            return "Kinematics_PawnShield_AB"
        end
    end
    return nil
end
function Kinematics_Shield_Passive.Activate(tiles, ret)
    local kind = PassiveType()

    if kind then
        Kinematics_Shield_Passive.SpawnShields(tiles, ret, kind)
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
function Kinematics_Shield_Passive.SpawnShields(tiles, ret, shield)
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
            local pawn_at_loc = sim:PawnAt(t.Space)

            local action
            if sim:CheckSpaceFree(t.Space, PATH_GROUND) == Simulation.VALID then
                action = "SPAWN"
            elseif pawn_at_loc and pawn_at_loc:GetType() == shield then
                action = "HEAL"
            elseif not pawn_at_loc or (pawn_at_loc:IsGuarding() and pawn_at_loc:IsPlayer()) then
                action = "SHIELD"
            else
                action = "NONE"
            end
            local dir = t.Dir
            if pawn_at_loc and pawn_at_loc:HasMoved() then
                dir = DIR_NONE
            end
            local damage = SpaceDamage(t.Space, DAMAGE_ZERO, dir)
            if action == "SPAWN" or action == "SHIELD" then
                local terr = sim:TerrainAt(t.Space)
                if terr ~= TERRAIN_HOLE and terr ~= TERRAIN_ACID and terr ~= TERRAIN_LAVA and terr ~= TERRAIN_WATER then
                    none_shielded = false
                    damage.sImageMark = "combat/shield_front.png"
                end
            end
            if Board:IsValid(t.Space) then 
                ret:AddDamage(damage)
                Kinematics_Shield_Passive.DoShield(t.Space, ret, shield, action)
            end
        end
        ret:AddDelay(none_shielded and NO_DELAY or FULL_DELAY)
    end
end

function Kinematics_Shield_Passive.DoShield(p, ret, shield, action)
    local damage = SpaceDamage(p)
    damage.sScript = "Kinematics_Shield_Passive.DoSpawn("..p:GetString() .. ",\""..shield.."\",\"" .. action .."\")"
    LOG(damage.sScript)
    damage.sSound = "/props/shield_activated"
    ret:AddDamage(damage)
    ret:AddBounce(p, -3)
end
function Kinematics_Shield_Passive.DoSpawn(p, shield, action)
    if action == "SPAWN" then
        local pawn = PAWN_FACTORY:CreatePawn(shield)
        Board:AddPawn(pawn, p)
        pawn:FireWeapon(p, 1)
    elseif action == "SHIELD" then
        local dam = SpaceDamage(p)
        dam.iShield = 1
        Board:DamageSpace(dam)
    elseif action == "HEAL" then
        local dam = SpaceDamage(p, -2)
        Board:DamageSpace(dam)
    end
end
function Kinematics_Shield_Passive_Tooltip:GetSkillEffect(p1, p2)
    if not PassiveType() then
        Board:GetPawn(p1):AddWeapon("Kinematics_Shield_Passive")
    end
    return Science_Shield:GetSkillEffect(p1, p2)

end
function Kinematics_Shield_Passive_Tooltip:GetTargetArea(p1, p2)
    local ret = PointList()
    ret:push_back(Point(2,1))
    return ret
end

