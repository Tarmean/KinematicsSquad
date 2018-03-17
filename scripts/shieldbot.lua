
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
	UpgradeCost = { 3 , 1 },
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
    
    DoIt(ret, self.Shield, dir, p2)
    for i = 1, self.WallSize do
        ret:AddDelay(0.06)
        local p3 = p2 + (lv * i)
        DoIt(ret, self.Shield, dir, p3)
        local p3 = p2  - (lv*i)
        DoIt(ret, self.Shield, dir, p3)
    end

    return ret
end
function Prime_ShieldWall:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end
function DoIt(ret, shield, dir, p)
    local pawn = Board:GetPawn(p)
    local dirv = DIR_VECTORS[dir]
    if pawn then
        if pawn:GetTeam() == TEAM_PLAYER then
            local damage = SpaceDamage(p, DAMAGE_ZERO)
            damage.iShield = 1
            ret:AddDamage(damage)
        else
            local damage = SpaceDamage(p, DAMAGE_ZERO)
            damage.iPush = dir
            damage.sAnimation = "airpush_"..dir
            ret:AddDamage(damage)
            ret:AddDelay(FULL_DELAY)
            local arg = "SpawnShield( \""..shield .. "\","..p:GetString()..")"
            ret:AddScript(arg)
        end
    else 
        local terr = Board:GetTerrain(p)
        if terr == TERRAIN_MOUNTAIN or terr == TERRAIN_BUILDING then
            local damage = SpaceDamage(p, DAMAGE_ZERO)
            damage.iShield = 1
            ret:AddDamage(damage)
        else
            local damage = SpaceDamage(p, DAMAGE_ZERO)
            damage.sPawn = shield
            ret:AddDamage(damage)
            ret:AddScript("Board:GetPawn("..p:GetString().."):FireWeapon("..p:GetString()..", 1)")
        end
    end
end

function SpawnShield(shield, p)
    if not Board:IsBlocked(p, PATH_GROUND) then
        local pawn = PAWN_FACTORY:CreatePawn(shield)
        Board:AddPawn(pawn, p)
        pawn:FireWeapon(p, 1)
    end
end
