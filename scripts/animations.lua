ANIMS.shield1 =     ANIMS.BaseUnit:new{ Image = "units/aliens/shield_1.png", PosX = -23, PosY = -4 }
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


ANIMS.MechPush = ANIMS.MechUnit:new { Image = "units/player/mech_push.png", PosX = -17, PosY = -1 }
ANIMS.MechPusha = ANIMS.MechPush:new {Image = "units/player/mech_push_a.png", PosX = -17, PosY = -1, NumFrames = 4}
ANIMS.MechPushw = ANIMS.MechPush:new {}
ANIMS.MechPush_broken = ANIMS.MechPush:new {Image = "units/player/mech_push_broken.png"}
ANIMS.MechPushw_broken = ANIMS.MechPush:new {Image = "units/player/mech_push_broken_w.png", PosX = -15, PosY = 15}
ANIMS.MechPush_ns = ANIMS.MechPush:new {Image = "units/player/mech_push_ns.png"}
