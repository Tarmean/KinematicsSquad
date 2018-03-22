ShieldWallMech = {
	Name = "Wall Mech",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 3,
	Image = "MechGuard",
	ImageOffset = 2,
	SkillList = { "Prime_ShieldWall" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}
AddPawn("ShieldWallMech")
UpperCutMech = {
	Name = "Uppercut Mech",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 3,
	Image = "MechJudo",
	ImageOffset = 2,
	SkillList = { "Prime_Uppercut" },
	SoundLocation = "/mech/prime/rock_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true
}
AddPawn("UpperCutMech")

PushMech = {
	Name = "Push Mech",
	Class = "Science",
    MoveSpeed = 4,
    Health = 2,
    Image = "MechPush",
    ImageOffset = 2,
	SkillList = { "Prime_Pushmech" },
	SoundLocation = "/mech/science/science_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
    Flying = true,
}
AddPawn("PushMech")

PawnShield = {
    SkillList = { "Suicide" },
	Name = "Shield",
    Class  = "Prime",
	Health = 1,
	MoveSpeed = 0,
	Image = "shield1",
	ImageOffset = 8,
	DefaultTeam = TEAM_NONE,
	Neutral = true,
	ImpactMaterial = IMPACT_SHIELD,
	Massive = false,
	Pushable = false,
    IgnoreFire = true,
    IgnoreSmoke = true,
}
AddPawn("PawnShield") 
PermShield = {
    SkillList = { "SelfHarm" },
	Name = "Shield",
    Class  = "Prime",
	Health = 2,
	MoveSpeed = 0,
	Image = "shield1",
	ImageOffset = 8,
	DefaultTeam = TEAM_NONE,
	Neutral = true,
	ImpactMaterial = IMPACT_SHIELD,
	Massive = false,
	Pushable = false,
    IgnoreFire = true,
    IgnoreSmoke = true,
}

AddPawn("PermShield") 

local function SafeDamage(pos, amount)
    local dam = SpaceDamage(pos, amount)
    if not Board:IsFire(pos) then
        dam.iFire = EFFECT_REMOVE
    end
    if not Board:IsSmoke(pos) then
        dam.iSmoke = EFFECT_REMOVE
    end
    dam.iTerrain = Board:GetTerrain(pos)

    return dam
end
Suicide = Skill:new {
    PathSize = 1,
    Description = "Destroyed at end of turn",
    Damage = 1,
	LaunchSound = "",
}
function Suicide:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    local damage = SafeDamage(p1, DAMAGE_ZERO)
    damage.bHide= true
    damage.bHidePath= true
    damage.sScript = "Board:RemovePawn("..p1:GetString()..")"
    damage.sSound = "impact/generic/general"
    ret:AddQueuedDamage(damage)
    return ret
end
function Suicide:GetTargetArea(p)
    local ret = PointList()
    ret:push_back(p)
    return ret
end
function Suicide:GetTargetScore(p1, p2)
    return 100
end

SelfHarm = Skill:new {
    PathSize = 1,
    Description = "Destroyed at end of turn",
    Damage = 1,
	LaunchSound = "",
}
function SelfHarm:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    local damage = SafeDamage(p1, 1)
    damage.bHide= true
    damage.bHidePath= true
    damage.sSound = "impact/generic/general"
    ret:AddQueuedDamage(damage)
    return ret
end
function SelfHarm:GetTargetArea(p)
    local ret = PointList()
    ret:push_back(p)
    return ret
end
function SelfHarm:GetTargetScore(p1, p2)
    return 100
end
