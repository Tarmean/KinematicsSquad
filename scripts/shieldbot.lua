
-- local inspect = require("inspect")
Prime_ShieldWall = Skill:new{  
	Class = "Prime",
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
	UpgradeCost = { 2 , 3 },
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

    local collision = DoPush(p2, ret, dir)
    for i = 1, self.WallSize do
        local l = DoPush(p2 + (lv * i), ret, dir)
        local r = DoPush(p2 - (lv * i), ret, dir)
        collision = collision or l or r
    end

    if collision then
        ret:AddDelay(FULL_DELAY)
    end
    
    -- monadic getskilleffect might be neat

    DoShield(p2, ret, self.Shield)
    for i = 1, self.WallSize do
        ret:AddDelay(0.09)
        DoShield(p2 + (lv * i), ret, self.Shield)
        DoShield(p2 - (lv * i), ret, self.Shield)
    end

    return ret
end
function Prime_ShieldWall:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end
function DoPush(p, ret, dir)
    local pawn = Board:GetPawn(p)
    local collision = false
    if pawn then
        local p_next = p + DIR_VECTORS[dir]
        if not Board:IsBlocked(p_next, pawn:GetPathProf()) and not pawn:IsGuarding() then
            ret:AddCharge(Board:GetSimplePath(p, p_next), NO_DELAY)
        else
            collision = Board:IsValid(p_next)
        end
    end
    local damage = SpaceDamage(p, DAMAGE_ZERO, dir)
    damage.sImageMark = "combat/shield_front.png"
    damage.sAnimation = "airpush_"..dir
    ret:AddDamage(damage)
    return collision
end
function DoShield(p, ret, shield)
    local damage = SpaceDamage(p)
    damage.sScript = "DoSpawn("..p:GetString() .. ",\""..shield.."\")"
    damage.sSound = "/props/shield_activated"
    ret:AddDamage(damage)
    ret:AddBounce(p, -3)
end
function DoSpawn(p, shield)
    if not Board:IsBlocked(p, PATH_GROUND) then
        local pawn = PAWN_FACTORY:CreatePawn(shield)
        Board:AddPawn(pawn, p)
        pawn:FireWeapon(p, 1)
    else
        local dam = SpaceDamage(p)
        dam.iShield = 1
        Board:DamageSpace(dam)
    end
end
