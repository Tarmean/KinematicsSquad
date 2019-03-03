Prime_Pushmech = Skill:new{  
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
 
function Prime_Pushmech:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    local dir = GetDirection(p2 - p1)
    local dirv = DIR_VECTORS[dir]

    
    local final_state = BasePush(p1, dirv)

    for i = #final_state, 1, -1 do
        ret:AddDelay(FULL_DELAY)
        local p = final_state[i]
        local moved = p:HasMoved()
        if moved then
            ret:AddSound("/weapons/charge")

            Prime_Pushmech.AddTrail(p1, p:GetOriginalSpace(), ret)

            Prime_Pushmech.DoAction(p, ret)

            Prime_Pushmech.AddTrail(p:GetOriginalSpace(), p:GetSpace(), ret)
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
function Prime_Pushmech.DoAction(p, ret)
    local path = PointList()

    for p in PointIter(p:GetOriginalSpace(), p:GetSpace()) do
        path:push_back(p)
    end
    if not p:IsAlive() then
        -- this abuses a bug in the preview code
        -- the preview shows the unit dieing from DAMAGE_DEATH, the execution shows the unit diving charging to its death
        ret:AddCharge(path, NO_DELAY)
        SafeDamage(p:GetOriginalSpace(), DAMAGE_DEATH, false, ret)
    else
        -- we do the damage at orig_pos because WEIRD THINGS happen to the preview if we damage at pos.
        -- this sucks because fires and smoke icons are visible when we suppress them
        ret:AddCharge(path, NO_DELAY)
    end
end

function Prime_Pushmech.AddTrail(from, to, ret)
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


function BasePush(pos, dir)
    local cur = pos
    local sim = Simulation:new()
    local p = sim:PawnAt(pos)
    while RecursivePush(p:GetId(), dir, sim) do end
    return sim.sim_pawns
end
function RecursivePush(id, dir, sim)
    local p = sim:PawnWithId(id)
    local pos = p:GetSpace()
    local new_pos = pos + dir
    local move_typ = p:SetSpace(new_pos)
    local mov_types = {[1]="collision", [2]= "terr_collision", [3]= "dropped", [4]= "valid", [5]= "oob"}
    local result = false
    if move_typ == ProxyPawn.UNIT_COLLISION then
        local collision_pawn = sim:PawnAt(new_pos)
        return RecursivePush(collision_pawn:GetId(), dir, sim)
    elseif move_typ == ProxyPawn.VALID or move_typ == ProxyPawn.DROPPED then
        return true
    end
    return false
end
