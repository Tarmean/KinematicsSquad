local utils = Kinematics:require("utils")
Kinematics_ShieldWallMech = {
    Name = "Guardian Mech",
    Class = "Prime",
    Health = 3,
    MoveSpeed = 3,
    Image = "MechGuard",
    ImageOffset = 2,
    SkillList = { "Kinematics_Prime_ShieldWeapon" },
    SoundLocation = "/mech/prime/punch_mech/",
    DefaultTeam = TEAM_PLAYER,
    ImpactMaterial = IMPACT_METAL,
    Massive = true,
}
AddPawn("Kinematics_ShieldWallMech")
Kinematics_UpperCutMech = {
    Name = "Launcher Mech",
    Class = "Brute",
    Health = 3,
    MoveSpeed = 3,
    Image = "Kinematics_MechLaunch",
    ImageOffset = 2,
    SkillList = { "Kinematics_Prime_LaunchWeapon" },
    SoundLocation = "/mech/prime/rock_mech/",
    DefaultTeam = TEAM_PLAYER,
    ImpactMaterial = IMPACT_METAL,
    Massive = true
}
AddPawn("Kinematics_UpperCutMech")

Kinematics_TurbineMech = {
    Name = "Turbine Mech",
    Class = "Science",
    MoveSpeed = 4,
    Health = 2,
    Image = "Kinematics_MechPush",
    ImageOffset = 2,
    SkillList = { "Kinematics_Prime_PushWeapon", "Kinematics_Shield_Passive" },
    SoundLocation = "/mech/science/science_mech/",
    DefaultTeam = TEAM_PLAYER,
    ImpactMaterial = IMPACT_METAL,
    Massive = true,
    Flying = true,
}
AddPawn("Kinematics_TurbineMech")

local function copy (t) -- shallow-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do target[k] = v end
    setmetatable(target, meta)
    return target
end
Kinematics_PawnShield = {
    SkillList = { "Kinematics_SelfHarm" },
    Name = "Shield",
    Class  = "Prime",
    Health = 1,
    MoveSpeed = 0,
    Image = "Kinematics_shield1",
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
Kinematics_PawnShield_A = copy(Kinematics_PawnShield)
Kinematics_PawnShield_B = copy(Kinematics_PawnShield)
Kinematics_PawnShield_AB = copy(Kinematics_PawnShield)
Kinematics_PawnShield_A.Health = 2
Kinematics_PawnShield_B.DefaultTeam = TEAM_PLAYER
Kinematics_PawnShield_AB.Health = 2
Kinematics_PawnShield_AB.DefaultTeam = TEAM_PLAYER
AddPawn("Kinematics_PawnShield") 
AddPawn("Kinematics_PawnShield_A") 
AddPawn("Kinematics_PawnShield_B") 
AddPawn("Kinematics_PawnShield_AB") 
function Kinematics_PawnShield.OverwriteTargetScore(skill, spaceDamage, queued)
    local target = spaceDamage.loc
    if not target then return end
    local target_pawn = Board:GetPawn(target)
    if not target_pawn then return end
    if modApi:stringStartsWith(target_pawn:GetType(), "Kinematics_PawnShield") then
        return 0
    end
end

Kinematics_SelfHarm = Skill:new {
    PathSize = 1,
    Description = "Decays at end of turn",
    Damage = 1,
    LaunchSound = "",
}
function Kinematics_SelfHarm:GetSkillEffect(p1, p2)
    local ret = SkillEffect()
    utils.QueuedSafeDamage(p1, 1, ret)
    local dam = SpaceDamage()
    dam.sSound = "impact/generic/general"
    ret:AddQueuedDamage(dam)
    return ret
end
function Kinematics_SelfHarm:GetTargetArea(p)
    local ret = PointList()
    ret:push_back(p)
    return ret
end
function Kinematics_SelfHarm:GetTargetScore(p1, p2)
    return 100
end
