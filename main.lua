-- Goofy Game

scaleX,scaleY = 3,3-- universal scale values
success = love.window.setMode(320*scaleX,240*scaleY,{}) -- creates window
width,height = love.graphics.getWidth()/16, love.graphics.getHeight()/16
fogFactor = .15
mazeWidth, mazeHeight = 200, 200
seed = os.time()
monsters_amount = 150
damage_overlay = 0

function love.load()
    -- touch variables
    Tid,Tx,Ty,Tp = 0,0,0,0
    -- loads in anim8 library
    anim8 = require 'libraries/anim8'
    -- sets filter to nearest to avoid blurry pixels
    love.graphics.setDefaultFilter("nearest","nearest")

    font = love.graphics.newFont(11)
    big_font = love.graphics.newFont(20)
    love.graphics.setFont(font)

    --[[
    items
    id = unique id for each item
    texture = the texture displayed in the invintory
    max_stack_size = the max amount of items in one slot
    playerAnim = the animation that is used by the player (if there is none for the item use "empty")
    ]]
    items = {}
    items.coal = {id=1, texture=love.graphics.newImage("itemTextures/coal.png"), max_stack_size=8, playerAnim="empty"}
    items.gun = {id=2, texture=love.graphics.newImage("itemTextures/gun.png"), max_stack_size=1, playerAnim="gun"}

    monsters = {}
    monsters.zombie = {texture=love.graphics.newImage("monsterTextures/zombie.png"), damage=2, speed=1/20}
    loaded_monsters = {}
    -- loaded_monsters[1] = {monster=monsters.zombie, x=102, y=102}

    -- creates player object
    player = {}

    player.health = {}
    player.health.max = 20
    player.health.current = 20
    player.health.full_heart_texture = love.graphics.newImage("uiTextures/heart-full.png")
    player.health.half_heart_texture = love.graphics.newImage("uiTextures/heart-half.png")
    player.health.empty_heart_texture = love.graphics.newImage("uiTextures/heart-empty.png")

    mapData = generate_maze(mazeWidth, mazeHeight, seed) -- generates a maze

    for y = 0, 3 do
        for x = 0, 3 do
            mapData[(mazeHeight/2) + y][(mazeWidth/2) + x] = 0
        end
    end

    wallTextures = {love.graphics.newImage("wallTextures/path.png"),love.graphics.newImage("wallTextures/wall.png")} -- add wall textures here

    player.spritesheets = {} -- player spritesheet image
    player.spritesheets.empty = love.graphics.newImage("playerSprites/empty.PNG")
    player.spritesheets.gun = love.graphics.newImage("playerSprites/gun.PNG")
    player.spritesheets.sword = love.graphics.newImage("playerSprites/sword.PNG")
    player.grid = {}
    player.grid.empty = anim8.newGrid(16,16,player.spritesheets.empty:getWidth(),player.spritesheets.empty:getHeight())
    player.grid.gun = anim8.newGrid(16,16,player.spritesheets.empty:getWidth(),player.spritesheets.empty:getHeight())
    player.grid.sword = anim8.newGrid(16,16,player.spritesheets.empty:getWidth(),player.spritesheets.empty:getHeight())

    -- inventory
    player.inventory = {}
    player.inventory.contents = {}
    player.inventory.slot_number = 3
    player.inventory.slot_texture = love.graphics.newImage("uiTextures/inventory-slot.png")

    for x = 1, player.inventory.slot_number do
        player.inventory.contents[x] = {item="empty", amount=nil}
    end

    -- just for testing
    player.inventory.contents[1] = {item=items.coal, amount=3}
    player.inventory.contents[2] = {item=items.coal, amount=2}
    player.inventory.contents[3] = {item=items.coal, amount=1}

    -- setting up player animatons; if it works dont break it
    player.animations = {}
    player.animations.empty = {}
    for key, item in pairs(items) do
        player.animations[item.playerAnim] = {}
        for torchIdx=1, 4 do
            player.animations[item.playerAnim]["torch"..torchIdx] = {}
            for animIdx=1, 2 do
                local animType = (animIdx == 1 and "idle") or (animIdx == 2 and "move")
                player.animations[item.playerAnim]["torch"..torchIdx][animType] = {}
                for directionIdx=1, 4 do
                    local direction = (directionIdx == 1 and "down") or (directionIdx == 2 and "left") or (directionIdx == 3 and "right") or (directionIdx == 4 and "up")
                    local spritesheetX = ''
                    if animType == "move" then 
                        spritesheetX = (directionIdx == 1 and '1-4') or (directionIdx == 2 and '5-8') or (directionIdx == 3 and '5-8') or (directionIdx == 4 and '1-4')
                    else
                        spritesheetX = (directionIdx == 1 and '1-2') or (directionIdx == 2 and '5-6') or (directionIdx == 3 and '5-6') or (directionIdx == 4 and '1-2')
                    end
                    local spritesheetY = (directionIdx == 1 and 1 + (animIdx)) or (directionIdx == 2 and 1 + (animIdx)) or (directionIdx == 3 and 12 + (animIdx)) or (directionIdx == 4 and 12 + (animIdx))
                    player.animations[item.playerAnim]["torch"..torchIdx][animType][direction] = anim8.newAnimation( player.grid[item.playerAnim](spritesheetX , spritesheetY), .2)
                end
            end
        end
    end

    player.x,player.y,player.dir = mazeWidth/2+3, mazeHeight/2+3,"down"  -- player variables
    camX,camY = 1,1 -- camera x and y position
    lights = {}
    shadowData = {}

    for x = 1, monsters_amount do
        ::retry::
        local posX = math.random(1, mazeWidth)
        local posY = math.random(1, mazeHeight)
        if get_tile(posX, posY, mapData) == 1 or (math.abs(player.x - posX) <= 6 and math.abs(player.y - posY) <= 6) then
            goto retry
        end
        table.insert(loaded_monsters, {monster=monsters.zombie, x=posX, y=posY, health=20, last_attack=os.time()})
    end
end



function love.update(dt)

    -- kiwi you comment this cuz i have no [expletive] clue how it works - epic
    -- just setting the shadowData table to be all black so the shadow script can brighten it up later -SpaceKiwi
    lights = {}
    shadowData = {}
    for y=0, height*16/16 do
        local line = {}
        for x=0, width*16/16 do
            table.insert(line,1)
        end
        table.insert(shadowData,line)
    end
    -- adding the light at the players location
    table.insert(lights,{0,0,0})
    lights[1][1]=player.x
    lights[1][2]=player.y
    lights[1][3]=.6


    local isMoving = false


    -- moving down and checking if you can
    if love.keyboard.isDown("s") or Ty > love.graphics.getHeight()*.9 and Tx > love.graphics.getWidth()*.5 then 
        if get_tile(player.x, player.y + 1/8 + 0.45, mapData) == 0 then
           player.y = player.y + 1/16
           player.dir = "down"
           isMoving = true
        end
    end

    -- moving up and checking if you can
    if love.keyboard.isDown("w") or Ty < love.graphics.getHeight()*.6 and Ty > love.graphics.getHeight()*.5 and Tx > love.graphics.getWidth()*.5 then
        if get_tile(player.x, player.y - 1/8, mapData) == 0 then
            player.y = player.y - 1/16
            player.dir = "up"
            isMoving = true
        end
    end
    
    -- moving right and checking if you can
    if love.keyboard.isDown("d") or Tx > love.graphics.getWidth()*.9 and Ty > love.graphics.getHeight()*.5 then 
        if get_tile(player.x + 1/8, player.y + 0.45, mapData) == 0 and get_tile(player.x + 1/8, player.y, mapData) == 0 then
            player.x = player.x + 1/16
            player.dir = "right"
            isMoving = true
        end
    end

    -- moving left and checking if you can
    if love.keyboard.isDown("a") or Tx < love.graphics.getWidth()*.6 and Tx > love.graphics.getWidth()*.5 and Ty > love.graphics.getHeight()*.5 then 
        if get_tile(player.x - 1/8, player.y + 0.45, mapData) == 0 and get_tile(player.x - 1/8, player.y, mapData) == 0 then
            player.x = player.x - 1/16
            player.dir = "left"
            isMoving = true
        end
    end

    -- obvious stuff
    local state = isMoving and "move" or "idle"
    player.anim = player.animations.empty.torch4[state][player.dir]

    player.anim:update(dt)
    update_shadows()

    -- monster ai

    for x=1, #loaded_monsters do
        local monster = loaded_monsters[x]
        local dirX = player.x - 0.5 - monster.x
        local dirY = player.y - 0.5 - monster.y

        local length = math.sqrt(dirX * dirX + dirY * dirY)

        if math.abs((player.x+0.5) - (monster.x+0.5)) <= 1 and math.abs((player.y+0.5) - (monster.y+0.5)) <= 1 and (os.time() - monster.last_attack) >= 0.5 then
            player.health.current = player.health.current - monster.monster.damage
            monster.last_attack = os.time()
            damage_overlay = 5
        end

        if player.health.current < 0 then
            player.health.current = 0
        end

        if length ~= 0 then
            dirX = dirX/length/100
            dirY = dirY/length/100

            if get_tile(monster.x + dirX + 0.25, monster.y + 0.25, mapData) == 0 and get_tile(monster.x + dirX + 0.75, monster.y + 0.75, mapData) == 0 then
                monster.x = monster.x + dirX
            end
            if get_tile(monster.x + 0.25, monster.y + dirY + 0.25, mapData) == 0 and get_tile(monster.x + 0.75, monster.y + dirY + 0.75, mapData) == 0 then
                monster.y = monster.y + dirY
            end 
        end
    end
end



function love.draw()
    -- updates cam position to not show outside of maze (but it should be in update no?)
    camX = math.max(player.x-width/(2*scaleX),1)
    camY = math.max(player.y-height/(2*scaleY),1)

    -- sets color to white
    love.graphics.setColor(1,1,1,1)

    if damage_overlay ~= 0 then
        love.graphics.setColor(1,0,0,1)
        damage_overlay = damage_overlay - 1
    end


    -- drawing walls and eventually paths
    for y=0, height do
        for x=0, width do
                -- TODO: only draw walls close to player to get more of them fps
                love.graphics.draw(wallTextures[mapData[math.floor(y+camY)][math.floor(x+camX)]+1],tiles_to_pixels(x,"X"),tiles_to_pixels(y,"Y"),0,scaleX,scaleY) -- goofy drawing for math
        end
    end

    for x = 1, #loaded_monsters do
        local monster = loaded_monsters[x]
        if math.abs(monster.x - player.x) < 10 and math.abs(monster.y - player.y) < 10 then
            love.graphics.draw(monster.monster.texture, (monster.x - camX) * 16 * scaleX, (monster.y - camY) * 16 * scaleY, 0, scaleX, scaleY)
        end
    end
    
    player.anim:draw(player.spritesheets.empty, (player.x-camX)*16*scaleX-(6.5*scaleX), (player.y-camY)*16*scaleY-(8*scaleY),nil,scaleX,scaleY)
    -- drawing lighting that idk how it works and prob will be replaced soon
    for y=1, height*16/16 do
        for x=1, width*16/16 do
            love.graphics.setColor(0,0,0,shadowData[y][x])
            love.graphics.rectangle("fill",tiles_to_pixels(x-1,"X"),tiles_to_pixels(y-1,"Y"),scaleX*16,scaleY*16) 
        end
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("camera: "..math.floor(camX).." "..math.floor(camY),0,0)
    love.graphics.print("player: "..math.floor(player.x).." "..math.floor(player.y),0,10)
    love.graphics.print("window size: "..width.." "..height,0,20)
    love.graphics.print("Touch pressed: ID " .. Tid .. " at (" .. Tx .. ", " .. Ty .. ") pressure:" .. Tp,0,30)

    for x = 1, player.inventory.slot_number do
        love.graphics.draw(player.inventory.slot_texture, love.graphics.getWidth()/2 - (player.inventory.slot_number*16*scaleX)/2 + (x-1)*scaleX*16, love.graphics.getHeight()-90, 0, scaleX, scaleY)
        if player.inventory.contents[x].item ~= "empty" then
            love.graphics.draw(player.inventory.contents[x].item.texture, love.graphics.getWidth()/2 - (player.inventory.slot_number*16*scaleX)/2 + (x-1)*scaleX*16, love.graphics.getHeight()-90, 0, scaleX, scaleY)
            love.graphics.setFont(big_font)
            love.graphics.print(player.inventory.contents[x].amount, love.graphics.getWidth()/2 - (player.inventory.slot_number*16*scaleX)/2 + (x-1)*scaleX*16+10*scaleX, love.graphics.getHeight()-90+8*scaleY)
            love.graphics.setFont(font)
        end
    end

    local temp_health = player.health.current
    for x = 0, player.health.max/2 do
        if temp_health > 1 then
            love.graphics.draw(player.health.full_heart_texture, love.graphics.getWidth() - ((10 * 9 * scaleX) - (x * 9 * scaleX)), 10, 0, scaleX, scaleY)
            temp_health = temp_health - 2
        elseif temp_health == 1 then
            love.graphics.draw(player.health.half_heart_texture, love.graphics.getWidth() - ((10 * 9 * scaleX) - (x * 9 * scaleX)), 10, 0, scaleX, scaleY)
            temp_health = temp_health - 1
        elseif temp_health == 0 then
            love.graphics.draw(player.health.empty_heart_texture, love.graphics.getWidth() - ((10 * 9 * scaleX) - (x * 9 * scaleX)), 10, 0, scaleX, scaleY)
        end
    end

    if Tid ~= 0 then
        love.graphics.setColor(1,1,1,.25)
        love.graphics.rectangle("fill",love.graphics.getWidth()*.5,love.graphics.getHeight()*.5,love.graphics.getWidth()*.5,love.graphics.getHeight()*.5)
    end
end


-- no clue how it works, kiwi u comment it when u update
function update_shadows()
    for y=1, height*16/16 do
        for x=1, width*16/16 do
            for i=1, #lights do
                local shadowX = (x-1) + camX
                local shadowY = (y-1) + camY
                local distX = lights[i][1]-shadowX
                local distY = lights[i][2]-shadowY
                local dist = math.sqrt(distX^2 + distY^2)
                if  math.max(0, 1 - ((dist * fogFactor) / lights[i][3])^2) > 0 then
                    if check_line_of_sight(shadowX,shadowY,lights[i][1],lights[i][2]) then
                        shadowData[y][x] = shadowData[y][x] - ((1 - ((dist * fogFactor) / lights[i][3])^2) * lights[i][3] / 4)
                    end
                    if check_line_of_sight(shadowX+1,shadowY,lights[i][1],lights[i][2]) then
                        shadowData[y][x] = shadowData[y][x] - ((1 - ((dist * fogFactor) / lights[i][3])^2) * lights[i][3] / 4)
                    end
                    if check_line_of_sight(shadowX,shadowY+1,lights[i][1],lights[i][2]) then
                        shadowData[y][x] = shadowData[y][x] - ((1 - ((dist * fogFactor) / lights[i][3])^2) * lights[i][3] / 4)
                    end
                    if check_line_of_sight(shadowX+1,shadowY+1,lights[i][1],lights[i][2]) then
                        shadowData[y][x] = shadowData[y][x] - ((1 - ((dist * fogFactor) / lights[i][3])^2) * lights[i][3] / 4)
                    end
                end
            end
        end
    end
end

function check_line_of_sight(x1, y1, x2, y2)
    --[[commented this out for now cause im a bit busy to fix these nonsensical bugs
    local distX = x2 - x1
    local distY = y2 - y1
    local dist = math.sqrt(distX^2 + distY^2)
    local step = 0.01 -- step size
    local steps = math.ceil(dist / step)
    local stepX = distX / steps
    local stepY = distY / steps

    local rayX, rayY = x1, y1

    for i = 1, steps do
        rayX = rayX + stepX
        rayY = rayY + stepY
        if math.floor(x1) ~= math.floor(rayX) or math.floor(y1) ~= math.floor(rayY) then -- checks if the current tile is not the tile we were previously on
            x1,y1 = rayX,rayY -- updates it so the previous if doesnt trigger on every cycle after we leave the first tile
            if get_tile(rayX, rayY, mapData) == 1 then
                return false -- wall hit
            end
        end
    end]]

    return true -- no walls hit
end

function tiles_to_pixels(tiles,XorY)
    if XorY == "X" then
        return (tiles -(camX%1))*16*scaleX
    elseif XorY == "Y" then
        return (tiles -(camY%1))*16*scaleY
    end
end


function love.touchmoved(id, x, y, dx, dy, pressure)
Tid = tostring(id)
Tx = x
Ty = y
Tp = pressure
end


-- origin shift algorithm
-- programmed by epiccooldog

function generate_maze(width, height, seed)
    width = math.floor(width / 2)
    height = math.floor(height / 2) 
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
