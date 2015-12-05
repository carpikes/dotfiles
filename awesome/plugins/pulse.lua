-- Pulse audio volume control 
-- By Al
local newtimer        = require("lain.helpers").newtimer
local wibox           = require("wibox")
local io              = { popen  = io.popen }

local setmetatable    = setmetatable

-- Pulse volume
local pulse = {}

local function worker(args)
    local args     = args or {}
    local timeout  = args.timeout or 10
    local settings = args.settings or function() end

    pulse.widget = wibox.widget.textbox('')

    function pulse.update()
        volume_now = {}

        local f = assert(io.popen('pamixer --get-volume'))
        volume_now.level = f:read("*l")
        f:close()

        local f = assert(io.popen('pamixer --get-mute'))
        volume_now.mute = f:read("*l")
        f:close()

        if volume_now.level == nil
        then
            volume_now.level  = "0"
            volume_now.status = "off"
        end

        widget = pulse.widget
        settings()
    end

    newtimer("pulse", timeout, pulse.update)

    return setmetatable(pulse, { __index = pulse.widget })
end

return setmetatable(pulse, { __call = function(_, ...) return worker(...) end })
