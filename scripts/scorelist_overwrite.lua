local L = {}
L.ScoreListOverrides = {}

function Kinematics.RegisterScoreListOverride(fn)
	assert(type(fn) == "function")
	L.ScoreListOverrides[#L.ScoreListOverrides+1] = fn
end


L.base_impl = Skill.ScoreList

function L.TryOverrides(skill, spacedamage, isQueued)
    for _, v in ipairs(L.ScoreListOverrides) do
        local cur = v(skill, spacedamage, isQueued)
        if cur then return cur end
    end
end
-- This is mostly copy-pasted from global.lua
function Skill:ScoreList(list, queued)
	local score = 0
    local rest = SkillEffect()
	for i = 1, list:size() do
		local spaceDamage = list:index(i)

        local override = L.TryOverrides(self, spaceDamage, queued)
        if override then
            score = score + override
        else
            rest:AddDamage(spaceDamage)
        end
	end
    score = score + L.base_impl(self, rest.effect, queued)
	
	return score
end
