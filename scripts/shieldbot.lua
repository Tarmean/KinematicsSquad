
-- local inspect = require("inspect")
Prime_ShieldWall = Skill:new{  
	Class = "Prime",
    Name = "Shield Mech",
	Icon = "weapons/prime_shieldbash.png",
	Rarity = 3,
	Explosion = "",
	LaunchSound = "/weapons/shield_bash",
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
	Upgrades = 2,
	--UpgradeList = { "Dash",  "+2 Damage"  },
	UpgradeCost = { 3 , 2 },
	TipImage = StandardTips.Melee,
    WallSize = 1,
    Shield = "PawnShield"
}
Prime_ShieldWall_A = Prime_ShieldWall:new {
    WallSize = 2,
}
Prime_ShieldWall_B = Prime_ShieldWall:new {
    Shield = "PermShield",
}
Prime_ShieldWall_AB = Prime_ShieldWall:new {
    WallSize = 2,
    Shield = "PermShield",
}
function Prime_ShieldWall:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
    local dir = GetDirection(p2 - p1)
    local dir2 = (dir+1)% 4
    local lv = DIR_VECTORS[dir2]


    local chargepaths = {}
    Prime_ShieldWall.DoPush(p2, chargepaths, ret,  dir)
    for i = 1, self.WallSize do
        Prime_ShieldWall.DoPush(p2 + (lv * i), chargepaths, ret, dir)
        Prime_ShieldWall.DoPush(p2 - (lv * i), chargepaths, ret, dir)
    end

    ret:AddDelay(FULL_DELAY)

    for _,path in ipairs(chargepaths) do
        ret:AddCharge(path, NO_DELAY)
    end
    
    -- monadic getskilleffect might be neat

    Prime_ShieldWall.DoShield(p2, ret, self.Shield)
    for i = 1, self.WallSize do
        ret:AddDelay(FULL_DELAY)
        Prime_ShieldWall.DoShield(p2 + (lv * i), ret, self.Shield)
        Prime_ShieldWall.DoShield(p2 - (lv * i), ret, self.Shield)
    end

    return ret
end
function Prime_ShieldWall:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end
local function IsBlocked(p, pathprof)
    return (InvalidTerrain(p, pathprof) == TERR_COLLISION) or Board:IsPawnSpace(p)
end
function Prime_ShieldWall.DoPush(p, ls, ret, dir)
    local pawn = Board:GetPawn(p)
    local show_shield = false
    if pawn then
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
        damage.sImageMark = "combat/shield_front.png"
    end
    damage.sAnimation = "airpush_"..dir
    ret:AddDamage(damage)
end
function Prime_ShieldWall.DoShield(p, ret, shield)
    local damage = SpaceDamage(p)
    damage.sScript = "Prime_ShieldWall.DoSpawn("..p:GetString() .. ",\""..shield.."\")"
    damage.sSound = "/props/shield_activated"
    ret:AddDamage(damage)
    ret:AddBounce(p, -3)
end
function Prime_ShieldWall.DoSpawn(p, shield)
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
