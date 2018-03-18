
-- local inspect = require("inspect")
-- local log = require("log")
-- log.level = "warn"
local img = "effects/shotup_fireball.png"

Prime_Uppercut = Skill:new{
	Class = "Brute",
	Icon = "weapons/prime_shift.png",
	Rarity = 1,
	Shield = 0,
	Damage = 2,
    Push = false,
	CollisionDamage = 0,
	FriendlyDamage = true,
	Cost = "low",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {1,3},
	Range = 1, --TOOLTIP INFO
	LaunchSound = "/weapons/shift",
	TipImage = StandardTips.Melee,
}
Prime_Uppercut_A = Prime_Uppercut:new{
    Push = true
}
Prime_Uppercut_B = Prime_Uppercut:new{
    CollisionDamage = 3
}
Prime_Uppercut_AB = Prime_Uppercut:new{
    Push = true,
    CollisionDamage = 3
}
function Prime_Uppercut:GetSkillEffect(p1, p2)
    local result = SkillEffect()
    local pawn = Board:GetPawn(p2)
    if pawn and not pawn:IsGuarding() then
        result:AddScript("DoItAt(" .. p2:GetString() .. ", " .. tostring(self.Push) .. ", " .. tostring(self.CollisionDamage) .. ")")
        result:AddDelay(0.2)

        if self.Push then
            local fakearr = SpaceDamage(p2, DAMAGE_ZERO)
            local str_dirs = {"up","right","down","left"}
            for i = DIR_START, DIR_END do
                fakearr.loc = p2 + DIR_VECTORS[i]
                if DoesPushCollide(p2, i) then
                    fakearr.sImageMark = "combat/arrow_hit_"..str_dirs[i+1]..".png"
                else
                    fakearr.sImageMark = "combat/arrow_"..str_dirs[i+1]..".png"
                end
                result:AddDamage(fakearr)
            end
        end
    end
    result:AddDamage(SpaceDamage(p2, self.Damage))

    return result
end

function DoesPushCollide(p0, dir)
    local dirv = DIR_VECTORS[dir]
    local p = p0 + dirv
    local p_next = p + dirv
    local pawn = Board:GetPawn(p)
    return pawn and Board:IsBlocked(p_next, pawn:GetPathProf()) and not pawn:IsGuarding()
end
function Prime_Uppercut:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end

function RestoreAfterPunch(state)
    local pawn = Board:GetPawn(state.Id)
    if pawn then
        pawn:SetInvisible(false)
        pawn:SetSpace(state.Space)
    end
end

function GetEffect(state)
    local eff = SkillEffect()
    eff.piOrigin = Point(-10-state.Space.y,-10-state.Space.x)
    local dam = SpaceDamage(state.Space, DAMAGE_DEATH)
    dam.sAnimation = "explo_fire1"
    eff:AddSound("/props/satellite_launch")
    eff:AddArtillery(dam, img)
    eff:AddDelay(0.125)
    eff:AddBounce(state.Space, 3)
    eff:AddBoardShake(1)
    eff:AddScript("RestoreAfterPunch("..save_table(state)..")")
    if state.DoPush then
        local push = SpaceDamage()
        for dir = DIR_START, DIR_END do
            push.loc = state.Space + DIR_VECTORS[dir]
            push.sAnimation = "airpush_"..dir
            push.iPush = dir
            eff:AddDamage(push)
        end
    end
    local extra = Board:IsBlocked(state.Space, state.PathProf) and state.CollisionDamage or 0
    dam = SpaceDamage(state.Space, extra+2)
    eff:AddDamage(dam)
    return eff
end

function DoItAt(p, doPush, extradamage)
    local pawn = Board:GetPawn(p)

    MkEffect("combat/tile_icon/tile_lightning.png", "lightning", p, doPush, extradamage, pawn:GetPathProf(), pawn:GetId())

    local launcheff = SkillEffect()
    launcheff.piOrigin = p
    launcheff:AddBoardShake(1)
    launcheff:AddScript( "HideUnit("..p:GetString()..")")
    local liftoff = SpaceDamage(Point(-10-p.y, -10-p.x))
    launcheff:AddArtillery(liftoff, img)
    Board:AddEffect(launcheff)
end

function HideUnit(p)
    local pawn = Board:GetPawn(p)
    pawn:SetSpace(Point(32,32))
    pawn:SetActive(false)
    pawn:SetInvisible(true)
    pawn:ClearQueued()
end

local PendingEvents = { }
local CurrentAttack = nil

local function PushLocal(env)
    if not env.Injected then
        env.Injected = {}
    end
    for _, v in ipairs(PendingEvents) do
        env.Injected[#env.Injected+1] = v
    end
    PendingEvents = {}
end
local function IsEffect(env)
    PushLocal(env)
    return env.Injected and #env.Injected > 0
end
local function ApplyEffect(env)
    PushLocal(env)
    if IsEffect(env) then
        CurrentAttack = env.Injected[1]
        table.remove(env.Injected,1)
        local effect = GetEffect(CurrentAttack)
        Board:AddEffect(effect)
        return IsEffect(env)
    else
        return false
    end
end
local function MarkBoard(env)
    PushLocal(env)
	if (#env.Injected == 0) and not Board:IsBusy() then 
		CurrentAttack = nil
	end
		
	for _,v in ipairs(env.Injected) do
        Board:MarkSpaceDesc(v.Space,v.Desc)
	    if CurrentAttack == v then
            Board:MarkSpaceImage(v.Space,v.CombatIcon, GL_Color(255,150,150,0.75))
        else
            Board:MarkSpaceImage(v.Space,v.CombatIcon, GL_Color(255,226,88,0.75))
	    end
	end
end

local appenv_base = Mission.ApplyEnvironmentEffect
function Mission:ApplyEnvironmentEffect()
    return ApplyEffect(self.LiveEnvironment) or appenv_base(self)
end

local isenv_base = Mission.IsEnvironmentEffect
function Mission:IsEnvironmentEffect()
    return isenv_base(self) or IsEffect(self.LiveEnvironment)
end
local baseupdate_base = Mission.BaseUpdate
function Mission:BaseUpdate()
    baseupdate_base(self)
    MarkBoard(self.LiveEnvironment)
end
-- local planenv_base = Mission.PlanEnvironment
function ResetUppercut(env)
    -- planenv_base(self)
    if env then
        env.Injected = {}
    end
    PendingEvents = {}
end

function MkEffect(CombatIcon, Desc, Space, DoPush, CollisionDamage, PathProf, Id)
    local effect = {
        CombatIcon = CombatIcon,
        Desc = Desc,
        Space = Space,
        DoPush = DoPush,
        CollisionDamage = CollisionDamage,
        Id = Id,
        PathProf = PathProf
    }
    PendingEvents[#PendingEvents+1] = effect
end
