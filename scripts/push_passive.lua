-- local inspect = require("inspect")
Shield_Stabilizer = Skill:new {
    Name = "Shield Stabilizer",
    Passive = "Flame_Immune",
    Icon = "weapons/shield_stabilizer.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {2, 3}
}
Shield_Stabilizer_A = Shield_Stabilizer:new {}
Shield_Stabilizer_B = Shield_Stabilizer:new {}
Shield_Stabilizer_AB = Shield_Stabilizer:new {}


function PassiveType()
    for s in ActiveWeapons() do
        if s == "Shield_Stabilizer" then
            return "PawnShield"
        elseif s == "Shield_Stabilizer_A" then
            return "PawnShield_A"
        elseif s == "Shield_Stabilizer_B" then
            return "PawnShield_B"
        elseif s == "Shield_Stabilizer_AB" then
            return "PawnShield_AB"
        end
    end
    return nil
end
function Shield_Stabilizer.Activate(tiles, ret)
    local kind = PassiveType()

    if kind then
        Shield_Stabilizer.SpawnShields(tiles, ret, kind)
    else
        Shield_Stabilizer.ApplyShields(tiles, ret)
    end

end

function Shield_Stabilizer.ApplyShields(tiles, ret)
    local damage = SpaceDamage()
    damage.iShield = 1
    for _, s in ipairs(tiles) do
        for _, t in ipairs(s) do
            damage.loc = t.Space
            ret:AddDamage(damage)
        end
    end
end
function Shield_Stabilizer.SpawnShields(tiles, ret, shield)
    local chargepaths = {}
    for _, s in ipairs(tiles) do
        for _, t in ipairs(s) do
            Shield_Stabilizer.DoPush(t.Space, chargepaths, ret, t.Dir)
        end
    end

    ret:AddDelay(FULL_DELAY)

    for _,path in ipairs(chargepaths) do
        ret:AddCharge(path, NO_DELAY)
    end

    for _, s in ipairs(tiles) do
        for _, t in ipairs(s) do
            Shield_Stabilizer.DoShield(t.Space, ret, shield)
        end
        ret:AddDelay(FULL_DELAY)
    end
end

local function IsBlocked(p, pathprof)
    return (InvalidTerrain(p, pathprof) == TERR_COLLISION) or Board:IsPawnSpace(p)
end
function Shield_Stabilizer.DoPush(p, ls, ret, dir)

    local pawn = Board:GetPawn(p)
    local show_shield = false
    if dir == DIR_NONE and pawn then
        show_shield = false
    elseif pawn then
        local p_next = p + DIR_VECTORS[dir]
        local guard = pawn:IsGuarding()
        local collision =  not guard and IsBlocked(p_next, pawn:GetPathProf()) 
        local moved = not collision and not guard
        if moved then
            ls[#ls+1] = Board:GetSimplePath(p, p_next)
        end
        local push_free = moved or (collision and (pawn:GetHealth() == 1))
        local friendly_building = guard and pawn:IsPlayer()
        show_shield = push_free or friendly_building
    else
        show_shield = true
    end
    local damage = SpaceDamage(p, DAMAGE_ZERO, dir)
    if show_shield then
        local terr = Board:GetTerrain(p)
        if terr ~= TERRAIN_HOLE and terr ~= TERRAIN_ACID and terr ~= TERRAIN_LAVA and terr ~= TERRAIN_WATER then
            damage.sImageMark = "combat/shield_front.png"
        end
    end
    if (dir ~= DIR_NONE) then 
        damage.sAnimation = "airpush_"..dir
    end
    ret:AddDamage(damage)
end
function Shield_Stabilizer.DoShield(p, ret, shield)
    local damage = SpaceDamage(p)
    damage.sScript = "Shield_Stabilizer.DoSpawn("..p:GetString() .. ",\""..shield.."\")"
    damage.sSound = "/props/shield_activated"
    ret:AddDamage(damage)
    ret:AddBounce(p, -3)
end
function Shield_Stabilizer.DoSpawn(p, shield)
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
