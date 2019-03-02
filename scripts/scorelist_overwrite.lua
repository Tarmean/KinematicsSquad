local L = {}
L.ScoreListOverrides = {}

function RegisterScoreListOverride(fn)
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
	local posScore = 0
	for i = 1, list:size() do
		local spaceDamage = list:index(i)
		local target = spaceDamage.loc
		local damage = spaceDamage.iDamage 
		local moving = spaceDamage:IsMovement() and spaceDamage:MoveStart() == Pawn:GetSpace()


        -- these three lines are new
        local override = L.TryOverrides(self, spaceDamage, queued)
        if override then
            score = score + override
		elseif Board:IsValid(target) or moving then	
			if spaceDamage:IsMovement() then
				posScore = posScore + ScorePositioning(spaceDamage:MoveEnd(), Pawn)
			elseif Board:GetPawnTeam(target) == Pawn:GetTeam() and damage > 0 then
				if Board:IsFrozen(target) and not Board:IsTargeted(target) then
					score = score + self.ScoreEnemy
				else
					score = score + self.ScoreFriendlyDamage
				end
			elseif isEnemy(Board:GetPawnTeam(target),Pawn:GetTeam()) then
					if Board:GetPawn(target):IsDead() then 
						score = self.ScoreNothing
					else
						score = score + self.ScoreEnemy
					end
			elseif Board:IsBuilding(target) and Board:IsPowered(target) and damage > 0 then
				score = score + self.ScoreBuilding
			elseif Board:IsPod(target) and not queued and (damage > 0 or spaceDamage.sPawn ~= "") then
				return -100
			else
				score = score + self.ScoreNothing
			end
		end
	end
	
	--if position is REALLY BAD don't do this (blocking friends, dying, etc.)
	if posScore < -5 then	
		return posScore 
	end
	
	return score
end
