-- local inspect = require("inspect")
-- local log = require("log")
-- log.level = "warn"
local img = "effects/shotup_fireball.png"

Prime_Uppercut = Skill:new{--{{{
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
    CustomTipImage = "Prime_Uppercut_Tooltip",
}

Prime_Uppercut_A = Prime_Uppercut:new{
    Shielding = true,
    CustomTipImage = "Prime_Uppercut_Tooltip_A",
}
Prime_Uppercut_B = Prime_Uppercut:new{
    FriendlyDamage = false
}
Prime_Uppercut_AB = Prime_Uppercut:new{
    Shielding = true,
    CustomTipImage = "Prime_Uppercut_Tooltip_A",
    FriendlyDamage = false
}

Prime_Uppercut_Tooltip = Skill:new {
    Shielding = false,
    TipImage = {
        Unit = Point(2,2),
        Target = Point(2,1),
        Enemy = Point(2,1),
    }
}
Prime_Uppercut_Tooltip_A = Prime_Uppercut_Tooltip:new {
    Shielding = true,
}--}}}

function Prime_Uppercut:GetSkillEffect(p1, p2)--{{{{{{
    local result = Prime_Uppercut.Punch(p1, p2)


    local pawn = Board:GetPawn(p2)
    if pawn and not pawn:IsGuarding() then
        local state = Prime_Uppercut.MkState(p2,self.FriendlyDamage, pawn:GetId())
        result:AddScript("Prime_Uppercut.Pre(" .. p1:GetString() .. ", " .. save_table(state) ..  ")")

        result:AddDelay(1)
        SafeDamage(p2, 2, false, result)
    else
        local post_damage = SpaceDamage(p2, 2)
        post_damage.sAnimation = "explo_fire1"
        result:AddDamage(post_damage)
    end
    if self.Shielding then
        Prime_Uppercut.AddShield(p1, p2, result)
    end

    return result
end--}}}

function Prime_Uppercut:GetTargetArea(point)--{{{
    return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end--}}}}}}

function Prime_Uppercut.AddShield(p1, p2, result)
    local shields = Prime_Uppercut.ShieldPositions(p1, p2)
    Shield_Stabilizer.Activate(shields, result)
end

function Prime_Uppercut.HideUnit(id)--{{{
    local pawn = Board:GetPawn(id)
    pawn:SetSpace(Point(32,32))
    pawn:SetActive(false)
    pawn:ClearQueued()
end--}}g

function Prime_Uppercut.RestoreUnit(state)--{{{
    local pawn = Board:GetPawn(state.Id)
    if pawn then
        pawn:SetSpace(state.Space)
        if not pawn:IsDead() then
            pawn:SpawnAnimation()
        end
    else
    end
end--}}}

function Prime_Uppercut.Punch(p1, p2)
    local result = SkillEffect()

    local punch = SpaceDamage(p2)
    result:AddMelee(p1, punch, NO_DELAY)
    return result
end
function Prime_Uppercut.Pre(p0, state)--{{{
    local launcheff = Prime_Uppercut.LaunchFX(state, p0)

    launcheff:AddScript("Prime_Uppercut.QueueEvent("..save_table(state)..")")
    launcheff:AddDelay(FULL_DELAY)

    Board:AddEffect(launcheff)
end--}}}
function Prime_Uppercut.LaunchFX(state, p0)
    local launcheff = SkillEffect()
    launcheff.piOrigin = p0

    local leap = PointList()
    leap:push_back(state.Space)
    leap:push_back(p0)
    launcheff:AddBoardShake(3)
    launcheff:AddLeap(leap, 0.75)
    launcheff:AddScript( "Prime_Uppercut.HideUnit("..state.Id..")")
    launcheff:AddSound( "/props/satellite_launch")
    launcheff:AddDelay(1)

    local visual = SpaceDamage(p0, DAMAGE_ZERO)
    visual.sAnimation = "ExploUpper"
    launcheff:AddDamage(visual)

    local liftoff = SpaceDamage(Point(-1-p0.y, -1-p0.x), DAMAGE_ZERO)
    liftoff.sSound = "/props/pod_incoming"
    launcheff:AddAnimation(p0, "splash_3")
    launcheff:AddArtillery(liftoff, img)

    return launcheff
end

function Prime_Uppercut.Post(state)
    local eff = SkillEffect()
    Prime_Uppercut.PostEffect(eff, state)
    Board:AddEffect(eff)
end
function Prime_Uppercut.PostEffect(eff, state)--{{{
    eff.piOrigin = Point(-10-state.Space.y,-10-state.Space.x)
    eff:AddSound("/props/satellite_launch")

    Prime_Uppercut.FriendlyFireUpgrade(state, eff)
    eff:AddBoardShake(1.1)
    local dam = SpaceDamage(state.Space, DAMAGE_ZERO)
    eff:AddArtillery(dam, img)
    eff:AddDelay(0.1)
    Prime_Uppercut.ImpactFX(eff, state.Space)

    eff:AddEmitter(state.Space, "Emitter_Unit_Crashed")
    eff:AddBoardShake(1)
    local script = "Prime_Uppercut.RestoreUnit("..save_table(state)..")"
    eff:AddScript(script)
    local PathProf = Board:GetPawn(state.Id):GetPathProf()
    local impact_damage = SpaceDamage(state.Space, 2)
    if Board:IsBlocked(state.Space, PathProf) then
        local pawn = Board:GetPawn(state.Space)
        if not state.FriendlyDamage and pawn and pawn:GetTeam() == TEAM_PLAYER then
            eff:AddScript("Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION_SHIELDED\")")
            eff:AddScript("test.SetHealth(Board:GetPawn("..state.Id.."), 0)")

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


function Prime_Uppercut.ImpactFX(eff, p)--{{{
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

function Prime_Uppercut_Tooltip:GetSkillEffect(p1, p2)--{{{
    local eff = SkillEffect()
    local damage = SpaceDamage()
    Prime_Uppercut_Tooltip.Punch(self.Shielding)
    eff:AddDelay(5)
    return eff
end
function Prime_Uppercut_Tooltip.Punch(shielding)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local eff = Prime_Uppercut.Punch(p1, p2)
    eff:AddScript("Prime_Uppercut_Tooltip.Launch("..tostring(shielding)..")")
    Board:AddEffect(eff)
end
function Prime_Uppercut_Tooltip.Launch(shielding)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local pawn = Board:GetPawn(p2)
    local id = pawn:GetId()

    local state = Prime_Uppercut.MkState(p2, false, id)
    local eff = Prime_Uppercut.LaunchFX(state, p1)
    if shielding then
        eff:AddScript("Prime_Uppercut_Tooltip.Shield("..id..")")
    else
        eff:AddScript("Prime_Uppercut_Tooltip.Land("..id..")")
    end
    Board:AddEffect(eff)
end--}}}
function Prime_Uppercut.ShieldPositions(p1, p2)
    local back_dir = GetDirection(p1 - p2)
    local dir_vec = DIR_VECTORS[back_dir]
    local shieldpos = p1 + dir_vec

    local shields = { {{Space = shieldpos + dir_vec + dir_vec, Dir = back_dir}}, {{Space = shieldpos + dir_vec, Dir = back_dir}}, {{Space = shieldpos, Dir = back_dir}}}
    return shields
end
function Prime_Uppercut_Tooltip.Shield(id)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local eff = SkillEffect()

    local shields = Prime_Uppercut.ShieldPositions(p1, p2)
    Shield_Stabilizer.SpawnShields(shields, eff, "PawnShield")

    eff:AddScript("Prime_Uppercut_Tooltip.Land("..id..")")
    Board:AddEffect(eff)

end
function Prime_Uppercut_Tooltip.Land(id)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)

    local pawn = Board:GetPawn(id)
    local state = Prime_Uppercut.MkState(p2, false, pawn:GetId())
    local eff = SkillEffect()
    eff:AddDelay(0.74)
    Prime_Uppercut.PostEffect(eff, state)
    Board:AddEffect(eff)
end


function Prime_Uppercut_Tooltip:GetTargetArea()--{{{
    local ret = PointList()
    ret:push_back(Point(2,1))
    return ret
end--}}}
function Prime_Uppercut.FriendlyFireUpgrade(state, eff)
    local pawn = Board:GetPawn(state.Space)
    if not state.FriendlyDamage and pawn and (pawn:GetTeam() == TEAM_PLAYER) then
        local dmg = SpaceDamage(state.Space, DAMAGE_ZERO)
        dmg.iShield = EFFECT_CREATE
        eff:AddDamage(dmg)
    end
end
