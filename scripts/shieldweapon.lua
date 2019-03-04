
-- local inspect = require("inspect")
Kinematics_Prime_ShieldWeapon = Skill:new{  
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
    UpgradeCost = { 3 },
    TipImage = {
        Unit = Point(2,2),
        Building = Point(2,1),
        Target = Point(2,1)
    },
    WallSize = 1,
}
Kinematics_Prime_ShieldWeapon_A = Kinematics_Prime_ShieldWeapon:new {
    WallSize = 2,
}
function Kinematics_Prime_ShieldWeapon:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    local dir = GetDirection(p2 - p1)
    local dir2 = (dir+1)% 4
    local lv = DIR_VECTORS[dir2]

    local tiles = {{{Space = p2, Dir = dir}}}
    for i = 1, self.WallSize do
        tiles[#tiles+1] = {{Space = p2 + lv * i, Dir = dir}, { Space =  p2 - lv * i, Dir = dir}}
    end
    Kinematics_Shield_Passive.Activate(tiles,ret, dir)

    return ret
end
function Kinematics_Prime_ShieldWeapon:GetTargetArea(point)
    return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end
