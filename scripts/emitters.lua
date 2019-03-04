Emitter_Push_0 = Emitter:new{   --up
    image = "combat/tiles_grass/particle.png",
    -- x = -60,
    -- y = 40,
    max_alpha = 0.2,
    angle = -20,
    -- variance_x = 30,
    -- variance_y = 15,
    variance = 10,
    lifespan = 1,
    burst_count = 100,
    birth_rate = 0.001,
    timer = 0.8,
    max_particles = 300,
    speed = 12,
    gravity = false,
    layer = LAYER_BACK
}
Emitter_Push_1 = Emitter_Push_0:new{  angle = 40, }  --right
Emitter_Push_2 = Emitter_Push_0:new{ angle = 160, }  --down
Emitter_Push_3 = Emitter_Push_0:new{  angle = 220, }  --left

-- Uppercutted unit landing
Emitter_Unit_Crashed = Emitter_Pod:new{
    burst_count = 10,
    lifespan = 2.2,
    speed = 1.75,
    variance = 30,
    angle = 255,
    timer = 0.5,
}
