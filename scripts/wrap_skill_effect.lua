local skill_new = Skill.new
local mod = {hooks = {}}
local wrapped = { [Skill.GetSkillEffect] = true }
function mod:ApplyHooks(skill, newly_set)
    local skill_effect = skill.GetSkillEffect
    if skill_effect  then
        if not wrapped[skill_effect] then
            skill.GetSkillEffect = function(this, p1, p2)
                local out = skill_effect(this, p1, p2)
                for _, fn in ipairs(mod.hooks) do
                    fn(this, p1, p2, out)
                end
                return out
            end
            wrapped[skill.GetSkillEffect] = true
        else
            LOG("hooked already seen" .. tostring(newly_set))
        end
    else
        LOG("hooked too early: " .. tostring(newly_set))
    end
end
function mod:RegisterSkillEffectHook(fn)
    self.hooks[#self.hooks+1] = fn
end
function mod:Setup() 
    if self.IsSetup then return end
    self.IsSetup = true
    for _, obj in pairs(_G) do
        if (type(obj)=="table") and obj.GetSkillEffect then
            -- LOG("existing hook")
            self:ApplyHooks(obj, false)
        end
    end
    Skill.__newindex  = function(this, k, v)
        rawset(this, k, v)
        if k == "GetSkillEffect" then
            self:ApplyHooks(this, true)
        end
    end
end

mod:Setup()
return mod
