local CurAttack = {}
function CurAttack:SetSim(source, sim)
    local p = Board:GetPawn(source)
    if not p then return end
    local pawn_id = p:GetId()
    
    self.weapon_id = p:GetArmedWeaponId()
    if not self.weapon_id then return end

    self.attack_source = pawn_id
    self.sim = sim
end
function CurAttack:PawnAt(space)
    if self.attack_source then
        local pawn = Board:GetPawn(self.attack_source)
        if pawn and (pawn:GetArmedWeaponId() == self.weapon_id) and sim then
            return self.sim:PawnAt(space)
        end
    end
    self.attack_source = nil
    return Board:GetPawn(space)
end
return CurAttack
