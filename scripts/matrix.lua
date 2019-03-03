-- local inspect = require("inspect")
Simulation = {}
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
        self.sim_terrain[position] = Board:GetTerrain(position)
    end
    return self.sim_terrain[position]
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
ProxyPawn = {}
function ProxyPawn:new (pawn, simulation, o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  o.pawn = pawn
  o.simulation = simulation
  return o
end
function ProxyPawn:GetHealth()
    if not self.health then
        self.health = self.pawn:GetHealth()
    end
    return self.health
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
function ProxyPawn:GetId()
    if not self.id then
        self.id = self.pawn:GetId()
    end
    return self.id
end
function ProxyPawn:GetSpace()
    if not self.space then
        self.space = self.pawn:GetSpace()
    end
    return self.space
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
local TERR_COLLISION = 2
local TERR_DROPPED = 3
local PATH_LEAPER = 6
local INVALID_TERRAINS =
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

ProxyPawn.UNIT_COLLISION = 1
ProxyPawn.TERR_COLLISION = 2
ProxyPawn.DROPPED = 3
ProxyPawn.VALID = 4
ProxyPawn.OOB = 5
function ProxyPawn:CheckSpaceFree(pos)
    if self.simulation:PawnAt(pos) then
        return ProxyPawn.UNIT_COLLISION
    end
    local terr_type = self.simulation:TerrainAt(pos)
    local terr_map = INVALID_TERRAINS[self:GetPathProf()]
    local invalid_result = terr_map and terr_map[terr_type]
    local result =  invalid_result or ProxyPawn.VALID
    return result
end
function ProxyPawn:SetSpace(pos)
    if not (Board:IsValid(pos)) then
        return ProxyPawn.OOB
    end
    local result = self:CheckSpaceFree(pos)
    if result == ProxyPawn.DROPPED then
        self.space = pos
        self.is_dropped = true
        self.is_alive = false
    elseif result == ProxyPawn.VALID then
        self.space = pos
    end
    return result
end
