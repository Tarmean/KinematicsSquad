-- local inspect = require("inspect")
local Simulation = {
    UNIT_COLLISION = 1,
    TERR_COLLISION = 2,
    DROPPED = 3,
    VALID = 4,
    OOB = 5,
    GUARDING = 6,
    -- This is for the extra space of trains and dams
    -- for now we treat ExtraSpaces as terrain
    TERRAIN_EXTRA_SPACE = 902
}
local MoveStateRev = {
    [Simulation.UNIT_COLLISION] = "UNIT_COLLISION",
    [Simulation.TERR_COLLISION] = "TERR_COLLISION",
    [Simulation.DROPPED] = "DROPPED",
    [Simulation.VALID] = "VALID",
    [Simulation.OOB] = "OOB",
    [Simulation.GUARDING] = "GUARDING",
    [Simulation.TERRAIN_EXTRA_SPACE] = "TERRAIN_EXTRA_SPACE"
}

local ProxyPawn = {}

function Simulation:Setup()
    self.sim_pawns = {}
    self.sim_terrain = {}
    self.locked_attributes = {}
end
function Simulation:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  o:Setup()
  return o
end
function Simulation:_IsPawnNew(pawn)
    local p_id = pawn:GetId()
    for _, v in ipairs(self.sim_pawns) do
        if v:GetId() == p_id then
            return false
        end
    end
    return true
end
function Simulation:_AddPawnFromIdent(identifier)
    local new_pawn = Board:GetPawn(identifier)
    if not new_pawn then return end
    if not self:_IsPawnNew(new_pawn) then return end
    local new_pawn_proxy = ProxyPawn:new(new_pawn, self)
    self.sim_pawns[#self.sim_pawns+1] = new_pawn_proxy
    return new_pawn_proxy
end
function Simulation:TerrainAt(position)
    if not self.sim_terrain[position] then
        local pawn_at_space = Board:GetPawn(position)
        if pawn_at_space and pawn_at_space:GetSpace() ~= position then
            self.sim_terrain[position] = Simulation.TERRAIN_EXTRA_SPACE
        else
            self.sim_terrain[position] = Board:GetTerrain(position)
        end
    end
    return self.sim_terrain[position]
end
function Simulation:StartTimeStep()
    self.locked_attributes = {}
    self.transaction_id = 1
end
function Simulation:NewTransaction()
    if not self.transaction_id then
        self:StartTimeStep()
    else
        self.transaction_id = self.transaction_id + 1
    end
end
function Simulation:CommitTimeStep()
    if not self.transaction_id then return end
    self.transaction_id = nil
    local out = ""
    for pawn, entry in pairs(self.locked_attributes) do
        for attribute, data in pairs(entry) do
            if data.write_lock then
                -- out = out .. "\n    " .. pawn:GetType() .. "[" .. attribute .. "] = " .. inspect(data.write_lock.value)
                pawn.data[attribute] = data.write_lock.value
            end
        end
    end
    if out ~= "" then
        LOG("Commit time step:".. out)
    end
    self.locked_attributes = nil
end

function Simulation:AddPawn(ident, space)
    local p = PAWN_FACTORY:CreatePawn(ident)
    local new_pawn = ProxyPawn:new(p, self, {space = space})
    self.sim_pawns[#self.sim_pawns+1] = new_pawn
    return new_pawn
end
function Simulation:PawnAt(position)
    local id = self.transaction_id
    self.transaction_id = nil
    for _, v in ipairs(self.sim_pawns) do
        if v:IsAlive() and (v:GetSpace() == position) then
            self.transaction_id = id
            return v
        end
    end
    self.transaction_id = id
    return self:_AddPawnFromIdent(position)
end
function Simulation:PawnWithId(pawn_id)
    for _, v in ipairs(self.sim_pawns) do
        if v:GetId() == pawn_id then
            return v
        end
    end
    return self:_AddPawnFromIdent(pawn_id)
end
function Simulation:RunSkillEffect(skill_eff)
    LOG("sim")
    local dmg_list = skill_eff.effect
    if not dmg_list then return end
    for i = 1, dmg_list:size() do
        self:RunSpaceDamage(dmg_list, i)
    end
    self:CommitTimeStep()
    self:Summary()
end
function Simulation:Summary()
    for _, p in ipairs(self.sim_pawns) do
        LOG("pawn: " .. p:GetType() .. ", " .. p:GetSpace():GetString() .. ", alive: " .. tostring(p:IsAlive()))
    end
end
function Simulation:RunSpaceDamage(dmg_list, i)
    self:NewTransaction()
    local dmg = dmg_list:index(i)
    -- we want our simulation to match the preview
    -- if dmg.bHide then return end
    local loc = dmg.loc
    local p_dmg = self:PawnAt(loc)
    if p_dmg then
        if dmg.iDamage == DAMAGE_DEATH then
            LOG("simulation damage_death at " .. loc:GetString())
            -- DAMAGE_DEATH ignores shields and so on
            p_dmg:GetSpace()
            p_dmg:Kill()
        elseif dmg.iDamage > 0 and dmg.iDamage ~= DAMAGE_ZERO then
            LOG("simulation damage at " .. loc:GetString() .. " by " .. dmg.iDamage)
            p_dmg:GetSpace()
            p_dmg:DamageBy(dmg.iDamage)
        end
        if dmg.iPush ~= DIR_NONE then
            local res = p_dmg:Shove(dmg.iPush)
            LOG("Simulated shove at " .. loc:GetString()  ..  " to " .. dmg.iPush .. " with result " .. MoveStateRev[res])
        end
    end
    if dmg.sPawn ~= "" then
        LOG("Simulated spawn of " .. dmg.sPawn .. " at " .. dmg.loc:GetString())
        self:AddPawn(dmg.sPawn, dmg.loc)
    end
    local p_move = self:PawnAt(dmg:MoveStart())
    if p_move then
        LOG("Simulated movement  of " .. dmg:MoveStart():GetString() .. "->" .. dmg:MoveEnd():GetString())
        p_move:SetSpaceIgnoringCollisions(dmg:MoveEnd())
    end
    if dmg.fDelay ~= 0 then
        -- LOG("Committing with delay " .. dmg.fDelay)
        self:CommitTimeStep()
    end
end
local PATH_LEAPER = 6
local INVALID_TERRAINS =
    { [PATH_FLYER] = -- 1
        { [TERRAIN_BUILDING] = Simulation.TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = Simulation.TERR_COLLISION
        , [Simulation.TERRAIN_EXTRA_SPACE] = Simulation.TERR_COLLISION
        }
    , [PATH_GROUND] = -- 0
        { [TERRAIN_BUILDING] = Simulation.TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = Simulation.TERR_COLLISION
        , [TERRAIN_ACID] = Simulation.DROPPED
        , [TERRAIN_HOLE] = Simulation.DROPPED
        , [TERRAIN_LAVA] = Simulation.DROPPED
        , [TERRAIN_WATER] = Simulation.DROPPED
        , [Simulation.TERRAIN_EXTRA_SPACE] = Simulation.TERR_COLLISION
        }
    , [PATH_LEAPER] = -- 6
        { [TERRAIN_BUILDING] = Simulation.TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = Simulation.TERR_COLLISION
        , [TERRAIN_ACID] = Simulation.DROPPED
        , [TERRAIN_HOLE] = Simulation.DROPPED
        , [TERRAIN_LAVA] = Simulation.DROPPED
        , [TERRAIN_WATER] = Simulation.DROPPED
        , [Simulation.TERRAIN_EXTRA_SPACE] = Simulation.TERR_COLLISION
        }
    , [PATH_MASSIVE] = -- 2
        { [TERRAIN_BUILDING] = Simulation.TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = Simulation.TERR_COLLISION
        , [TERRAIN_HOLE]     = Simulation.TERR_COLLISION
        , [Simulation.TERRAIN_EXTRA_SPACE] = Simulation.TERR_COLLISION
        }
    , [PATH_PHASING] = {} -- 9
    , [PATH_PROJECTILE] = -- 3
        { [TERRAIN_BUILDING] = Simulation.TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = Simulation.TERR_COLLISION
        , [Simulation.TERRAIN_EXTRA_SPACE] = Simulation.TERR_COLLISION
        }
    , [PATH_ROADRUNNER] = -- 4
        { [TERRAIN_BUILDING] = Simulation.TERR_COLLISION
        , [TERRAIN_MOUNTAIN] = Simulation.TERR_COLLISION
        , [TERRAIN_HOLE] = Simulation.TERR_COLLISION
        , [Simulation.TERRAIN_EXTRA_SPACE] = Simulation.TERR_COLLISION
        }
    }

local reverse_check = { [4] = "valid", [3] = "dropped", [5] = "oob", [1] = "unit collision", [2] = "terrain collision", [6] = "guarding" }
function Simulation:CheckSpaceFree(pos, pathprof)
    if self:PawnAt(pos) then
        return Simulation.UNIT_COLLISION
    end
    return self:CheckTerrainFree(pos, pathprof)
end
function Simulation:CheckTerrainFree(pos, pathprof)
    local terr_type = self:TerrainAt(pos)
    local terr_map = INVALID_TERRAINS[pathprof]
    local invalid_result = terr_map and terr_map[terr_type]
    local result =  invalid_result or Simulation.VALID
    return result
end

-- this is our __index method but we actually have three data sources:
-- - self.data holds our instance data
-- - self.super is our prototype table which holds functions etc
-- - during transactions self.simulation.locked_attributes[self][attribute]
--     holds locks (and pending writes which are only visible from the owning
--     transaction)
--
-- We do some extra logic when we are in a transaction:
-- - If self.space is in our Write set we return the pending write instead
-- - If self.space is in Write set of another concurrent transaction abort.
--     In the real game this equals a race condition which we can't simulate
-- - If the value is in self.data use it and add it to our read set
-- - Otherwise use data from self.super
function ProxyPawn.__index(self, attribute)
    local result = self.data[attribute]

    local id = self.simulation.transaction_id
    if id then 
        l = self.super._LockTable(self, attribute)
        if l.write_lock then
            if l.write_lock.id == id then 
                return l.write_lock.value
            else
                -- LOG( "Tried aquiring read lock for attribute " .. attribute .. " during transaction " .. id .. " while concurrent transaction held write lock"  .. inspect(l))
                error()
            end
        elseif result then
            l.read_lock = l.read_lock or {}
            l.read_lock[id] = true
        end
    end

    if result == nil then
        result = self.super[attribute]
    end
    return result
end
-- Compare ProxyPawn.__transactional_index
-- If in transaction then we aquire a unique lock to self[attribute]
-- Future reads from this transaction will return new_val, after Simulation:CommitTransactions it will be written into main memory
function ProxyPawn.__newindex(self, attribute, new_val)
    local id = self.simulation.transaction_id
    if not id then
        self.data[attribute] = new_val
        return
    end

    l = self.super._LockTable(self, attribute)
    if l.write_lock and l.write_lock.id ~= id then
        LOG("Tried aquiring write lock for attribute " .. attribute .. " while concurrent transaction held write lock" )
        error()
    end
    if l.read_lock then
        for other_id, _ in pairs(l.read_lock) do
            if other_id ~= id then
                LOG("Tried aquiring write lock for attribute " .. attribute .. " while concurrent transaction held read lock" )
                error()
            end
        end
    end
    l.write_lock = { id = id, value = new_val }
end

function ProxyPawn:new (pawn, simulation, o)
  o = o or {}   -- create object if user does not provide one
  o.super = self
  o.pawn = pawn
  o.simulation = simulation
  o.data = {}
  setmetatable(o, self)
  return o
end

function ProxyPawn:_LockTable(attribute)
    local sim = self.simulation
    sim.locked_attributes[self] = sim.locked_attributes[self] or {}
    self_locks = sim.locked_attributes[self]
    self_locks[attribute] = self_locks[attribute] or {}
    return self_locks[attribute]
end

function ProxyPawn:SetHealth(i)
    self.health = i
    if self.health <= 0 then
        self.data.health = 0
        self.is_alive = false
    end
end
function ProxyPawn:GetHealth()
    if not self.health then
        self.data.health = self.pawn:GetHealth()
    end
    return self.health
end
function ProxyPawn:DamageBy(amount)
    if self:IsShield() then
        self:SetShield(false)
    else
        self:SetHealth(self:GetHealth() - amount)
    end
end
function ProxyPawn:IsGuarding()
    if nil == self.is_guarding then
        self.data.is_guarding = self.pawn:IsGuarding()
    end
    return self.is_guarding
end
function ProxyPawn:IsDropped()
    if nil == self.is_dropped then
        self.data.is_dropped = false
    end
    return self.is_dropped
end
function ProxyPawn:Kill()
    self.is_alive = false
end
function ProxyPawn:IsAlive()
    if nil == self.is_alive then
        self.data.is_alive = true
    end
    return self.is_alive
end
function ProxyPawn:IsShield()
    if nil == self.is_shield then
        self.data.is_shield = self.pawn:IsShield()
    end
    return self.is_shield
end
function ProxyPawn:SetShield(b)
    self.is_shield = b
end
function ProxyPawn:GetId()
    if not self.id then
        self.data.id = self.pawn:GetId()
    end
    return self.id
end
function ProxyPawn:GetSpace()
    if not self.space then
        self.data.space = self.pawn:GetSpace()
        self.data.orig_space = self.space
    end
    return self.space
end

function ProxyPawn:IsPlayer()
    if nil == self.is_player then
        self.data.is_player = self.pawn:IsPlayer()
    end
    return self.is_player
end
function ProxyPawn:GetType()
    if not self.typ then
        self.data.typ = self.pawn:GetType()
    end
    return self.typ
end
function ProxyPawn:GetPathProf()
    if not self.pathprof then
        if self:GetType() == "SpiderBoss" then
            self.data.pathprof = PATH_MASSIVE
        else
            self.data.pathprof = self.pawn:GetPathProf() % 16
        end
    end
    return self.pathprof
end
function ProxyPawn:GetOriginalSpace()
    return self.orig_space or self:GetSpace()
end
function ProxyPawn:GetTeam()
    if not self.team then
        self.data.team = self.pawn:GetTeam()
    end
    return self.team
end
function ProxyPawn:SetSpaceIgnoringCollisions(pos)
    self:GetSpace()
    local result = self.simulation:CheckTerrainFree(pos, self:GetPathProf())
    if result == Simulation.DROPPED then
        self.is_dropped = true
        self.is_alive = false
    end
    self.space = pos
    return result
end
function ProxyPawn:SetSpace(pos)
    -- make sure to call GetSpace before setting it
    self:GetSpace()
    if not (Board:IsValid(pos)) then
        return Simulation.OOB
    end
    local result = self.simulation:CheckSpaceFree(pos, self:GetPathProf())
    if result == Simulation.DROPPED then
        self.space = pos
        self.is_dropped = true
        self.is_alive = false
    elseif result == Simulation.VALID then
        self.space = pos
    end
    return result
end
function ProxyPawn:Shove(dir)
    if self:IsGuarding() then
        return Simulation.GUARDING
    end
    local dirv = DIR_VECTORS[dir]
    if not dirv then return end
    local old_pos = self:GetSpace()
    local new_pos = old_pos + dirv
    local res = self:SetSpace(new_pos)
    if res == Simulation.UNIT_COLLISION then
        local other = self.simulation:PawnAt(new_pos)
        other:DamageBy(1)
        self:DamageBy(1)
    elseif res == Simulation.TERR_COLLISION then
        self:DamageBy(1)
    end
    return res
end
function ProxyPawn:HasMoved()
    return self:GetSpace() ~= self:GetOriginalSpace()
end

return Simulation
