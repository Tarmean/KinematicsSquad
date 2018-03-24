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
	Damage = 2,
    -- Push = false,
	CollisionDamage = 0,
	FriendlyDamage = true,
	Cost = "low",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {2,3},
	Range = 1, --TOOLTIP INFO
	LaunchSound = "/weapons/shift",
	CustomTipImage = "Prime_Uppercut_Tooltip",
}

Prime_Uppercut_A = Prime_Uppercut:new{
    Damage = 3,
}
Prime_Uppercut_B = Prime_Uppercut:new{
    CollisionDamage = 3
}
Prime_Uppercut_AB = Prime_Uppercut:new{
    Damage = 3,
    CollisionDamage = 3
}

Prime_Uppercut_Tooltip = Skill:new {
    TipImage = {
        Unit = Point(2,2),
        Target = Point(2,1),
        Enemy = Point(2,1),
    }
}--}}}

function Prime_Uppercut:GetSkillEffect(p1, p2)--{{{{{{
    local result = Prime_Uppercut.Punch(p1, p2)

    local pawn = Board:GetPawn(p2)
    if pawn and not pawn:IsGuarding() then
        result:AddScript("Prime_Uppercut.Pre(" .. p2:GetString() .. ", " .. tostring(self.Damage) .. ", " .. tostring(self.CollisionDamage) .. ")")

        result:AddDelay(0.125)
        SafeDamage(p2, self.Damage, false, result)
    else
        local post_damage = SpaceDamage(p2, self.Damage)
        post_damage.sAnimation = "explo_fire1"
        result:AddDamage(post_damage)
    end

    return result
end--}}}

function Prime_Uppercut:GetTargetArea(point)--{{{
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end--}}}}}}

function Prime_Uppercut.HideUnit(p)--{{{
    local pawn = Board:GetPawn(p)
    pawn:SetSpace(Point(32,32))
    pawn:SetActive(false)
    pawn:ClearQueued()
end--}}}

function Prime_Uppercut.RestoreUnit(state)--{{{
    local pawn = Board:GetPawn(state.Id)
    if pawn then
        pawn:SetSpace(state.Space)
        if not pawn:IsDead() then
            pawn:SpawnAnimation()
        end
    end
end--}}}

function Prime_Uppercut.Punch(p1, p2)
    local result = SkillEffect()

    local punch = SpaceDamage(p2)
    punch.sSound = "/props/satellite_launch"
    result:AddMelee(p1, punch, NO_DELAY)
    result:AddBoardShake(2)
    result:AddDelay(1)
    return result
end
function Prime_Uppercut.Pre(p, damage, extradamage)--{{{
    local launcheff = Prime_Uppercut.PreEffect(p, damage, extradamage)

    local pawn = Board:GetPawn(p)
    local state = Prime_Uppercut.MkState(p, damage, extradamage, pawn:GetPathProf(), pawn:GetId())
    launcheff:AddScript("Prime_Uppercut.QueueEvent("..save_table(state)..")")

    Board:AddEffect(launcheff)
end--}}}
function Prime_Uppercut.PreEffect(p, damage, extradamage)

    local launcheff = SkillEffect()
    launcheff.piOrigin = p

    local visual = SpaceDamage(p, DAMAGE_ZERO)
    visual.sAnimation = "explo_fire1"
    launcheff:AddDamage(visual)
    launcheff:AddScript( "Prime_Uppercut.HideUnit("..p:GetString()..")")

    local liftoff = SpaceDamage(Point(-1-p.y, -1-p.x), DAMAGE_ZERO)
    liftoff.sSound = "/props/pod_incoming"
    launcheff:AddAnimation(p, "splash_3")
    launcheff:AddArtillery(liftoff, img)
    return launcheff
end

function Prime_Uppercut.Post(state)--{{{
    local eff = SkillEffect()
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
    eff:AddScript("Prime_Uppercut.RestoreUnit("..save_table(state)..")")
    local extra = Board:IsBlocked(state.Space, state.PathProf) and state.CollisionDamage or 0
    dam = SpaceDamage(state.Space, extra+state.Damage)
    dam.sAnimation = "explo_fire1"
    if extra > 0 then
        dam.sScript = "Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION\")"
    end
    eff:AddDamage(dam)
    eff:AddDelay(0.4)
    Board:AddEffect(eff)
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
    damage.sScript = "Prime_Uppercut_Tooltip.GetSkillEffect_Script()"
    eff:AddDamage(damage)
    return eff
end
function Prime_Uppercut_Tooltip.GetSkillEffect_Script()
    local p1 = Point(2, 2)
    local p2 = Point(2, 1)

    Board:AddEffect(Prime_Uppercut.Punch(p1, p2))

    Board:AddEffect(Prime_Uppercut.PreEffect(p2, 0, 0))

    local pawn = Board:GetPawn(p2)
    local state = Prime_Uppercut.MkState(p2, 0, 0, pawn:GetPathProf(), pawn:GetId())
    Prime_Uppercut.Post(state)
end--}}}

function Prime_Uppercut_Tooltip:GetTargetArea()--{{{
    local ret = PointList()
    ret:push_back(Point(2,1))
    return ret
end--}}}
