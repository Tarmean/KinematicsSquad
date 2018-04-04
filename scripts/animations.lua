ANIMS.shield1 =     ANIMS.BaseUnit:new{ Image = "units/aliens/shield_1.png", PosX = -23, PosY = -4 }
ANIMS.shield1a =     ANIMS.shield1:new{NumFrames = 1}
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

ANIMS.MechLaunch = ANIMS.MechUnit:new { Image = "units/player/mech_launch.png", PosX = -15, PosY = -8 }
ANIMS.MechLauncha = ANIMS.MechLaunch:new {Image = "units/player/mech_launch_a.png", NumFrames = 4 }
ANIMS.MechLaunchw = ANIMS.MechLaunch:new {Image = "units/player/mech_launch_w.png", PosX = -15, PosY = 4}
ANIMS.MechLaunch_broken = ANIMS.MechLaunch:new {Image = "units/player/mech_launch_broken.png", PosX = -15, PosY = -1}
ANIMS.MechLaunchw_broken = ANIMS.MechLaunch:new {Image = "units/player/mech_launch_broken_w.png", PosX = -15, PosY = 9}
ANIMS.MechLaunch_ns = ANIMS.MechLaunch:new {Image = "units/player/mech_launch_ns.png"}
--
ANIMS.ExploUpper = Animation:new{
	Image = "effects/explo_artillery3.png",
	NumFrames = 10,
	Time = 0.075,
	PosX = -20,
	PosY = -50,
}
