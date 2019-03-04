ANIMS.Kinematics_shield1 =     ANIMS.BaseUnit:new{ Image = "units/aliens/kinematics_shield_1.png", PosX = -23, PosY = -4 }
ANIMS.Kinematics_shield1a =     ANIMS.Kinematics_shield1:new{NumFrames = 1}
ANIMS.Kinematics_shield1e = Animation:new{
    Image = "combat/shield_front_turnon.png",
    PosX = -23,
    PosY = -4,
    NumFrames = 7,
    Time = 0.05,
    Loop = false ,
}
ANIMS.Kinematics_shield1d = ANIMS.Shield_Emerge:new{
    Image = "combat/shield_front_turnoff.png",
    Time = 0.05,
}


ANIMS.Kinematics_MechPush = ANIMS.MechUnit:new { Image = "units/player/mech_kinematics_push.png", PosX = -17, PosY = -1 }
ANIMS.Kinematics_MechPusha = ANIMS.Kinematics_MechPush:new {Image = "units/player/mech_kinematics_push_a.png", PosX = -17, PosY = -1, NumFrames = 4}
ANIMS.Kinematics_MechPushw = ANIMS.Kinematics_MechPush:new {}
ANIMS.Kinematics_MechPush_broken = ANIMS.Kinematics_MechPush:new {Image = "units/player/mech_kinematics_push_broken.png"}
ANIMS.Kinematics_MechPushw_broken = ANIMS.Kinematics_MechPush:new {Image = "units/player/mech_kinematics_push_broken_w.png", PosX = -15, PosY = 15}
ANIMS.Kinematics_MechPush_ns = ANIMS.Kinematics_MechPush:new {Image = "units/player/mech_kinematics_push_ns.png"}

ANIMS.Kinematics_MechLaunch = ANIMS.MechUnit:new { Image = "units/player/mech_kinematics_launch.png", PosX = -15, PosY = -8 }
ANIMS.Kinematics_MechLauncha = ANIMS.Kinematics_MechLaunch:new {Image = "units/player/mech_kinematics_launch_a.png", NumFrames = 4 }
ANIMS.Kinematics_MechLaunchw = ANIMS.Kinematics_MechLaunch:new {Image = "units/player/mech_kinematics_launch_w.png", PosX = -15, PosY = 4}
ANIMS.Kinematics_MechLaunch_broken = ANIMS.Kinematics_MechLaunch:new {Image = "units/player/mech_kinematics_launch_broken.png", PosX = -15, PosY = -1}
ANIMS.Kinematics_MechLaunchw_broken = ANIMS.Kinematics_MechLaunch:new {Image = "units/player/mech_kinematics_launch_broken_w.png", PosX = -15, PosY = 9}
ANIMS.Kinematics_MechLaunch_ns = ANIMS.Kinematics_MechLaunch:new {Image = "units/player/mech_kinematics_launch_ns.png"}
--
ANIMS.Kinematics_ExploUpper = Animation:new{
	Image = "effects/explo_artillery3.png",
	NumFrames = 10,
	Time = 0.075,
	PosX = -20,
	PosY = -50,
}
