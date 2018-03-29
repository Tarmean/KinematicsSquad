-- local inspect = require("inspect")
-- local log = require("log")
-- log.level = "warn"
local img = "effects/shotup_fireball.png"

Prime_Uppercut = Skill:new{--{{{
	Class = "Brute",
    Name = "Uppercut Mech",
	Icon = "weapons/prime_shift.png",
	Rarity = 1,
	Shield = 0,
    -- Push = false,
	CollisionDamage = false,
	FriendlyDamage = true,
	Cost = "low",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {1,3},
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
    CollisionDamage = true
}
Prime_Uppercut_AB = Prime_Uppercut:new{
    Shielding = true,
	CustomTipImage = "Prime_Uppercut_Tooltip_A",
    CollisionDamage = true
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
        result:AddScript("Prime_Uppercut.Pre(" .. p2:GetString() .. ", " ..p1:GetString().. ", " .. tostring(self.CollisionDamage) .. "," .. tostring(self.Shielding) .. ")")

        result:AddDelay(1)
        SafeDamage(p2, 2, false, result)
    else
        local post_damage = SpaceDamage(p2, 2)
        post_damage.sAnimation = "explo_fire1"
        result:AddDamage(post_damage)
        Prime_Uppercut.AddShield(p1, p2, result)
    end

    return result
end--}}}

function Prime_Uppercut:GetTargetArea(point)--{{{
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end--}}}}}}

function Prime_Uppercut.AddShield(p1, p2, result)
    local back_dir = GetDirection(p1 - p2)
    local shieldpos = p1 + DIR_VECTORS[back_dir]

    local chargepath = {}

    Shield_Stabilizer.Activate( {{shieldpos}}, result, back_dir)
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
function Prime_Uppercut.Pre(p, p0, extradamage, shielding)--{{{
    local launcheff = Prime_Uppercut.PreEffect(p, p0, extradamage, shielding)

    local pawn = Board:GetPawn(p)
    local state = Prime_Uppercut.MkState(p, extradamage, pawn:GetPathProf(), pawn:GetId())
    launcheff:AddScript("Prime_Uppercut.QueueEvent("..save_table(state)..")")
    launcheff:AddDelay(FULL_DELAY)


    Board:AddEffect(launcheff)
end--}}}
function Prime_Uppercut.PreEffect(p, p0, extradamage, shielding)

    local launcheff = SkillEffect()
    launcheff.piOrigin = p0

    local id = Board:GetPawn(p):GetId()
    local leap = PointList()
    leap:push_back(p)
    leap:push_back(p0)
    launcheff:AddBoardShake(3)
    launcheff:AddLeap(leap, FULL_DELAY)
    launcheff:AddScript( "Prime_Uppercut.HideUnit("..id..")")
    launcheff:AddSound( "/props/satellite_launch")
    launcheff:AddDelay(1)

    local visual = SpaceDamage(p0, DAMAGE_ZERO)

    visual.sAnimation = "ExploArt3"
    launcheff:AddDamage(visual)

    local liftoff = SpaceDamage(Point(-1-p0.y, -1-p0.x), DAMAGE_ZERO)
    liftoff.sSound = "/props/pod_incoming"
    launcheff:AddAnimation(p0, "splash_3")
    launcheff:AddArtillery(liftoff, img)

    if shielding then
        Prime_Uppercut.AddShield(p0, p, launcheff)
    end
    return launcheff
end

function Prime_Uppercut.Post(state)
    local eff = SkillEffect()
    Prime_Uppercut.PostEffect(eff, state)
    Board:AddEffect(eff)
end
function Prime_Uppercut.PostEffect(eff, state)--{{{
    eff.piOrigin = Point(-10-state.Space.y,-10-state.Space.x)
    local dam = SpaceDamage(state.Space, DAMAGE_ZERO)
    eff:AddSound("/props/satellite_launch")

    eff:AddBoardShake(1.1)
    eff:AddArtillery(dam, img)
    SafeDamage(state.Space, DAMAGE_DEATH, true, eff)
    eff:AddDelay(0.1)
    Prime_Uppercut.AddImpact(eff, state.Space)

    eff:AddEmitter(state.Space, "Emitter_Unit_Crashed")
    eff:AddBoardShake(1)
    local script = "Prime_Uppercut.RestoreUnit("..save_table(state)..")"
    eff:AddScript(script)
    dam = SpaceDamage(state.Space, 2)
    if Board:IsBlocked(state.Space, state.PathProf) and state.CollisionDamage then
        dam.sScript = "Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION\")"
        dam.iDamage = DAMAGE_DEATH
    end
    dam.sAnimation = "explo_fire1"
    eff:AddDamage(dam)
    eff:AddDelay(0.4)
end--}}}


function Prime_Uppercut.AddImpact(eff, p)--{{{
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
    damage.sScript = "Prime_Uppercut_Tooltip.GetSkillEffect_Script("..tostring(self.Shielding)..")"
    eff:AddDamage(damage)
    return eff
end
function Prime_Uppercut_Tooltip.GetSkillEffect_Script(shielding)
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)
    local pawn = Board:GetPawn(p2)

    Board:AddEffect(Prime_Uppercut.Punch(p1, p2))

    Board:AddEffect(Prime_Uppercut.PreEffect(p2, p1, 0, 0, shielding))

    local eff = SkillEffect()
    eff:AddDelay(1.25)
    local state = Prime_Uppercut.MkState(p2, 0, false, pawn:GetPathProf(), pawn:GetId())
    Prime_Uppercut.PostEffect(eff, state)
    Board:AddEffect(eff)
end--}}}

function Prime_Uppercut_Tooltip:GetTargetArea()--{{{
    local ret = PointList()
    ret:push_back(Point(2,1))
    return ret
end--}}}
