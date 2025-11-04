-- Goofy Game

scaleX,scaleY = 3,3-- universal scale values
success = love.window.setMode(320*scaleX,240*scaleY,{}) -- creates window
width,height = love.graphics.getWidth()/16, love.graphics.getHeight()/16
fogFactor = 1

function love.load()
    -- loads in anim8 library
    anim8 = require 'libraries/anim8'
    -- sets filter to nearest to avoid blurry pixels
    love.graphics.setDefaultFilter("nearest","nearest")

    -- creates player object
    player = {}

    mapData = generate_maze(200,200,100) -- generates a maze of size 200, 200 and using the random seed 100

    wallTextures = {love.graphics.newImage("wallTextures/MissingTexture.png"),love.graphics.newImage("wallTextures/Test1.png")} -- add wall textures here

    player.spritesheets = {empty=love.graphics.newImage("playerSprites/Empty.png")} -- player spritesheet image
    player.grid = {}
    player.grid.empty = anim8.newGrid(16,16,player.spritesheets.empty:getWidth(),player.spritesheets.empty:getHeight())

    -- setting up player animatons; if it works dont break it
    player.animations = {}
    player.animations.empty = {}
    player.animations.empty.torch4 = {}
    player.animations.empty.torch4.move = {}
    player.animations.empty.torch4.idle = {}
    player.animations.empty.torch4.move.down = anim8.newAnimation( player.grid.empty('1-4', 3), .2)
    player.animations.empty.torch4.move.left = anim8.newAnimation( player.grid.empty('5-8', 3), .2)
    player.animations.empty.torch4.move.up = anim8.newAnimation( player.grid.empty('1-4', 14), .2)
    player.animations.empty.torch4.move.right = anim8.newAnimation( player.grid.empty('5-8', 14), .2)
    player.animations.empty.torch4.idle.down = anim8.newAnimation( player.grid.empty('1-2', 2), .2)
    player.animations.empty.torch4.idle.left = anim8.newAnimation( player.grid.empty('5-6', 2), .2)
    player.animations.empty.torch4.idle.up = anim8.newAnimation( player.grid.empty('1-2', 13), .2)
    player.animations.empty.torch4.idle.right = anim8.newAnimation( player.grid.empty('5-6', 13), .2)

    player.x,player.y,player.dir = 2.5,2.5,"down"  -- player variables
    camX,camY = 1,1 -- camera x and y position
    lights = {}
    shadowData = {}
    end



function love.update(dt)

    -- kiwi you comment this cuz i have no fucking clue how it works - epic
    lights = {}
    shadowData = {}
    for y=0, height*16/16 do
        local line = {}
        for x=0, width*16/16 do
            table.insert(line,1)
        end
        table.insert(shadowData,line)
    end
    table.insert(lights,{0,0,0})
    lights[1][1]=player.x
    lights[1][2]=player.y
    lights[1][3]= 4


    local isMoving = false

    -- moving right and checking if you can
    if love.keyboard.isDown("right") and get_tile(player.x + 1/16, player.y + 0.45, mapData) == 0 and get_tile(player.x + 1/16, player.y, mapData) == 0 then 
        player.x = player.x + 1/16
        player.dir = "right"
        isMoving = true
    end

    -- moving left and checking if you can
    if love.keyboard.isDown("left") and get_tile(player.x - 1/16, player.y + 0.45, mapData) == 0 and get_tile(player.x - 1/16, player.y, mapData) == 0 then 
        player.x = player.x - 1/16
        player.dir = "left"
        isMoving = true
    end

    -- moving down and checking if you can
    if love.keyboard.isDown("down") and get_tile(player.x, player.y + 1/16 + 0.45, mapData) == 0 then 
        player.y = player.y + 1/16
        player.dir = "down"
        isMoving = true
    end

    -- moving up and checking if you can
    if love.keyboard.isDown("up") and get_tile(player.x, player.y - 1/16, mapData) == 0 then
        player.y = player.y - 1/16
        player.dir = "up"
        isMoving = true
    end

    -- obvious stuff
    local state = isMoving and "move" or "idle"
    player.anim = player.animations.empty.torch4[state][player.dir]

    player.anim:update(dt)
    update_shadows()
end



function love.draw()
    -- updates cam position to not show outside of maze (but it should be in update no?)
    camX = math.max(player.x-width/(2*scaleX),1)
    camY = math.max(player.y-height/(2*scaleY),1)

    -- sets color to white
    love.graphics.setColor(1,1,1,1)


    -- drawing walls and eventually paths
    for y=0, height do
        for x=0, width do
            if mapData[math.floor(y+camY)][math.floor(x+camX)] == 1 then -- checks if it is a wall
                -- TODO: only draw walls close to player to get more of them fps
                love.graphics.draw(wallTextures[1],tiles_to_pixels(x,"X"),tiles_to_pixels(y,"Y"),0,scaleX,scaleY) -- goofy drawing for math
            end
        end
    end

    
    -- drawing lighting that idk how it works and prob will be replaced soon
    player.anim:draw(player.spritesheets.empty, (player.x-camX)*16*scaleX-(6.5*scaleX), (player.y-camY)*16*scaleY-(8*scaleY),nil,scaleX,scaleY)
    for y=1, height*16/16 do
        for x=1, width*16/16 do
            love.graphics.setColor(0,0,0,shadowData[y][x])
            love.graphics.rectangle("fill",tiles_to_pixels(x-1,"X"),tiles_to_pixels(y-1,"Y"),scaleX*16,scaleY*16)
        end
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(camX.." "..camY,0,0)
    love.graphics.print(player.x.." "..player.y,0,10)
    love.graphics.print(width.." "..height,0,20)
end


-- no clue how it works, kiwi u comment it when u update
function update_shadows()
    distances = {}
    distances.x1 = {}
    distances.y1 = {}
    distances.x2 = {}
    distances.y2 = {}
    for y=1, height*16/16 do
        for x=1, width*16/16 do
            for i=1, #lights do
                shadowX = (x-1) + camX
                shadowY = (y-1) + camY
                distX = lights[i][1]-shadowX
                distY = lights[i][2]-shadowY
                dist = math.sqrt(distX^2 + distY^2)
                if  math.max(0, 1 - ((dist * fogFactor) / lights[i][3])^2) > 0 then
                    shadowData[y][x] = shadowData[y][x] - (1 - ((dist * fogFactor) / lights[i][3])^2)
                end
            end
        end
    end
end



function tiles_to_pixels(tiles,XorY)
    if XorY == "X" then
        return (tiles -(camX%1))*16*scaleX
    elseif XorY == "Y" then
        return (tiles -(camY%1))*16*scaleY
    end
end



-- origin shift algorithm
-- programmed by epiccooldog

function generate_maze(width, height, seed)
    math.randomseed(seed) -- sets the math.random seed

    local direction_maze = {} -- maze saved as directions of paths
    local maze = {} -- maze saved as 1s being walls and 0s being paths

    -- creates a boring but perfect maze that looks like this (note this example is represented in 1s and 0s, but it actually makes a direction maze):
    -- 1 1 1 1 1 1
    -- 1 0 0 0 0 1
    -- 1 1 1 1 0 1
    -- 1 0 0 0 0 1
    -- 1 1 1 1 0 1
    -- 1 0 0 0 0 1
    -- 1 1 1 1 1 1
    for y = 1, height do
        local temp = {} -- singular line in the directional maze
        for x = 1, width do
            if x == width and y == height then
                table.insert(temp, "o") -- origin point; no direction
            
            elseif x == width then
                table.insert(temp, "d") -- down
            else
                table.insert(temp, "r") -- right
            end
        end

        table.insert(direction_maze, temp) -- adds line to maze
    end

    -- makes the maze cool :O

    local iterations = width * height * 20 -- number of times maze will be changed
    local o = {x = width, y = height} -- origin position stays tracked

    for _ = 1, iterations do
        options = {}

        -- adds all possible directional options to move origin
        if o.x > 1 then
            table.insert(options, "l")
        end
        if o.x < width then
            table.insert(options, "r")
        end
        if o.y > 1 then
            table.insert(options, "u")
        end
        if o.y < height then
            table.insert(options, "d")
        end

        -- chooses a direction to move origin to
        choice = options[math.random(#options)]

        direction_maze[o.y][o.x] = choice

        -- applies change based on where origin moves
        if choice == "u" then
            direction_maze[o.y-1][o.x] = "o"
            o = {x = o.x, y = o.y-1}
        end
        if choice == "d" then
            direction_maze[o.y+1][o.x] = "o"
            o = {x = o.x, y = o.y+1}
        end
        if choice == "l" then
            direction_maze[o.y][o.x-1] = "o"
            o = {x = o.x-1, y = o.y}
        end
        if choice == "r" then
            direction_maze[o.y][o.x+1] = "o"
            o = {x = o.x+1, y = o.y}
        end
    end

    -- converting to table of 1s and 0s :D

    for y = 1, height*2 + 1 do
        local temp = {}
        for x = 1, width*2 + 1 do
            table.insert(temp, 1)  -- Initialize all cells as walls
        end
        table.insert(maze, temp)  -- Add row to maze
    end

    for y = 1, height do
        for x = 1, width do
            local t_x = x*2
            local t_y = y*2

            -- note that by "clear" i mean changing 1s to 0s

            if direction_maze[y][x] == "u" then -- clears yowards
                maze[t_y-1][t_x] = 0
                maze[t_y-2][t_x] = 0
            end
            if direction_maze[y][x] == "d" then -- clears downwards
                maze[t_y+1][t_x] = 0
                maze[t_y+2][t_x] = 0
            end
            if direction_maze[y][x] == "l" then -- clears to the left 
                maze[t_y][t_x-1] = 0
                maze[t_y][t_x-2] = 0
            end
            if direction_maze[y][x] == "r" then -- clears to the right
                maze[t_y][t_x+1] = 0
                maze[t_y][t_x+2] = 0
            end
        end
    end

    return maze
end

-- this function is trivial and is left as a challenge to the reader to understand
function get_tile(x, y, maze)
    local tile_x = math.floor(x)
    local tile_y = math.floor(y)

    local tile = maze[tile_y][tile_x]

    return tile
end
