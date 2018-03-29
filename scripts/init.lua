local function RequireAll(self)
    return function(ls)
        for _, v in ipairs(ls) do
            require(self.scriptPath .. v)
        end
    end
end
local function init(self)
	modApi:addWeapon_Texts(require(self.scriptPath.."weapons_text"))
    modApi:addWeapon_Texts{ALERT_COLLISION = "COLLISION DAMAGE"}

    TILE_TOOLTIPS.uppercut =
    { "Crash Site",
        "Unit will land here, killing anything it lands on"
    }

	modApi:appendAsset("img/units/aliens/shield_1.png",self.resourcePath.."img/shield_solid_1.png")
	modApi:appendAsset("img/units/player/mech_push.png",self.resourcePath.."img/pushmech.png")
	modApi:appendAsset("img/units/player/mech_push_a.png",self.resourcePath.."img/pushmech_a.png")
	modApi:appendAsset("img/units/player/mech_push_ns.png",self.resourcePath.."img/pushmech_ns.png")
	modApi:appendAsset("img/units/player/mech_push_h.png",self.resourcePath.."img/pushmech_h.png")
	modApi:appendAsset("img/units/player/mech_push_broken_w.png",self.resourcePath.."img/pushmech_broken_w.png")
	modApi:appendAsset("img/units/player/mech_push_broken.png",self.resourcePath.."img/pushmech_broken.png")
    RequireAll(self){
        "utils",
        "animations",
        "emitters",
        "push_passive",
        "doublepunch",
        "shieldbot",
        "uppercut",
        "uppercut_hooks",
        "pawns",
    }

end

local function load(self, options, version)
	modApi:addSquad({"PusherSquad","UpperCutMech","ShieldWallMech","PushMech"},"Pushers","These mechs counter enemies until they have an opening for the perfect combo attack.", self.resourcePath.."img/pushmech_ns.png")
	modApi:addMissionStartHook(function(m)
        ResetUppercut(m.LiveEnvironment)
    end)
end


return {
	id = "PusherSquad",
	name = "Pusher Squad",
	version = "0.0.1",
	requirements = {},--Not a list of mods needed for our mod to function, but rather the mods that we need to load before ours to maintain compability 
	init = init,
	load = load,
}
