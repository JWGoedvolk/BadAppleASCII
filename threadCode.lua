---@diagnostic disable: lowercase-global
channel = {}
channel.I = love.thread.getChannel("I")
channel.O = love.thread.getChannel("O")

--[[
    channel O gets data from main.lua
        o = data received
            should be array of strings
    channel I send data to   main.lua
        i = ["text"]
]]

while true do
    local o = channel.O:pop()
    if o then
        o:play()
        --love.graphics.draw(video, 970)
        --love.timer.sleep(0.2)
        channel.I:push("playing")
    end
end