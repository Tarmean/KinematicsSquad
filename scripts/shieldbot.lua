
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
	Upgrades = 1,
	--UpgradeList = { "Dash",  "+2 Damage"  },
	UpgradeCost = { 3 },
	TipImage = {
		Unit = Point(2,2),
		Building = Point(2,1),
		Target = Point(2,1)
	},
    WallSize = 1,
}
Prime_ShieldWall_A = Prime_ShieldWall:new {
    WallSize = 2,
}
-- Prime_ShieldWall_B = Prime_ShieldWall:new {
--     Shield = "PermShield",
-- }
-- Prime_ShieldWall_AB = Prime_ShieldWall:new {
--     WallSize = 2,
--     Shield = "PermShield",
-- }
function Prime_ShieldWall:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
    local dir = GetDirection(p2 - p1)
    local dir2 = (dir+1)% 4
    local lv = DIR_VECTORS[dir2]

    local tiles = {{p2}}
    for i = 1, self.WallSize do
        tiles[#tiles+1] = {p2 + lv * i, p2 - lv * i}
    end
    Shield_Stabilizer.Activate(tiles,ret, dir)

    return ret
end
function Prime_ShieldWall:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end

