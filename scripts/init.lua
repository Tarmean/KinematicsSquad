local function RequireAll(self)
    return function(ls)
        for _, v in ipairs(ls) do
            require(self.scriptPath .. v)
        end
    end
end
local function init(self)
    modApi:addWeapon_Texts(require(self.scriptPath.."weapons_text"))
    modApi:addWeapon_Texts{ALERT_COLLISION = "COLLISION DAMAGE", ALERT_COLLISION_SHIELDED = "IMPACT SHIELDING"}

    TILE_TOOLTIPS.uppercut =
    { "Crash Site",
        "Unit will land here, killing anything it lands on"
    }

    modApi:appendAsset("img/units/player/mech_launch_ns.png",self.resourcePath.."img/launcher_ns.png")
    modApi:appendAsset("img/units/player/mech_launch.png",self.resourcePath.."img/launcher.png")
    modApi:appendAsset("img/units/player/mech_launch_h.png",self.resourcePath.."img/launcher_h.png")
    modApi:appendAsset("img/units/player/mech_launch_a.png",self.resourcePath.."img/launcher_a.png")
    modApi:appendAsset("img/units/player/mech_launch_w.png",self.resourcePath.."img/launcher_w.png")
    modApi:appendAsset("img/units/player/mech_launch_broken.png",self.resourcePath.."img/launcher_broken.png")
    modApi:appendAsset("img/units/player/mech_launch_broken_w.png",self.resourcePath.."img/launcher_broken_w.png")
    modApi:appendAsset("img/units/aliens/shield_1.png",self.resourcePath.."img/shield_solid_1.png")
    modApi:appendAsset("img/units/player/mech_push.png",self.resourcePath.."img/pushmech.png")
    modApi:appendAsset("img/units/player/mech_push_a.png",self.resourcePath.."img/pushmech_a.png")
    modApi:appendAsset("img/units/player/mech_push_ns.png",self.resourcePath.."img/pushmech_ns.png")
    modApi:appendAsset("img/units/player/mech_push_h.png",self.resourcePath.."img/pushmech_h.png")
    modApi:appendAsset("img/units/player/mech_push_broken_w.png",self.resourcePath.."img/pushmech_broken_w.png")
    modApi:appendAsset("img/units/player/mech_push_broken.png",self.resourcePath.."img/pushmech_broken.png")
    modApi:appendAsset("img/weapons/shield_stabilizer.png",self.resourcePath.."img/shield_stabilizer.png")
    -- package.cpath = self.resourcePath .. 'lib/?.dll;' .. package.cpath
    local f = assert(package.loadlib(self.resourcePath.. "/lib/utils.dll", "luaopen_utils"))()
    RequireAll(self){
        "utils",
        "animations",
        "emitters",
        "push_passive",
        "shield_overrides",
        "doublepunch",
        "shieldbot",
        "uppercut",
        "uppercut_hooks",
        "pawns",
        "scorelist_overwrite",
        "matrix"
    }

end

local function load(self, options, version)
    modApi:addSquad({"Kinematics","UpperCutMech","ShieldWallMech","TurbineMech"},"Kinematics","These mechs counter enemies until they have an opening for the perfect combo attack.", self.resourcePath.."img/pushmech_ns.png")
    modApi:addMissionStartHook(function(m)
        ResetUppercut(m.LiveEnvironment)
    end)

    RegisterScoreListOverride(PawnShield.OverwriteTargetScore)
end


return {
    id = "Kinematics",
    name = "Kinematics",
    version = "1.0.0",
    requirements = {},--Not a list of mods needed for our mod to function, but rather the mods that we need to load before ours to maintain compability 
    init = init,
    load = load,
}
