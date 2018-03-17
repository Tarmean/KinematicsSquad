
local inspect = require("inspect")
local log = require("log")
log.outfile = "C:/Users/Cyril/Desktop/log.log"
log.level = "warn"
local img = "effects/shotup_fireball.png"

Prime_Uppercut = Skill:new{
	Class = "Brute",
	Icon = "weapons/prime_shift.png",
	Rarity = 1,
	Shield = 0,
	Damage = 0,
	ExtraDamage = 0,
	FriendlyDamage = true,
	Cost = "low",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {3,2},
	Range = 1, --TOOLTIP INFO
	LaunchSound = "/weapons/shift",
	TipImage = StandardTips.Melee,
}
Prime_Uppercut_A = Prime_Uppercut:new{
    Damage = 2
}
Prime_Uppercut_B = Prime_Uppercut:new{
    ExtraDamage = 3
}
Prime_Uppercut_AB = Prime_Uppercut:new{
    Damage = 2,
    ExtraDamage = 3
}
function Prime_Uppercut:GetSkillEffect(p1, p2)
    local result = SkillEffect()
    local pawn = Board:GetPawn(p2)
    if pawn and not pawn:IsGuarding() then
        result:AddScript("DoItAt(" .. p2:GetString() .. ", " .. tostring(self.Damage) .. ", " .. tostring(self.ExtraDamage) .. ")")
    end

    return result
end
function Prime_Uppercut:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end

function RestoreAfterPunch(state)
    local pawn = Board:GetPawn(state.Id)
    if pawn then
        pawn:SetInvisible(false)
        pawn:SetSpace(state.Space)
        -- pawn:AddMoveBonus(-5)
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
    local extra = Board:IsBlocked(state.Space, PATH_GROUND) and state.ExtraDamage or 0
    dam = SpaceDamage(state.Space, state.Damage + extra)
    eff:AddDamage(dam)
    return eff
end

function DoItAt(p, damage, extradamage)
    local pawn = Board:GetPawn(p)

    MkEffect("combat/tile_icon/tile_lightning.png", "lightning", p, damage, extradamage, pawn:GetId())

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

function MkEffect(CombatIcon, Desc, Space, Damage, CollisionDamage, Id)
    local effect = {
        CombatIcon = CombatIcon,
        Desc = Desc,
        Space = Space,
        Damage = Damage,
        CollisionDamage = CollisionDamage,
        Id = Id
    }
    PendingEvents[#PendingEvents+1] = effect
end
