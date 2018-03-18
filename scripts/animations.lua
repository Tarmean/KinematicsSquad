ANIMS.shield1 = 	ANIMS.BaseUnit:new{ Image = "units/aliens/shield_1.png", PosX = -23, PosY = -4 }
ANIMS.shield1e = Animation:new{
    Image = "combat/shield_front_turnon.png",
    PosX = -23,
    PosY = -4,
    NumFrames = 7,
    Time = 0.05,
    Loop = false ,
}
ANIMS.shield1d = ANIMS.Shield_Emerge:new{
    Image = "combat/shield_front_turnoff.png",
    Time = 0.05,
}
