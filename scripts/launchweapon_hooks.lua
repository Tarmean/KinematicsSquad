local Attack = Kinematics:require("curattack_tracker")
local PendingEvents = { }
local PreMarked = {}
local apply_environment_effect_buffer = false

local function PushLocal(env)--{{{{{{
    if not env.Injected then
        env.Injected = {}
    end
    for _, v in ipairs(PendingEvents) do
        env.Injected[#env.Injected+1] = v
    end
    PendingEvents = {}
end--}}}
local function IsEffect(env)--{{{
    PushLocal(env)
    return env.Injected and #env.Injected > 0
end--}}}
local function ApplyEffect(env)--{{{
    PushLocal(env)
    if IsEffect(env) then
        CurrentAttack = env.Injected[1]
        PreMarked[CurrentAttack.Space:GetString()] = nil
        table.remove(env.Injected,1)
        Kinematics_Prime_LaunchWeapon.Post(CurrentAttack)
        return IsEffect(env)
    else
        return false
    end
end--}}}
local function MarkBoard(env)--{{{
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

        local p = Attack:PawnAt(v.Space)
        local should_preview = not Kinematics_Prime_LaunchWeapon.pawn_shield_should_preview(v, p)
        if should_preview then
            Board:MarkSpaceDamage(SpaceDamage(v.Space, DAMAGE_DEATH))
            PreMarked[v.Space:GetString()] = true
        end
    end
end--}}}

local appenv_base = Mission.ApplyEnvironmentEffect--{{{
function Mission:ApplyEnvironmentEffect()
    if apply_environment_effect_buffer then
        local result = ApplyEffect(self.LiveEnvironment)
        apply_environment_effect_buffer = result
        return result
    end

    local built_in = appenv_base(self)
    if built_in then
        return true
    elseif IsEffect(self.LiveEnvironment) then
        apply_environment_effect_buffer = true
        return true
    end
    return false
end--}}}

local isenv_base = Mission.IsEnvironmentEffect--{{{
function Mission:IsEnvironmentEffect()
    return isenv_base(self) or IsEffect(self.LiveEnvironment)
end--}}}

local baseupdate_base = Mission.BaseUpdate--{{{
function Mission:BaseUpdate()
    baseupdate_base(self)
    MarkBoard(self.LiveEnvironment)
end--}}}

function ResetUppercut(env)
    if env then
        env.Injected = {}
    end
    apply_environment_effect_buffer = false
    PreMarked = {}
    PendingEvents = {}
end--}}}

function Kinematics_Prime_LaunchWeapon.QueueEvent(effect)--{{{
    PendingEvents[#PendingEvents+1] = effect
end--}}}

function Kinematics_Prime_LaunchWeapon.MkState(Space, FriendlyDamage, Id)--{{{
    return {
        CombatIcon = "combat/tile_icon/tile_airstrike.png", 
        Desc = "uppercut",
        Space = Space,
        FriendlyDamage = FriendlyDamage,
        Id = Id,
    }
end
--}}}}}}


