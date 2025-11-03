scaleX,scaleY = 3,3-- universal scale values
success = love.window.setMode(320*scaleX,240*scaleY,{})
width,height = love.graphics.getWidth()/16, love.graphics.getHeight()/16
shadowRes = 4
fogFactor = 1
function love.load()
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest","nearest")

    player = {}
    mapData = generate_maze(200,200,100)
    wallTextures = {love.graphics.newImage("wallTextures/MissingTexture.png"),love.graphics.newImage("wallTextures/Test1.png")} -- add wall textures here
    player.spritesheets = {empty=love.graphics.newImage("playerSprites/Empty.png")}
    player.grid = {}
    player.grid.empty = anim8.newGrid(16,16,player.spritesheets.empty:getWidth(),player.spritesheets.empty:getHeight())

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

    player.x,player.y,player.dir = 50,50.5,"down"  -- player variables
    camX,camY = 1,1
    lights = {}
    shadowData = {}
    end



function love.update(dt)
    lights = {}
    shadowData = {}
    for y=0, height*16/shadowRes do
        local line = {}
        for x=0, width*16/shadowRes do
            table.insert(line,1)
        end
        table.insert(shadowData,line)
    end
    table.insert(lights,{0,0,0})
    lights[1][1]=player.x
    lights[1][2]=player.y
    lights[1][3]= 2
    local isMoving = false
    if love.keyboard.isDown("right") then 
        player.x = player.x + 1/16
        player.dir = "right"
        isMoving = true
    end
    if love.keyboard.isDown("left") then 
        player.x = player.x - 1/16
        player.dir = "left"
        isMoving = true
    end
    if love.keyboard.isDown("down") then 
        player.y = player.y + 1/16
        player.dir = "down"
        isMoving = true
    end
    if love.keyboard.isDown("up") then
        player.y = player.y - 1/16
        player.dir = "up"
        isMoving = true
    end

    local state = isMoving and "move" or "idle"
    player.anim = player.animations.empty.torch4[state][player.dir]

    player.anim:update(dt)
    update_shadows()
end



function love.draw()
    camX = math.max(player.x-width/(2*scaleX),1)
    camY = math.max(player.y-height/(2*scaleY),1)
    love.graphics.setColor(1,1,1,1)
    for y=0, height do
        for x=0, width do
            if mapData[math.floor(y+camY)][math.floor(x+camX)] == 1 then
                love.graphics.draw(wallTextures[1] ,--[[]] x*16*scaleX-(camX%1)*16*scaleX ,--[[]] y*16*scaleY-(camY%1)*16*scaleY,0,scaleX,scaleY)
            end
        end
    end
    love.graphics.print(camX.." "..camY,0,0)
    love.graphics.print(player.x.." "..player.y,0,10)
    love.graphics.print(width.." "..height,0,20)
    player.anim:draw(player.spritesheets.empty, (player.x-camX)*16*scaleX-(6.5*scaleX), (player.y-camY)*16*scaleY-(8*scaleY),nil,scaleX,scaleY)
    for y=1, height*16/shadowRes do
        for x=1, width*16/shadowRes do
            love.graphics.setColor(0,0,0,shadowData[y][x])
            love.graphics.rectangle("fill",(x-1)*scaleX*shadowRes,(y-1)*scaleY*shadowRes,scaleX*shadowRes,scaleY*shadowRes)
        end
    end
end






function update_shadows()
    for y=1, height*16/shadowRes do
        for x=1, width*16/shadowRes do
            for i=1, #lights do
                shadowX = (x-1)*(shadowRes/16) + camX
                shadowY = (y-1)*(shadowRes/16) + camY
                distX = math.abs(lights[i][1]-shadowX)
                distY = math.abs(lights[i][2]-shadowY)
                dist = math.sqrt(distX^2+distY^2)
                if 1 - ((dist * fogFactor) / lights[i][3])^2 then
                    --[[if within beam of light]]
                    --[[if it has line of sight]]
                    shadowData[y][x] = shadowData[y][x] - (1 - ((dist * fogFactor) / lights[i][3])^2)
                end
            end
        end
    end
end










































-- origin shift algorithm
-- programmed by epiccooldog

function generate_maze(width, height, seed)
    math.randomseed(seed)

    local direction_maze = {}
    local maze = {}

    -- creates a boring but perfect maze
    for y = 1, height do
        local temp = {}
        for x = 1, width do
            if x == width and y == height then
                table.insert(temp, "o")
            
            elseif x == width then
                table.insert(temp, "d")
            else
                table.insert(temp, "r")
            end
        end

        table.insert(direction_maze, temp)
    end

    -- makes the maze cool :O

    local iterations = width * height * 20
    local o = {x = width, y = height}

    for _ = 1, iterations do
        options = {}

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

        choice = options[math.random(#options)]

        direction_maze[o.y][o.x] = choice

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

    for t_y in pairs(direction_maze) do
        line = ""
        for t_x in pairs(direction_maze[t_y]) do
            line = line..direction_maze[t_y][t_x]..","
        end
        print(line)
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

            if direction_maze[y][x] == "u" then
                maze[t_y-1][t_x] = 0
                maze[t_y-2][t_x] = 0
            end
            if direction_maze[y][x] == "d" then
                maze[t_y+1][t_x] = 0
                maze[t_y+2][t_x] = 0
            end
            if direction_maze[y][x] == "l" then
                maze[t_y][t_x-1] = 0
                maze[t_y][t_x-2] = 0
            end
            if direction_maze[y][x] == "r" then
                maze[t_y][t_x+1] = 0
                maze[t_y][t_x+2] = 0
            end
        end
    end

    return maze
end
