-- local inspect = require("inspect")
function Science_Shield:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2-p1)
	local damage = SpaceDamage(p2,0)
	ret:AddArtillery(damage,"effects/shot_pull_U.png", NO_DELAY)
	local tiles = {}
	for i = DIR_START, DIR_END do
		damage.loc = p2 + DIR_VECTORS[i]
		damage.bHidePath = true
		if self.WideArea or (i == direction) then
			ret:AddArtillery(damage,"effects/shot_pull_U.png", NO_DELAY)--ret:AddDamage(damage)
            tiles[#tiles+1] = {Space = p2 + DIR_VECTORS[i], Dir = i}
		end
	end
    -- ret:AddDelay(FULL_DELAY)

    local full_tiles
    if self.WideArea then 
        full_tiles = {tiles, {{ Space = p2, Dir = DIR_NONE}}}
    else
        tiles[#tiles+1] = {Space = p2, Dir = ((direction+2)%4)}
        full_tiles = {tiles}
    end
    Kinematics_Shield_Passive.Activate(full_tiles, ret, p1)
	
	if self.SelfShield == 1 then
		damage.loc = p1
		ret:AddDamage(damage)
	end
	
	return ret
end	

local local_shield_old = Science_LocalShield.GetSkillEffect
function Science_LocalShield:GetSkillEffect(p1, p2)
    if self.IceVersion == 1 then
        return local_shield_old(self, p1, p2)
    end

    local max_radius = self.WideArea
    local points = {}
    for r = max_radius, 1, -1 do
        local cur_points = {}
        for i = -3, 3 do
            for j = -3, 3 do
                if math.abs(j)+math.abs(i) == r then
                    local p_cur = Point(i, j) + p1
                    cur_points[#cur_points+1] = { Space = p_cur, Dir = GetDirection(p_cur - p1)}
                end
            end
        end
        if #cur_points > 0 then
            points[#points+1] = cur_points
        end
    end
	local ret = SkillEffect()
    Kinematics_Shield_Passive.Activate(points, ret, p1)
	return ret
end	

function Deploy_ShieldTankShot:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	
	local damage = SpaceDamage(p2,0)
	ret:AddMelee(p1,damage)
    Kinematics_Shield_Passive.Activate({{{Space=p2, Dir=direction}}}, ret, p1)
	
	return ret
end	

function Deploy_ShieldTankShot2:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)

	local target = GetProjectileEnd(p1,p2,PATH_PROJECTILE)  
	
	local damage = SpaceDamage(p2,self.Damage)
	ret:AddProjectile(damage, self.ProjectileArt, NO_DELAY)
    ret:AddDelay(FULL_DELAY)
    Kinematics_Shield_Passive.Activate({{{Space=target, Dir=direction}}}, ret, p1)
	
	return ret
end
