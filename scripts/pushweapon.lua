local utils = Kinematics:require("utils")
local Simulation = Kinematics:require("matrix")
local Attack = Kinematics:require("curattack_tracker")
Kinematics_Prime_PushWeapon = Skill:new{  
    Class = "Science",
    Name = "Push",
    Icon = "weapons/support_wind.png",
    Rarity = 3,
    Explosion = "",
    -- LaunchSound = "/weapons/titan_fist",
    Range = 1, -- Tooltip?
    PathSize = INT_MAX,
    Damage = 0,
    PushBack = false,
    Flip = false,
    Dash = false,
    Shield = false,
    Projectile = false,
    Push = 1, --Mostly for tooltip, but you could turn it off for some unknown reason
    PowerCost = 1,
    Upgrades = 0,
    --UpgradeList = { "Dash",  "+2 Damage"  },
    UpgradeCost = { 2 , 3 },
    TipImage = StandardTips.Melee
}

local function RecursivePush(pawn, dir, sim)
    if pawn:IsGuarding() then
        return false
    end
    local pos = pawn:GetSpace()
    local new_pos = pos + dir
    local move_typ = pawn:SetSpace(new_pos)
    if move_typ == Simulation.UNIT_COLLISION then
        local collision_pawn = sim:PawnAt(new_pos)
        return RecursivePush(collision_pawn, dir, sim)
    end
    return move_typ == Simulation.VALID or move_typ == Simulation.DROPPED
end
local function BasePush(pos, dir)
    local cur = pos
    local sim = Simulation:new()
    local p = sim:PawnAt(pos)
    while RecursivePush(p, dir, sim) do end
    return sim
end
 
function Kinematics_Prime_PushWeapon:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    local dir = GetDirection(p2 - p1)
    local dirv = DIR_VECTORS[dir]

    local sim = BasePush(p1, dirv)
    Attack:SetSim(p1, sim)
    local final_state = sim.sim_pawns

    for i = #final_state, 1, -1 do
        ret:AddDelay(FULL_DELAY)
        local p = final_state[i]
        local moved = p:HasMoved()
        if moved then
            ret:AddSound("/weapons/charge")

            Kinematics_Prime_PushWeapon.AddTrail(p1, p:GetOriginalSpace(), ret)

            Kinematics_Prime_PushWeapon.DoAction(p, ret)

            Kinematics_Prime_PushWeapon.AddTrail(p:GetOriginalSpace(), p:GetSpace(), ret)
            for j = i, #final_state do
                local p = final_state[j]
                if p:IsAlive() then
                    ret:AddBounce(p:GetSpace(), -5)
                    ret:AddEmitter(p:GetSpace(), "Emitter_Burst")
                end
            end
            if p:IsAlive() then
                ret:AddBoardShake(0.5)
                ret:AddSound("/impact/generic/explosion")
            end
        end
    end

    return ret
end
function Kinematics_Prime_PushWeapon.DoAction(p, ret)
    local path = PointList()

    for p in PointIter(p:GetOriginalSpace(), p:GetSpace()) do
        path:push_back(p)
    end
    if not p:IsAlive() then
        -- this abuses a bug in the preview code
        -- the preview shows the unit dieing from DAMAGE_DEATH, the execution shows the unit diving charging to its death
        ret:AddCharge(path, NO_DELAY)
        utils.SafeDamage(p:GetOriginalSpace(), DAMAGE_DEATH, false, ret)
    else
        -- we do the damage at orig_pos because WEIRD THINGS happen to the preview if we damage at pos.
        -- this sucks because fires and smoke icons are visible when we suppress them
        ret:AddCharge(path, NO_DELAY)
    end
end

function Kinematics_Prime_PushWeapon.AddTrail(from, to, ret)
    local dir = GetDirection(to-from)
    local from_plus_one = from+(DIR_VECTORS[dir] or Point(0,0))
    for p in PointIter(from_plus_one, to) do
        ret:AddBounce(p, -3)
        -- local damage = SpaceDamage(p, 0)
        ret:AddAnimation(p, "exploout0_"..(dir)%4)
        ret:AddDelay(0.06)
    end
end

function PointIter(from, to)
    local i = from:Manhattan(to)
    local dir = GetDirection(to - from)
    local dirv = DIR_VECTORS[dir] or Point(0,0)
    local cur = from
    return function()
        if i >= 0 then
            out = cur
            cur = cur + dirv
            i = i - 1
            return out
        end
    end
end


