ShieldWallMech = Pawn:new {
	Name = "Wall Mech",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 3,
	Image = "MechGuard",
	ImageOffset = 6,
	SkillList = { "Prime_ShieldWall" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}
AddPawn("ShieldWallMech")
UpperCutMech = Pawn:new {
	Name = "Uppercut Mech",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 3,
	Image = "MechJudo",
	ImageOffset = 4,
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
    MoveSpeed = 3,
    Health = 3,
    Image = "MechPunch",
    ImageOffset = 0,
	SkillList = { "Prime_Pushmech" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}
AddPawn("PushMech")

PawnShield = Pawn:new {
    SkillList = { "Suicide" },
    Class  = "Prime",
	Name = "Shield",
	Health = 1,
	MoveSpeed = 0,
	Image = "shield1",
	ImageOffset = 8,
	DefaultTeam = TEAM_NONE,
	Neutral = true,
	ImpactMaterial = IMPACT_SHIELD,
	Massive = false,
	Pushable = false,
}
AddPawn("PawnShield") 
PermShield = Pawn:new {
    Class  = "Prime",
	Name = "Shield",
	Health = 1,
	MoveSpeed = 0,
	Image = "shield1",
	ImageOffset = 8,
	DefaultTeam = TEAM_NONE,
	Neutral = true,
	ImpactMaterial = IMPACT_SHIELD,
	Massive = false,
	Pushable = false,
    SkillList = {},
}
AddPawn("PermShield") 

Suicide = Skill:new {
    PathSize = 1,
    Description = "Destroyed at end of turn",
    Damage = 1,
	LaunchSound = "",
}
function Suicide:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    ret:AddQueuedScript("Board:RemovePawn("..p1:GetString()..")")
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
