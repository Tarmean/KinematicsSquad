local move_skilleffect_base = Move.GetSkillEffect
local Simulation = Kinematics:require("matrix")
local Attack = Kinematics:require("curattack_tracker")
function Move:GetSkillEffect(p1, p2)
    sim = Simulation:new()
    p = sim:PawnAt(p1)
    if p then
        p:SetSpace(p2)
        Attack:SetSim(p1, sim)
    end
    return move_skilleffect_base(self, p1, p2)
end
