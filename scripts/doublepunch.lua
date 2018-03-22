-- log = require "log"
-- log.level = "warn"
-- local inspect = require("inspect")


-- statemachine for the conga
local Tracked = {}
local ST_ACTIVE = 0 -- in the conga
local ST_DROPPED = 1 -- fell into a hole
local ST_PUSHED = 2 -- run into an immovable obstacle, acts as an immovable obstacle itself now
local ST_PAUSED = 3 -- temporarily paused until the conga catches up

Prime_Pushmech = Skill:new{  
	Class = "Science",
	Icon = "weapons/prime_punchmech.png",
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

    
    local state0 = Tracked:New(p1, dirv)
    local final_state = state0:GetPositions(self.PathSize)

    for i = #final_state, 1, -1 do
        ret:AddDelay(FULL_DELAY)
        local p = final_state[i]
        local moved = p.path:size() > 1
        if moved then
            ret:AddSound("/weapons/charge")

            Prime_Pushmech.AddTrail(p1, p.orig_pos, ret)

            Prime_Pushmech.DoAction(p, ret)

            Prime_Pushmech.AddTrail(p.orig_pos, p.pos, ret)
            for j = i, #final_state do
                local p = final_state[j]
                ret:AddBounce(p.pos, -5)
                ret:AddEmitter(p.pos, "Emitter_Burst")
            end
            if p.state ~= ST_DROPPED then
                ret:AddBoardShake(0.5)
                ret:AddSound("/impact/generic/explosion")
            end
        end
    end


    return ret
end
function Prime_Pushmech.DoAction(p, ret)
    if p.state == ST_DROPPED then
        -- this abuses a bug in the preview code
        -- the preview shows the unit dieing from DAMAGE_DEATH, the execution shows the unit diving charging to its death
        ret:AddCharge(p.path, NO_DELAY)
        local damage = SpaceDamage(p.orig_pos, DAMAGE_DEATH)
        ret:AddDamage(damage)
    else
        -- we do the damage at orig_pos because WEIRD THINGS happen to the preview if we damage at pos.
        -- this sucks because fires and smoke icons are visible when we suppress them
        ret:AddCharge(p.path, NO_DELAY)
    end
end

function Prime_Pushmech.AddTrail(from, to, ret)
    -- local path = extract_table(tracked.path)
    local dir = GetDirection(to-from)
    for p in PointIter(from, to) do
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
        if i > 0 then
            cur = cur + dirv
            i = i - 1
            return cur
        end
    end
end


function Tracked:GetPositions(left)
    -- The inner loop steps each unit in the conga by one tile. If the conga changes we break which runs self:Setup() and retries
    -- the outer loop repeats this until every unit is blocked (ST_PUSHED), seperated (ST_PAUSED) or killed (ST_DROPPED)
    while left > 0 and not self:Done() do
        self:Setup()
        for i = #self, 1, -1 do
            local pawn = self[i]

            if self:Interacts(pawn) then
                local next_pos = pawn.pos + self.dirv
                local succ =  self:GetKnown(next_pos)
                local next_pawn = self:GetUnknown(next_pos)
                local invalid_terr = self:CheckTerrain(pawn.pathprof, next_pos)
                if succ then
                    if succ.state == ST_PAUSED then
                        -- a unit in the middle of the conga dropped, splitting the conga in two
                        -- now we cought up so we setup to reintegrate the conga head
                        break
                    else
                        -- units that collided act as terrain so we stop here
                        pawn.state = ST_PUSHED
                    end
                elseif next_pawn then
                    -- unit we didn't see before so we setup
                    break
                elseif invalid_terr == TERR_COLLISION then
                    pawn.state = ST_PUSHED
                elseif invalid_terr == TERR_DROPPED then
                    pawn.state = ST_DROPPED
                end
                if pawn.state ~= ST_PUSHED then
                    pawn.pos = next_pos
                    pawn.path:push_back(next_pos)
                end
                if pawn.state == ST_DROPPED then
                    -- some part of the conga dropped so we setup
                    break
                end
            end
            if i == 1 then
                left = left - 1
            end
        end
    end
    return self
end

Tracked.__index = Tracked
function Tracked:New(p0, dirv)
    local o = {}
    setmetatable(o, self)
    o[1] = Tracked.mkMarker(Board:GetPawn(p0))
    o.obstacles = {}
    o.dirv = dirv
    return o
end
function Tracked:Interacts(p)
    return p.state == ST_ACTIVE
end
function Tracked:Alive(p)
    return (p.state ~= ST_DROPPED) and not p.dead
end
function Tracked:Done()
    local pred = function(p)
        return not self:Interacts(p)
    end
    local all_stopped = all(self,  pred)
    return all_stopped or self:CheckTerrain(self[1].pathprof, self[1].pos + self.dirv)
end
function Tracked:GetKnown(p)
    return findBy(self, function(x) return (x.pos == p) and self:Alive(x) end)
end
function Tracked:GetUnknown(p)
    local board_pawn = Board:GetPawn(p)
    return board_pawn and self:Unknown(board_pawn) and board_pawn
end
function Tracked:Unknown(pawn)
    local id = pawn:GetId()
    return all(self, function(p) return p.id ~= id end)
end
function Tracked:Get(p)
    local r = self:GetKnown(p) 
    if r then
        return r
    end
    r = self:GetUnknown(p)
    if r then
        r = Tracked.mkMarker(r)
        self[#self+1] = r
        return r
    end
    return nil
end

-- called whenever the conga changes
function Tracked:Setup()
    for _,v in ipairs(self) do
        if v.state == ST_ACTIVE then
            v.state = ST_PAUSED
        end
    end

    local current = self[1]
    while current do
        if current.state == ST_PAUSED then
            current.state = ST_ACTIVE
        elseif current.state == ST_PUSHED then
            break
        end
        current = self:Get(current.pos + self.dirv)
    end
end

function all(ls, pred)
    for _, y in ipairs(ls) do
        if not pred(y) then
            return false
        end
    end
    return true
end
function findBy(ls, pred) 
    for _, y in ipairs(ls) do
        if pred(y) then
            return y
        end
    end
    return nil
end

function Tracked.mkMarker(pawn)
    local list = PointList()
    local pos = pawn:GetSpace()
    list:push_back(pos)
    local state = pawn:IsGuarding() and ST_PUSHED or ST_ACTIVE
    local o = { pos = pos, dead =  false,  orig_pos = pos, id = pawn:GetId(), pathprof = pawn:GetPathProf(), state = state, path = list}
    return o
end


TERR_COLLISION = 1
TERR_DROPPED = 2
local PATH_LEAPER = 6
INVALID_TERRAINS =
    { [PATH_FLYER] = -- 1
        { [TERRAIN_BUILDING] = TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = TERR_COLLISION
        }
    , [PATH_GROUND] = -- 0
        { [TERRAIN_BUILDING] = TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = TERR_COLLISION
        , [TERRAIN_ACID] = TERR_DROPPED
        , [TERRAIN_HOLE] = TERR_DROPPED
        , [TERRAIN_LAVA] = TERR_DROPPED
        , [TERRAIN_WATER] = TERR_DROPPED
        }
    , [PATH_LEAPER] = -- 6
        { [TERRAIN_BUILDING] = TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = TERR_COLLISION
        , [TERRAIN_ACID] = TERR_DROPPED
        , [TERRAIN_HOLE] = TERR_DROPPED
        , [TERRAIN_LAVA] = TERR_DROPPED
        , [TERRAIN_WATER] = TERR_DROPPED
        }
    , [PATH_MASSIVE] = -- 2
        { [TERRAIN_BUILDING] = TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = TERR_COLLISION
        , [TERRAIN_HOLE]     = TERR_COLLISION
        }
    , [PATH_PHASING] = {} -- 9
    , [PATH_PROJECTILE] = -- 3
        { [TERRAIN_BUILDING] = TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = TERR_COLLISION
        }
    , [PATH_ROADRUNNER] = -- 4
        { [TERRAIN_BUILDING] = TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = TERR_COLLISION
        , [TERRAIN_HOLE] = TERR_COLLISION
        }
    }

function Tracked:CheckTerrain(path, pos)
    local result = InvalidTerrain(pos, path)
    if result == TERR_COLLISION then
        self.obstacles[#self.obstacles+1] = pos
    end
    return result
end
-- Maybe seperate this? It isn't super useful without the unit tracking, though
function InvalidTerrain(pos, pathtype)
    local pathtype = pathtype % 16

    if not Board:IsValid(pos) then
        return TERR_COLLISION
    end
    local table = INVALID_TERRAINS[pathtype] 
    if not table then
        table = INVALID_TERRAINS[PATH_GROUND]
    end
    local terr = Board:GetTerrain(pos)
    return table[terr]
end


