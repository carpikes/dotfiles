
--[[ A slight modified battery plugin 
                                                  
     Licensed under GNU General Public License v2 
      * (c) 2013,      Luke Bonham                
      * (c) 2010-2012, Peter Hofmann              
                                                  
--]]

local newtimer     = require("lain.helpers").newtimer
local first_line   = require("lain.helpers").first_line

local naughty      = require("naughty")
local wibox        = require("wibox")

local math         = { floor  = math.floor }
local string       = { format = string.format }
local tonumber     = tonumber

local setmetatable = setmetatable

-- Battery infos
-- lain.widgets.bat
local bat = {}

local function worker(args)
    local args = args or {}
    local timeout = args.timeout or 30
    local battery = args.battery or "BAT0"
    local notify = args.notify or "on"
    local settings = args.settings or function() end
    local low_shown = false
    local blink_val = false

    bat.widget = wibox.widget.textbox('')

    bat_notification_low_preset = {
        title = "Battery low",
        text = "Plug the cable!",
        timeout = 15,
        fg = "#FFFFFF",
        bg = "#FF0000"
    }

    bat_notification_critical_preset = {
        title = "Battery exhausted",
        text = "Shutdown imminent",
        timeout = 1,
        fg = "#FFFFFF",
        bg = "#FF0000"
    }

    function update()
        bat_now = {
            status = "Not present",
            perc   = 999,
            time   = "N/A",
            watt   = "N/A",
            blink  = false,
            stat   = "?"
        }

        local bstr  = "/sys/class/power_supply/" .. battery

        local present = first_line(bstr .. "/present")

        if present == "1" then
            local rate  = first_line(bstr .. "/power_now") or
                          first_line(bstr .. "/current_now")

            local ratev = first_line(bstr .. "/voltage_now")

            local rem   = first_line(bstr .. "/energy_now") or
                          first_line(bstr .. "/charge_now")

            local tot   = first_line(bstr .. "/energy_full") or
                          first_line(bstr .. "/charge_full")

            local bstat = first_line("/tmp/.batstat")
            bat_now.stat = bstat

            bat_now.status = first_line(bstr .. "/status") or "N/A"

            rate  = tonumber(rate) or 1
            ratev = tonumber(ratev)
            rem   = tonumber(rem)
            tot   = tonumber(tot)

            local time_rat = 0
            if bat_now.status == "Charging"
            then
                low_shown = false
                time_rat = (tot - rem) / rate
            elseif bat_now.status == "Discharging"
            then
                time_rat = rem / rate
            end

            local hrs = math.floor(time_rat)
            -- if hrs < 0 then hrs = 0 elseif hrs > 23 then hrs = 23 end

            local min = math.floor((time_rat - hrs) * 60)
            -- if min < 0 then min = 0 elseif min > 59 then min = 59 end

            if hrs < 0 or hrs > 20 or min < 0 or bat_now.status == "Unknown"
            then
                bat_now.time = "??:??"
            else
                bat_now.time = string.format("%02d:%02d", hrs, min)
            end

            bat_now.perc = tonumber(first_line(bstr .. "/capacity"))

            if rate ~= nil and ratev ~= nil then
                bat_now.watt = string.format("%.2fW", (rate * ratev) / 1e12)
            else
                bat_now.watt = "N/A"
            end

        end

        widget = bat.widget
        settings()

        -- notifications for low and critical states
        if bat_now.status == "Discharging" and notify == "on" and bat_now.perc ~= nil
        then
            local nperc = tonumber(bat_now.perc) or 100
            if nperc <= 2
            then
                low_shown = false
                bat.id = naughty.notify({
                    preset = bat_notification_critical_preset,
                    replaces_id = bat.id,
                }).id
            elseif nperc <= 5 and low_shown == false
            then
                low_shown = true
                bat.id = naughty.notify({
                    preset = bat_notification_low_preset,
                    replaces_id = bat.id,
                }).id
            end
        end
    end

    newtimer("bat", timeout, update)

    return bat.widget
end

return setmetatable(bat, { __call = function(_, ...) return worker(...) end })
