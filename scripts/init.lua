local function RequireAll(self)
    return function(ls)
        for _, v in ipairs(ls) do
            require(self.scriptPath .. v)
        end
    end
end
local function init(self)
	modApi:addWeapon_Texts(require(self.scriptPath.."weapons_text"))
	modApi:appendAsset("img/units/aliens/shield_1.png",self.resourcePath.."img/shield_solid_1.png")
    RequireAll(self){
        "animations",
        "doublepunch",
        "shieldbot",
        "uppercut",
        "pawns",
    }

end

local function load(self, options, version)
	modApi:addSquad({"PusherSquad","UpperCutMech","ShieldWallMech","PushMech"},"Pushers","Style over function")
	modApi:addMissionStartHook(function(m)
        ResetUppercut(m.LiveEnvironment)
        -- if m.LiveEnvironment then
        --     m.LiveEnvironment.Injected = {}
        -- end
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
