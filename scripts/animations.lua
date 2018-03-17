ANIMS.shield1 = Animation:new{
    Image = "pushsquad/shield_front_solid.png",
    PosX = -23,
    PosY = -4,
}
ANIMS.shield1a = ANIMS.shield1:new{
    NumFrames = 1,
    Loop = true,
    Time = 0.3,
}
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
