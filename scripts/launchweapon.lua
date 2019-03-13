-- local inspect = require("inspect")
-- local log = require("log")
-- log.level = "warn"
local img = "effects/shotup_fireball.png"
local utils = Kinematics:require("utils")

Kinematics_Prime_LaunchWeapon = Skill:new{--{{{
    Class = "Brute",
    Name = "Launch!",
    Icon = "weapons/prime_shift.png",
    Rarity = 1,
    Shield = 0,
    -- Push = false,
    FriendlyDamage = true,
    Cost = "low",
    PowerCost = 2,
    Upgrades = 2,
    UpgradeCost = {2,1},
    Shielding = false,
    Range = 1, --TOOLTIP INFO
    LaunchSound = "/weapons/shift",
    CustomTipImage = "Kinematics_Prime_LaunchWeapon_Tooltip",
}

Kinematics_Prime_LaunchWeapon_A = Kinematics_Prime_LaunchWeapon:new{
    Shielding = true,
    CustomTipImage = "Kinematics_Prime_LaunchWeapon_Tooltip_A",
}
Kinematics_Prime_LaunchWeapon_B = Kinematics_Prime_LaunchWeapon:new{
    FriendlyDamage = false,
    CustomTipImage = "Kinematics_Prime_LaunchWeapon_Tooltip_B"
}
Kinematics_Prime_LaunchWeapon_AB = Kinematics_Prime_LaunchWeapon:new{
    Shielding = true,
    CustomTipImage = "Kinematics_Prime_LaunchWeapon_Tooltip_AB",
    FriendlyDamage = false
}

Kinematics_Prime_LaunchWeapon_Tooltip = Skill:new {
    FriendlyDamage = true,
    Shielding = false,
    TipImage = {
        Unit = Point(2,2),
        Target = Point(2,1),
        Enemy = Point(2,1),
        CustomPawn = "Kinematics_UpperCutMech",
    }
}
Kinematics_Prime_LaunchWeapon_Tooltip_A = Kinematics_Prime_LaunchWeapon_Tooltip:new {
    Shielding = true,
}--}}}
Kinematics_Prime_LaunchWeapon_Tooltip_B = Kinematics_Prime_LaunchWeapon_Tooltip:new {
    FriendlyDamage = false,
}--}}}
Kinematics_Prime_LaunchWeapon_Tooltip_AB = Kinematics_Prime_LaunchWeapon_Tooltip:new {
    FriendlyDamage = false,
    Shielding = true,
}

function Kinematics_Prime_LaunchWeapon:GetSkillEffect(p1, p2)--{{{{{{
    local result = Kinematics_Prime_LaunchWeapon.Punch(p1, p2)
    local pawn = Board:GetPawn(p2)
    if pawn and not pawn:IsGuarding() then
        local state = Kinematics_Prime_LaunchWeapon.MkState(p2,self.FriendlyDamage, pawn:GetId())
        result:AddScript("Kinematics_Prime_LaunchWeapon.Pre(" .. p1:GetString() .. ", " .. save_table(state) ..  ")")
        result:AddDelay(1)
        utils.SafeDamage(p2, 2, false, result)
    else
        local post_damage = SpaceDamage(p2, 2)
        post_damage.sAnimation = "explo_fire1"
        result:AddDamage(post_damage)
    end
    if self.Shielding then
        Kinematics_Prime_LaunchWeapon.AddShield(p1, p2, result)
    end

    return result
end--}}}

function Kinematics_Prime_LaunchWeapon:GetTargetArea(point)--{{{
    return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end--}}}}}}

function Kinematics_Prime_LaunchWeapon.AddShield(p1, p2, result)
    local source = Board:GetPawn(p1)
    local shields = Kinematics_Prime_LaunchWeapon.ShieldPositions(p1, p2)
    Kinematics_Shield_Passive.Activate(shields, result, p1)
end

function Kinematics_Prime_LaunchWeapon.HideUnit(id)--{{{
    local pawn = Board:GetPawn(id)
    pawn:SetSpace(Point(32,32))
    pawn:SetActive(false)
    pawn:ClearQueued()
end--}}g

function Kinematics_Prime_LaunchWeapon.RestoreUnit(state)--{{{
    local pawn = Board:GetPawn(state.Id)
    if pawn then
        pawn:SetSpace(state.Space)
        if not pawn:IsDead() then
            pawn:SpawnAnimation()
        end
    else
    end
end--}}}

function Kinematics_Prime_LaunchWeapon.Punch(p1, p2)
    local result = SkillEffect()

    local punch = SpaceDamage(p2)
    result:AddMelee(p1, punch, NO_DELAY)
    return result
end
function Kinematics_Prime_LaunchWeapon.Pre(p0, state)--{{{
    local launcheff = Kinematics_Prime_LaunchWeapon.LaunchFX(state, p0)

    launcheff:AddScript("Kinematics_Prime_LaunchWeapon.QueueEvent("..save_table(state)..")")
    launcheff:AddDelay(FULL_DELAY)

    Board:AddEffect(launcheff)
end--}}}
function Kinematics_Prime_LaunchWeapon.LaunchFX(state, p0)
    local launcheff = SkillEffect()
    launcheff.piOrigin = p0

    local leap = PointList()
    leap:push_back(state.Space)
    leap:push_back(p0)
    launcheff:AddBoardShake(3)
    launcheff:AddLeap(leap, 0.75)
    launcheff:AddScript( "Kinematics_Prime_LaunchWeapon.HideUnit("..state.Id..")")
    launcheff:AddSound( "/props/satellite_launch")
    launcheff:AddDelay(1)

    local visual = SpaceDamage(p0, DAMAGE_ZERO)
    visual.sAnimation = "Kinematics_ExploUpper"
    launcheff:AddDamage(visual)

    local liftoff = SpaceDamage(Point(-1-p0.y, -1-p0.x), DAMAGE_ZERO)
    liftoff.sSound = "/props/pod_incoming"
    launcheff:AddAnimation(p0, "splash_3")
    launcheff:AddArtillery(liftoff, img)

    return launcheff
end

function Kinematics_Prime_LaunchWeapon.Post(state)
    local eff = SkillEffect()
    Kinematics_Prime_LaunchWeapon.PostEffect(eff, state)
    Board:AddEffect(eff)
end
function Kinematics_Prime_LaunchWeapon.pawn_is_shielded(pawn)
    return pawn and (pawn:GetTeam() == TEAM_PLAYER) and pawn:IsShield()
end
function Kinematics_Prime_LaunchWeapon.pawn_shield_should_trigger(state, pawn)
   if state.FriendlyDamage then
       return false
   end
   if not pawn or not (pawn:GetTeam() == TEAM_PLAYER) then
       return false
   end
   if modApi:stringStartsWith(pawn:GetType(), "Kinematics_PawnShield_A") then
       return false
   end
   return true
end
function Kinematics_Prime_LaunchWeapon.pawn_shield_should_preview(state, pawn)

    if Kinematics_Prime_LaunchWeapon.pawn_shield_should_trigger(state, pawn) then
        return true
    elseif pawn and modApi:stringStartsWith(pawn:GetType(), "Kinematics_PawnShield") then
        return true
    end
    return false

end
function Kinematics_Prime_LaunchWeapon.PostEffect(eff, state)--{{{
    eff.piOrigin = Point(-10-state.Space.y,-10-state.Space.x)
    eff:AddSound("/props/satellite_launch")

    Kinematics_Prime_LaunchWeapon.FriendlyFireUpgrade(state, eff)
    eff:AddBoardShake(1.1)
    local dam = SpaceDamage(state.Space, DAMAGE_ZERO)
    eff:AddArtillery(dam, img)
    eff:AddDelay(0.1)
    Kinematics_Prime_LaunchWeapon.ImpactFX(eff, state.Space)

    eff:AddEmitter(state.Space, "Emitter_Unit_Crashed")
    eff:AddBoardShake(1)
    local script = "Kinematics_Prime_LaunchWeapon.RestoreUnit("..save_table(state)..")"
    eff:AddScript(script)
    local impact_damage = SpaceDamage(state.Space, 2)
    local pathprof = Board:GetPawn(state.Id):GetPathProf()
    local pawn = Board:GetPawn(state.Space)
    if Board:IsBlocked(state.Space, pathprof) then
        if Kinematics_Prime_LaunchWeapon.pawn_shield_should_trigger(state, pawn) then
            eff:AddScript("Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION_SHIELDED\")")
            eff:AddScript("Board:GetPawn("..state.Id.."):Kill(true)")
        elseif Kinematics_Prime_LaunchWeapon.pawn_is_shielded(pawn) then
            eff:AddScript("Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION\")")
            eff:AddScript("Board:GetPawn("..state.Id.."):Kill(true)")
        else
            eff:AddScript("Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION\")")
            impact_damage.iDamage = DAMAGE_DEATH
        end
    end
    eff:AddDamage(impact_damage)
    dam.sAnimation = "explo_fire1"
    eff:AddDamage(dam)
    eff:AddDelay(0.4)
end--}}}


function Kinematics_Prime_LaunchWeapon.ImpactFX(eff, p)--{{{
    for i = -2, 2 do
        for j = -2, 2 do
            local cur = p + Point(i,j)
            local strength = math.max(4 - p:Manhattan(cur), 0) * 3
            if strength > 0 then
                eff:AddBounce(cur, strength)
            end
        end
    end
end--}}}

function Kinematics_Prime_LaunchWeapon_Tooltip:GetSkillEffect(p1, p2)--{{{
    local eff = SkillEffect()
    local damage = SpaceDamage()
    Kinematics_Prime_LaunchWeapon_Tooltip.Punch(self.Shielding, self.FriendlyDamage)
    eff:AddDelay(5)
    return eff
end
function Kinematics_Prime_LaunchWeapon_Tooltip.Punch(shielding, friendlyDamage)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local eff = Kinematics_Prime_LaunchWeapon.Punch(p1, p2)
    eff:AddScript("Kinematics_Prime_LaunchWeapon_Tooltip.Launch("..tostring(shielding).. ", " .. tostring(friendlyDamage) .. ")")
    Board:AddEffect(eff)
end
function Kinematics_Prime_LaunchWeapon_Tooltip.Launch(shielding, friendlyDamage)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local pawn = Board:GetPawn(p2)
    local id = pawn:GetId()

    local state = Kinematics_Prime_LaunchWeapon.MkState(p2, friendlyDamage, id)
    local eff = Kinematics_Prime_LaunchWeapon.LaunchFX(state, p1)
    if not friendlyDamage then
        eff:AddDelay(0.5)
        eff:AddMove(Board:GetSimplePath(p1, p2), FULL_DELAY)
    end
    if shielding then
        eff:AddScript("Kinematics_Prime_LaunchWeapon_Tooltip.Shield("..id..")")
    else
        eff:AddScript("Kinematics_Prime_LaunchWeapon_Tooltip.Land("..id..")")
    end
    Board:AddEffect(eff)
end--}}}
function Kinematics_Prime_LaunchWeapon.ShieldPositions(p1, p2)
    local back_dir = GetDirection(p1 - p2)
    local dir_vec = DIR_VECTORS[back_dir]
    local shieldpos = p1 + dir_vec

    local shields = {{ {Space = shieldpos + dir_vec + dir_vec, Dir = back_dir}, {Space = shieldpos + dir_vec, Dir = back_dir}, {Space = shieldpos, Dir = back_dir}}}
    return shields
end
function Kinematics_Prime_LaunchWeapon_Tooltip.Shield(id)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local eff = SkillEffect()

    local shields = Kinematics_Prime_LaunchWeapon.ShieldPositions(p1, p2)
    Kinematics_Shield_Passive.Activate(shields, eff)

    eff:AddScript("Kinematics_Prime_LaunchWeapon_Tooltip.Land("..id..")")
    Board:AddEffect(eff)

end
function Kinematics_Prime_LaunchWeapon_Tooltip.Land(id)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)

    local pawn = Board:GetPawn(id)
    local state = Kinematics_Prime_LaunchWeapon.MkState(p2, false, pawn:GetId())
    local eff = SkillEffect()
    eff:AddDelay(0.74)
    Kinematics_Prime_LaunchWeapon.PostEffect(eff, state)
    eff:AddDelay(0.6)
    Board:AddEffect(eff)
end


function Kinematics_Prime_LaunchWeapon_Tooltip:GetTargetArea()--{{{
    local ret = PointList()
    ret:push_back(Point(2,1))
    return ret
end--}}}
function Kinematics_Prime_LaunchWeapon.FriendlyFireUpgrade(state, eff)
    local pawn = Board:GetPawn(state.Space)
    if Kinematics_Prime_LaunchWeapon.pawn_shield_should_trigger(state, pawn) then
        local dmg = SpaceDamage(state.Space, DAMAGE_ZERO)
        dmg.iShield = EFFECT_CREATE
        eff:AddDamage(dmg)
    end
end
