-- local inspect = require("inspect")
local utils = Kinematics:require("utils")
local Simulation = Kinematics:require("matrix")
Kinematics_Shield_Passive = Skill:new {
    Name = "Shield Stabilizer",
    Passive = "Flame_Immune",
    Icon = "weapons/kinematics_shield_stabilizer.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {2, 3}
}
Kinematics_Shield_Passive_A = Kinematics_Shield_Passive:new {}
Kinematics_Shield_Passive_B = Kinematics_Shield_Passive:new {}
Kinematics_Shield_Passive_AB = Kinematics_Shield_Passive:new {}


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
            if not sim:PawnAt(t.Space) then
                local terr = sim:TerrainAt(t.Space)
                if terr ~= TERRAIN_HOLE and terr ~= TERRAIN_ACID and terr ~= TERRAIN_LAVA and terr ~= TERRAIN_WATER then
                    damage.sImageMark = "combat/shield_front.png"
                end
            end
            if (t.Dir ~= DIR_NONE) then 
                damage.sAnimation = "airpush_"..t.Dir
            end
            ret:AddDamage(damage)
        end
    end

    ret:AddDelay(FULL_DELAY)
    for outer_index, s in ipairs(tiles) do
        local none_shielded = true
        for _, t in ipairs(s) do
            local pawn_at_loc = sim:PawnAt(t.Space)
            local dir = t.Dir
            if pawn_at_loc and pawn_at_loc:HasMoved() then
                dir = DIR_NONE
            end
            local damage = SpaceDamage(t.Space, DAMAGE_ZERO, dir)
            if not pawn_at_loc then
                none_shielded = false
                local terr = sim:TerrainAt(t.Space)
                if terr ~= TERRAIN_HOLE and terr ~= TERRAIN_ACID and terr ~= TERRAIN_LAVA and terr ~= TERRAIN_WATER then
                    damage.sImageMark = "combat/shield_front.png"
                end
            end
            ret:AddDamage(damage)
            Kinematics_Shield_Passive.DoShield(t.Space, ret, shield)
        end
        ret:AddDelay(none_shielded and NO_DELAY or FULL_DELAY)
    end
end

function Kinematics_Shield_Passive.DoShield(p, ret, shield)
    local damage = SpaceDamage(p)
    damage.sScript = "Kinematics_Shield_Passive.DoSpawn("..p:GetString() .. ",\""..shield.."\")"
    damage.sSound = "/props/shield_activated"
    ret:AddDamage(damage)
    ret:AddBounce(p, -3)
end
function Kinematics_Shield_Passive.DoSpawn(p, shield)
    if not Board:IsBlocked(p, PATH_GROUND) then
        local pawn = PAWN_FACTORY:CreatePawn(shield)
        Board:AddPawn(pawn, p)
        pawn:FireWeapon(p, 1)
    else 
        local pawn = Board:GetPawn(p)
        if not pawn or (pawn:IsGuarding() and pawn:IsPlayer()) then
            local dam = SpaceDamage(p)
            dam.iShield = 1
            Board:DamageSpace(dam)
        elseif pawn:GetType() == shield then
            local dam = SpaceDamage(p, -2)
            Board:DamageSpace(dam)
        end
    end
end
