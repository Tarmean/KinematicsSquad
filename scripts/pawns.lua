ShieldWallMech = {
    Name = "Guardian Mech",
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
    Name = "Launcher Mech",
    Class = "Brute",
    Health = 3,
    MoveSpeed = 3,
    Image = "MechLaunch",
    ImageOffset = 2,
    SkillList = { "Prime_Uppercut" },
    SoundLocation = "/mech/prime/rock_mech/",
    DefaultTeam = TEAM_PLAYER,
    ImpactMaterial = IMPACT_METAL,
    Massive = true
}
AddPawn("UpperCutMech")

TurbineMech = {
    Name = "Turbine Mech",
    Class = "Science",
    MoveSpeed = 4,
    Health = 2,
    Image = "MechPush",
    ImageOffset = 2,
    SkillList = { "Prime_Pushmech", "Shield_Stabilizer" },
    SoundLocation = "/mech/science/science_mech/",
    DefaultTeam = TEAM_PLAYER,
    ImpactMaterial = IMPACT_METAL,
    Massive = true,
    Flying = true,
}
AddPawn("TurbineMech")

function copy (t) -- shallow-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do target[k] = v end
    setmetatable(target, meta)
    return target
end
PawnShield = {
    SkillList = { "SelfHarm" },
    Name = "Shield",
    Class  = "Prime",
    Health = 1,
    MoveSpeed = 0,
    Image = "shield1",
    ImageOffset = 8,
    DefaultTeam = TEAM_NONE,
	Corporate = true,
    Neutral = true,
    ImpactMaterial = IMPACT_SHIELD,
    Massive = false,
    Pushable = false,
    IgnoreFire = true,
    IgnoreSmoke = true,
}
PawnShield_A = copy(PawnShield)
PawnShield_B = copy(PawnShield)
PawnShield_AB = copy(PawnShield)
PawnShield_A.Health = 2
PawnShield_B.DefaultTeam = TEAM_PLAYER
PawnShield_AB.Health = 2
PawnShield_AB.DefaultTeam = TEAM_PLAYER
AddPawn("PawnShield") 
AddPawn("PawnShield_A") 
AddPawn("PawnShield_B") 
AddPawn("PawnShield_AB") 
function PawnShield.OverwriteTargetScore(skill, spaceDamage, queued)
    local target = spaceDamage.loc
    if not target then return end
    local target_pawn = Board:GetPawn(target)
    if not target_pawn then return end
    if modApi:stringStartsWith(target_pawn:GetType(), "PawnShield") then
        return 0
    end
end

Suicide = Skill:new {
    PathSize = 1,
    Description = "Destroyed at end of turn",
    Damage = 1,
    LaunchSound = "",
}
function Suicide:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    local damage = SpaceDamage(p1)
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
    QueuedSafeDamage(p1, 1, ret)
    local dam = SpaceDamage()
    dam.sSound = "impact/generic/general"
    ret:AddQueuedDamage(dam)
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
