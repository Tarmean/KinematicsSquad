local buffered_output = {}
local buffered_offset = 0
function LOGS(s)
    buffered_output = {};
    local delimiter = "\n"
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(buffered_output, match);
    end
    buffered_offset = 0
end
function lnext()
    local out = ""
    for i = 1,10 do
        buffered_offset = buffered_offset + 1
        if #buffered_output < buffered_offset then return end
        out = out .. buffered_output[buffered_offset] .. "\n"
    end
    LOG(out)
end
function lrestart()
    buffered_offset = 0
end
utils = Kinematics:require("utils")
attack = Kinematics:require("curattack_tracker")
Simulation = Kinematics:require("matrix")
inspect = require("inspect")
