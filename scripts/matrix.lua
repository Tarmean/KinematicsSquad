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

local ProxyPawn = {}
function Simulation:Setup()
    self.sim_pawns = {}
    self.sim_terrain = {}
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
    if not new_pawn or not self:_IsPawnNew(new_pawn) then return end
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
function Simulation:AddPawn(ident, space)
    local p = PAWN_FACTORY:CreatePawn(ident)
    local new_pawn = ProxyPawn:new(p, self, {space = space})
    self.sim_pawns[#self.sim_pawns+1] = new_pawn
    return new_pawn
end
function Simulation:PawnAt(position)
    for _, v in ipairs(self.sim_pawns) do
        if v:IsAlive() and v:GetSpace() == position then
            return v
        end
    end
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
    local terr_type = self:TerrainAt(pos)
    local terr_map = INVALID_TERRAINS[pathprof]
    local invalid_result = terr_map and terr_map[terr_type]
    local result =  invalid_result or Simulation.VALID
    return result
end

function ProxyPawn:new (pawn, simulation, o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  o.pawn = pawn
  o.simulation = simulation
  return o
end
function ProxyPawn:SetHealth(i)
    self.health = i
    if self.health <= 0 then
        self.health = 0
        self.is_alive = false
    end
end
function ProxyPawn:GetHealth()
    if not self.health then
        self.health = self.pawn:GetHealth()
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
        self.is_guarding = self.pawn:IsGuarding()
    end
    return self.is_guarding
end
function ProxyPawn:IsDropped()
    if nil == self.is_dropped then
        self.is_dropped = false
    end
    return self.is_dropped
end
function ProxyPawn:IsAlive()
    if nil == self.is_alive then
        self.is_alive = true
    end
    return self.is_alive
end
function ProxyPawn:IsShield()
    if nil == self.is_shield then
        self.is_shield = self.pawn:IsShield()
    end
    return self.is_shield
end
function ProxyPawn:SetShield(b)
    self.is_shield = b
end
function ProxyPawn:GetId()
    if not self.id then
        self.id = self.pawn:GetId()
    end
    return self.id
end
function ProxyPawn:GetSpace()
    if not self.space then
        self.space = self.pawn:GetSpace()
        self.orig_space = self.space
    end
    return self.space
end
function ProxyPawn:IsPlayer()
    if nil == self.is_player then
        self.is_player = self.pawn:IsPlayer()
    end
    return self.is_player
end
function ProxyPawn:GetType()
    if not self.typ then
        self.typ = self.pawn:GetType()
    end
    return self.typ
end
function ProxyPawn:GetPathProf()
    if not self.pathprof then
        if self:GetType() == "SpiderBoss" then
            self.pathprof = PATH_MASSIVE
        else
            self.pathprof = self.pawn:GetPathProf() % 16
        end
    end
    return self.pathprof
end
function ProxyPawn:GetOriginalSpace()
    return self.orig_space or self:GetSpace()
end
function ProxyPawn:GetTeam()
    if not self.team then
        self.team = self.pawn:GetTeam()
    end
    return self.team
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
