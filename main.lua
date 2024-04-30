---@diagnostic disable: lowercase-global, undefined-field
--[[
    Program to convert images into ASCII characters

    TODO:
        go through the entire line at once (threads?)
        optimise

    ORDER OF OPERATIONS: (final)
    1. find all images in folder
    2. load image data and drawable image
    3. convert image to grayscale and enlarge (grayscale to simplify, enlarge to increase detail)
        3.1. find average of color in the area
        3.2. set color to the average
        3.3. move to next area
    4. convert grayscale image to ASCII

    MODES
    #: STEPS ON    | NOTES
    0: mouse click | debugging
    1: frame       | debugging at faster speed
    2: frame       | final(-ish)
]]

function loadDir(path) --[[returns the files in the given directory
    ]]
    files = love.filesystem.getDirectoryItems(path)
    return files
end

function loadImage (mode, path, data) --[[takes in a path and returns the image
    TODO:
        add validaction of path
    ]]
    if mode == 1 then
        local info = love.filesystem.getInfo(path)
        if info then
            return love.graphics.newImage(path)
        end
    else
        return love.graphics.newImage(data)
    end
end

function loadData(path) --[[takes in a path and returns imageData
    TODO:
        add validation of path

    get image data from path and returns it
    ]]
    return love.image.newImageData(path)
end

function getpixel(coord, img, data) --[[takes image data and returns pixel info
    ]]
    local pr = 0
    local pg = 0
    local pb = 0
    pr, pg, pb = data:getPixel(coord[1], coord[2])
    local pixel = {pr, pg, pb}
    return pixel
end

function setpixel(img, data, xstep, ystep)
    local ave = (img.ave[1] + img.ave[2] + img.ave[3]) / 3
    for i = 0, ystep - 1 do
        for j = 0, xstep - 1 do
            data:setPixel(img.coordO[1] + j, img.coordO[2] + i, ave, ave, ave)
        end
    end
    --img.drawableO = love.graphics.newImage(img.dataO)
end

function getPixelAve(img, w, h, data) --calculate average values for pixels in an area
    local tr = 0
    local tg = 0
    local tb = 0
    for i = 0, h - 1 do
        for j = 0, w - 1 do
            local pixel = getpixel({img.coord[1] + j, img.coord[2] + i}, img, data)
            tr = tr + pixel[1]
            tg = tg + pixel[2]
            tb = tb + pixel[3]
        end
    end
    ar = tr / (w * h)
    ag = tg / (w * h)
    ab = tb / (w * h)
    if ar > 1 then
        ar = 1
    end
    if ag > 1 then
        ag = 1
    end
    if ab > 1 then
        ab = 1
    end
    local ave = {ar, ag, ab}
    return ave
end

function getluminance(ave) --calculate the brightness of the area
    local ar = ave[1]
    local ag = ave[2]
    local ab = ave[3]
    local luminance = (0.2126 * ar) + (0.7152 * ag) + (0.0722 * ab)
    return luminance
end

function pixel_convert(img) --return which character to ad to the line
    local brightness = img.lumi
    local charIndex = 1

    for i = 1, 10, 1 do
        if (brightness >= CHAR[i][1]) and (brightness <= CHAR[i][2]) then
            img.line = img.line .. CHAR[i][3]
        end
    end

    --[[
    while charIndex <= 10 do
        if (brightness >= CHAR[charIndex][1]) and (brightness <= CHAR[charIndex][2]) then
            img.line = img.line .. CHAR[charIndex][3]
        else
            charIndex = charIndex + 1
        end
    end
    ]]
end

function step(img, xstep, ystep)
    --[[

        steps to convert pixel area:
        1. get average of color values in the area
        2. calculate luminocity with the average
        3. add a char to the line using luminocity to determine char added
        4. next step

        steps to convert image: 1
        1. convert pixel area
        2. increase progress bar
        3. go to next area
        4. if the next area is out of bounds 
            4.1. add the line to the table of lines
            4.2. reset the line and position
            4.3. go to next line
            4.4. if the next line is out of bounds
                4.4.1. add the table of lines to the table of converted images
                4.4.2. go to next image
                4.4.3. if no more image to process
                    4.4.4.1. flag done processing

        I:
        1256
        3478

        O:
        11225566
        11225566
        33447788
        33447788
    ]]
    --enlarge and grayscale I:1
    loadingBar(progress)
    if img.grayed then
        --convert to ascii
        img.ave = getPixelAve(img, 7, 14, img.dataI) --average values of pixels in area
        img.lumi = getluminance(img.ave)
        pixel_convert(img)
    else
        img.ave = getPixelAve(img, 7, 14, img.dataI) --average values of pixels in area
        grayscale (img, 14, 28)
        img.coordO[1] = img.coordO[1] + xstep --go to O:2
        img.coordO[1] = img.coordO[1] + xstep --go to O:2
    end
    img.coord [1] = img.coord [1] + xstep --go to I:2
    
    if  img.coord [1] >= img.dimI [1] then --at the end of the line
        img.coord [1]  = 0                         --go back to the start
        img.coord [2]  = img.coord[2] + ystep      --go to next line
        if img.grayed == false then                
            img.coordO[1]  = 0                     --go back to the start
            img.coordO[2]  = img.coordO[2] + ystep --go to next line
            img.coordO[2]  = img.coordO[2] + ystep --go to next line
        else
            img.line = img.line
            table.insert(img.text, img.line)
            img.line = "\n"
        end
        if  img.coord[2] >= img.dimI[2] then --at the end of the image
            img.coord[1]  = 0 --reset to the start of the line
            img.coord[2]  = 0 --reset to the start of the image
            if img.grayed == false then
                img.grayed = true
                img.dataI  = img.dataO
                img.drawableI = loadImage(2, "", img.dataI)
                img.dimI  [1] = img.dimO[1]
                img.dimI  [2] = img.dimO[2]
                img.coordO[1] = 0 --reset to the start of the line
                img.coordO[2] = 0 --reset to the start of the image
            else --image has been converted to ascii
                img.converted = true
                saveimg(img)
                if curimg + 1 >= #imgs then
                    processing = false
                    curimg = 1
                else
                    curimg = curimg + 1
                    newImg({0, 0}, imgs[curimg])
                end
            end
        end
    end
end

function love.load()
    love.window.maximize()
    FONT = love.graphics.newFont("cour.ttf")
    love.graphics.setFont(FONT)

    MODE = 1
    processing = true
    progress = {}
        progress.barcur      = ""
        progress.stepscur    = 0
        progress.neededcur   = 0
        progress.donecur     = 0
        progress.bartotal    = ""
        progress.stepstotal  = 0
        progress.neededtotal = 0
        progress.donetotal   = 0
    stepSize = 8970
    pathI = "/images/frames"
    pathO = "/images/ascii"
    imgs = loadDir(pathI)
    curimg = 1
    
    IMGS = {}
    newImg({0, 0}, imgs[curimg])
    progress.neededtotal = progress.neededcur * #imgs

    music = love.audio.newSource("badapple.mp3", "stream")
    video = love.graphics.newVideo("badapple.ogv")

    --[[
    thread   = love.thread.newThread("threadCode.lua")
    thread:start()
    channel = {}
    channel.I = love.thread.newChannel()
    channel.O = love.thread.newChannel()
    playing = false
    ]]

    CHAR = {
        {0.0, 0.1, " "}, --luminance >= 0.0 and luminance <= 0.1 then char = ' '
        {0.1, 0.2, "."}, --luminance >= 0.1 and luminance <= 0.2 then char = '.'
        {0.2, 0.3, ":"}, --luminance >= 0.2 and luminance <= 0.3 then char = ':'
        {0.3, 0.4, "-"}, --luminance >= 0.3 and luminance <= 0.4 then char = '-'
        {0.4, 0.5, "="}, --luminance >= 0.4 and luminance <= 0.5 then char = '='
        {0.5, 0.6, "+"}, --luminance >= 0.5 and luminance <= 0.6 then char = '+'
        {0.6, 0.7, "*"}, --luminance >= 0.6 and luminance <= 0.7 then char = '*'
        {0.7, 0.8, "#"}, --luminance >= 0.7 and luminance <= 0.8 then char = '#'
        {0.8, 0.9, "%"}, --luminance >= 0.8 and luminance <= 0.9 then char = '%'
        {0.9, 1.0, "@"}, --luminance >= 0.9 and luminance <= 1.0 then char = '@'
    }

    spaces = false
end

function newImg(coord, name)
    IMG = {}
    IMG.grayed = false
    IMG.converted = false
    IMG.coord = coord
    IMG.coordO = {0, 0}
    IMG.pathI = pathI .. "/" .. name
    IMG.pathO = pathO .. "/" .. name
    IMG.drawableI = loadImage(1, IMG.pathI)
    IMG.dataI = loadData(IMG.pathI)
    IMG.dimI = {0, 0}
    IMG.dimI[1], IMG.dimI[2] = IMG.dataI:getDimensions()
    IMG.imgAve = {}
    IMG.dimO = {IMG.dimI[1] * 2, IMG.dimI[2] * 2}
    IMG.dataO = love.image.newImageData(IMG.dimO[1], IMG.dimO[2])
    IMG.drawableO = loadImage(2, IMG.pathO, IMG.dataO)
    IMG.text = {}
    IMG.line = "\n"
    IMG.ave = {0, 0, 0}
    IMG.lumi = 0

    table.insert(IMGS, IMG)
    progress.neededcur = ((IMG.dimI[1] / 7) * (IMG.dimI[2] / 14)) + ((IMG.dimO[1] / 7) * (IMG.dimO[2] / 14))
    progress.stepscur = 0
end

function saveimg(img)
    local name = img.pathO
    local savename = string.sub(name, 1, #name-3) .. "txt"
    f = love.filesystem.newFile(savename)
    f:open("w")
    for i = 1, #img.text do
        f:write(img.text[i])
    end
    f:close()
    --love.filesystem.write(savename, img.text)
end

function populateImage(data, w, h)
    for y = 1, h-1 do
        for x = 1, w-1 do
            data:setPixel(x, y, 1, 1, 1)
        end
    end
end

function grayscale(img, xstep, ystep) --[[converts the image into grascale before converting into ASCII
    steps:
    1. get the average colors for the area
    2. set all colors in the area to this average
    3. move to next area
    4. repeat until image is converted
    ]]
    setpixel(img, img.dataO, xstep, ystep)
end

function love.keypressed(key)
    if     key == "escape" then
        --i = channel.I:release()
        --o = channel.O:release()
        --if i and o then
           love.event.quit()
        --end
    elseif key == "space"  then
        if spaces then
            spaces = false
            stepSize = 66
        else
            spaces = true
            stepSize = 1
        end
    end
end

function loadingBar(progress)
    progress.stepscur   =  progress.stepscur   + 1
    progress.donecur    = (progress.stepscur   / progress.neededcur  ) * 100
    progress.stepstotal =  progress.stepstotal + 1
    progress.donetotal  = (progress.stepstotal / progress.neededtotal) * 100
    progress.barcur     = ""
    progress.bartotal   = ""
    
    for c = 1, progress.donecur   / 5 do
               progress.barcur   = progress.barcur   .. "-"
    end        
    for t = 1, progress.donetotal / 5 do
               progress.bartotal = progress.bartotal .. "-"
    end
end

function love.update(dt)
    --[[
        find current pixel's values
        convert to text
        add to line
        advance
        if new position out of line
        reset to start of line
        go to next line
        if next line out of bounds
        reset position to start of line and image
        processing done
    ]]
    if processing then
        if MODE == 0 then --step through on mouse click
            function love.mousepressed()
                for i = 1, stepSize do
                    step(IMGS[curimg], 7, 14)
                    --loadingBar(progress)
                    if processing == false then
                        break
                    end
                end
            end
        elseif MODE == 1 or MODE == 2 then --run at normal speed
            if MODE == 1 then --debug at normal speed
                for i = 1, stepSize do
                    step(IMGS[curimg], 7, 14)
                    if processing == false then
                        break
                    end
                end
            else --run normally with no debugging
                for i = 1, stepSize do
                    step(IMGS[curimg], 7, 14)
                    if processing == false then
                        break
                    end
                end
            end
        end
    else
        --love.event.quit()
        --[[
        if not music:isPlaying() then
            love.audio.play(music)
        end
        ]]

        --[[
            channel I gets data from thread
            channel O send data to   thread
        ]]
        --if not threadUp then --start thread if it is not up yet
        --    thread:start()
        --else
        --    i = channel.I:pop() --receive data from thread
        --    if i then --if there is data then the thread is ready for the next image
        --        --love.graphics.print(tostring(i))
        --        channel.O:push(IMGS[curimg].text) --send next image to thread
        --    end
        --end

        --if not playing then
        --    channel.O:push(video)
        --end
        --threadIn = channel.I:pop()
        --if threadIn == "playing" then
            if curimg < #IMGS then
                curimg = curimg + 1
            else
                love.event.quit()
            end
        --end


        --love.graphics.setColor(0, 1, 0)
    end
end

function love.draw()
    if processing == false then --will display finished product
        --love.graphics.print("All done")
        --for i = 1, #IMGS do
            
        for j = 1, #IMGS[curimg].text do
            love.graphics.print(IMGS[curimg].text[j], 0, j * 14)
        end
        love.timer.sleep((1/30)*10)
        --end
        --love.graphics.print(tostring(#IMGS))
    else
        if MODE == 0 or MODE == 1 then
            if IMGS[curimg].grayed == false then --first pass
                love.graphics.draw(IMGS[curimg].drawableI, 0)
            elseif IMGS[curimg].converted == false then --second pass
                love.graphics.draw(IMGS[curimg].drawableI, 0)
            end
            love.graphics.rectangle("line", IMGS[curimg].coord [1]     , IMGS[curimg].coord [2]                       , 7  , 14 )
            love.graphics.rectangle("line", IMGS[curimg].coord [1] + 7 , IMGS[curimg].coord [2]                       , 7  , 14 )
            love.graphics.rectangle("line", 0                          , IMGS[curimg].coord [2] + 14                  , 7  , 14 )
            love.graphics.rectangle("line", IMGS[curimg].coordO[1]     , IMGS[curimg].coordO[2] + IMGS[curimg].dimI[2], 14 , 28 )
            love.graphics.rectangle("line", 0                          , 0                                            , 483, 364)
            love.graphics.rectangle("line", 0                          , 0                                            , 966, 728)
            love.graphics.print(table.concat({
                "current image: " .. IMGS[curimg].pathI,
                "processing done on current image: " .. string.format("%.2f", progress.donecur  ) .. "% = " ..  progress.stepscur   .. " / " ..progress.neededcur  ,
                "processing done on current image: " .. progress.barcur     ,
                "processing done on all     image: " .. string.format("%.2f", progress.donetotal) .. "% = " ..  progress.stepstotal .. " / " ..progress.neededtotal,
                "processing done on all     image: " .. progress.bartotal   ,
                " x: " .. IMGS[curimg].coord [1] .. " |  y: " .. IMGS[curimg].coord [2],
                "Ox: " .. IMGS[curimg].coordO[1] .. " | Oy: " .. IMGS[curimg].coordO[2],
                "step size: " .. stepSize,
                "current width: " .. IMGS[curimg].dimI[1] .. " | height: " .. IMGS[curimg].dimI[2],
                "grayed  width: " .. IMGS[curimg].dimO[1] .. " | height: " .. IMGS[curimg].dimO[2],
                "converted to grayscale: " .. tostring(IMGS[curimg].grayed),
                "luminance: " .. tostring(IMGS[curimg].lumi),
                "average: {"  .. tostring(IMGS[curimg].ave[1] .. ", " .. tostring(IMGS[curimg].ave[2]) .. ", " .. tostring(IMGS[curimg].ave[3]) .. "}"),
                "line: " .. IMGS[curimg].line
            }, '\n'), 1000)
        end
    end
end