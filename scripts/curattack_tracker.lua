-- local inspect = require("inspect")
local SkillHooks = Kinematics:require("wrap_skill_effect")
local Simulation = Kinematics:require("matrix")
local CurAttack = {}
function CurAttack:PawnAt(space)
    if self.attack_source then
        local pawn = Board:GetPawn(self.attack_source)
        if pawn and (pawn:GetArmedWeaponId() == self.weapon_id) and self.sim then
            return self.sim:PawnAt(space)
        end
    end
    self.attack_source = nil
    return Board:GetPawn(space)
end
SkillHooks:RegisterSkillEffectHook(function(skill, p1, p2, eff)
    if not p1 then
        return
    end

    local p = Board:GetPawn(p1)
    if not p or not p:IsWeaponArmed() then return end
    local pawn_id = p:GetId()
    
    CurAttack.weapon_id = p:GetArmedWeaponId()
    if not CurAttack.weapon_id then return end

    CurAttack.attack_source = pawn_id
    CurAttack.sim = Simulation:new()
    pcall(function() CurAttack.sim:RunSkillEffect(eff) end)
end)
return CurAttack
