-- Goofy Game

scaleX,scaleY = 3,3-- universal scale values
success = love.window.setMode(320*scaleX,240*scaleY,{}) -- creates window
width,height = love.graphics.getWidth()/16, love.graphics.getHeight()/16
fogFactor = .15
mazeWidth, mazeHeight = 200, 200
seed = os.time()
monsters_amount = 1000
damage_overlay = 0
running = true
debugCounter = 0
debugString = {}
start_time = os.time()
sound = {}
sound.music = love.audio.newSource("sound/atria tenebrarum.mp3", "static")
sound.rareEat = love.audio.newSource("sound/eating.wav", "static")
sound.hit = love.audio.newSource("sound/enemyhit.mp3", "static")
sound.footstep = {}
sound.footstep[1] = love.audio.newSource("sound/footstep1.wav", "static")
sound.footstep[2] = love.audio.newSource("sound/footstep2.wav", "static")
sound.footstep[3] = love.audio.newSource("sound/footstep3.wav", "static")
sound.footstep[4] = love.audio.newSource("sound/footstep4.wav", "static")
sound.footstep[5] = love.audio.newSource("sound/footstep5.wav", "static")
sound.eat = love.audio.newSource("sound/gamebite.mp3", "static")
sound.gunshot = love.audio.newSource("sound/gunshot.mp3", "static")
sound.itempickup = love.audio.newSource("sound/itempickup.mp3", "static")
sound.swingsword = love.audio.newSource("sound/swingsword.mp3", "static")
sound.torchextenguish = love.audio.newSource("sound/torchextenguish.mp3", "static")
sound.torchignite = love.audio.newSource("sound/torchignite.mp3", "static")
sound.torchloop = love.audio.newSource("sound/torchloop.mp3", "static")
function love.load()
    ending = 0
    gunDelay = 0
    swordDelay = 0
    swordswing = 0
    stepDelay = 0
    stepidx = 0
    inputFlag={i1=false,i2=false,i3=false,Use=false,iQ=false}
    -- touch variables
    Tid,Tx,Ty,Tp = 0,0,0,0
    -- loads in anim8 library
    anim8 = require 'libraries/anim8'
    -- sets filter to nearest to avoid blurry pixels
    love.graphics.setDefaultFilter("nearest","nearest")

    font = love.graphics.newFont(11)
    big_font = love.graphics.newFont(20)
    font_ultra_pro_max_5g_z_flip = love.graphics.newFont(70)
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
    items.flag = {id=2, texture=love.graphics.newImage("itemTextures/flag.png"), max_stack_size=32, playerAnim="empty"}
    items.bread = {id=2, texture=love.graphics.newImage("itemTextures/bread.png"), max_stack_size=4, playerAnim="empty"}
    items.sword = {id=2, texture=love.graphics.newImage("itemTextures/sword.png"), max_stack_size=1, playerAnim="sword"}

    monsters = {}
    monsters.zombie = {texture=love.graphics.newImage("monsterTextures/zombie.png"), damage=1, speed=1/20, health=20}
    monsters.zombie.spritesheet = love.graphics.newImage("monsterTextures/zombie-spritesheet.png")
    monsters.zombie.grid = anim8.newGrid(16, 16, monsters.zombie.spritesheet:getWidth(), monsters.zombie.spritesheet:getHeight())
    monsters.zombie.animations = {}
    monsters.zombie.animations.down = anim8.newAnimation(monsters.zombie.grid('1-2', 1), 0.4)
    monsters.zombie.animations.up = anim8.newAnimation(monsters.zombie.grid('1-2', 2), 0.4)
    monsters.zombie.animations.left = anim8.newAnimation(monsters.zombie.grid('1-2', 3), 0.4)
    monsters.zombie.animations.right = anim8.newAnimation(monsters.zombie.grid('1-2', 4), 0.4)
    loaded_monsters = {}
    -- loaded_monsters[1] = {monster=monsters.zombie, x=102, y=102}

    -- creates player object
    player = {}

    player.alive = true

    player.torchLevel = 4

    player.bullets = {}
    items.bullet = {texture = love.graphics.newImage("itemTextures/bullet-item.png"),draw_texture = love.graphics.newImage("itemTextures/bullet.png"), max_stack_size = 16, speed = 1/2, playerAnim="empty"}

    player.health = {}
    player.health.max = 6 -- probably want to change this for balance
    player.health.current = 6
    player.health.full_heart_texture = love.graphics.newImage("uiTextures/Maze_Heart_full.png")
    player.health.half_heart_texture = love.graphics.newImage("uiTextures/Maze_Heart_half.png")
    player.health.empty_heart_texture = love.graphics.newImage("uiTextures/Maze_Heart_empty.png")

    chest = {}
    chest.inventory = {}
    chest.inventory.contents = {}
    chest.inventory.slot_number = #items

    for key, item1 in pairs(items) do
        chest.inventory.contents[key] = {item=item1, amount=0}
    end

    mapData = generate_maze(mazeWidth, mazeHeight, seed) -- generates a maze
    create_cross_paths(500)
    floorItems = {}
    for y=1, #mapData do
        floorItems[y] = {}
        for x=1, #mapData[1] do
            rand = love.math.random(1,1000)
            if mapData[y][x] == 0 then
                if rand == 1 then
                    floorItems[y][x] = {item=items.sword, amount=1}
                elseif rand == 2 then
                    floorItems[y][x] = {item=items.gun, amount=1}
                elseif rand > 2 and rand <= 4 then
                    floorItems[y][x] = {item=items.bullet, amount=love.math.random(1,8)}
                elseif rand > 4 and rand <= 10 then
                    floorItems[y][x] = {item=items.flag, amount=love.math.random(1,16)}
                elseif rand > 10 and rand <= 16 then
                    floorItems[y][x] = {item=items.bread, amount=love.math.random(1,2)}
                elseif rand > 16 and rand <= 22 then
                    floorItems[y][x] = {item=items.coal, amount=love.math.random(1,4)}
                else
                    floorItems[y][x] = {item="empty", amount=nil}
                end
            else
                floorItems[y][x] = {item="empty", amount=nil}
            end
        end
    end



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
    player.grid.gun = anim8.newGrid(16,16,player.spritesheets.gun:getWidth(),player.spritesheets.gun:getHeight())
    player.grid.sword = anim8.newGrid(16,16,player.spritesheets.sword:getWidth(),player.spritesheets.sword:getHeight())

    -- attack
    player.attack = {}
    player.attack.last_attack = os.time()
    player.attack.slash_spritesheet = love.graphics.newImage("playerSprites/sword-slash.png")
    player.attack.slash_grid = anim8.newGrid(17, 24, player.attack.slash_spritesheet:getWidth(), player.attack.slash_spritesheet:getHeight())
    player.attack.slash_animation = anim8.newAnimation(player.attack.slash_grid('1-10', 1), 0.05)

    -- inventory
    player.inventory = {}
    player.heldItem = {item=items.sword, amount=1}
    player.inventory.contents = {}
    player.inventory.slot_number = 3
    player.inventory.slot_texture = love.graphics.newImage("uiTextures/inventory-slot.png")

    for x = 1, player.inventory.slot_number do
        player.inventory.contents[x] = {item="empty", amount=nil}
    end

    -- just for testing
    player.inventory.contents[1] = {item=items.coal, amount=6}
    player.inventory.contents[2] = {item=items.bullet, amount=16}
    player.inventory.contents[3] = {item=items.gun, amount=1}

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
                    local spritesheetY = (directionIdx == 1 and 1 + (animIdx) + (4-torchIdx)*2) or (directionIdx == 2 and 1 + (animIdx) + (4-torchIdx)*2) or (directionIdx == 3 and 12 + (animIdx) + (4-torchIdx)*2) or (directionIdx == 4 and 12 + (animIdx) + (4-torchIdx)*2)
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
        table.insert(loaded_monsters, {monster=monsters.zombie, x=posX, y=posY, health=3, last_attack=os.time(), direction="up"})
    end
end



function love.update(dt)
    success = love.audio.play(sound.music)
    if not running then 
            isMoving = false
        end
        player.dir = "up"
    end

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
            player.dir = "right"
        if get_tile(player.x + 1/8, player.y + 0.45, mapData) == 0 and get_tile(player.x + 1/8, player.y, mapData) == 0 then
            player.x = player.x + 1/16
            isMoving = true
        end
    end

    -- moving left and checking if you can
    if love.keyboard.isDown("a") or Tx < love.graphics.getWidth()*.6 and Tx > love.graphics.getWidth()*.5 and Ty > love.graphics.getHeight()*.5 then 
            if get_tile(player.x - 1/8, player.y + 0.45, mapData) == 0 and get_tile(player.x - 1/8, player.y, mapData) == 0 then
                player.x = player.x - 1/16
                isMoving = true
            end
        if player.dir == "right" then
            isMoving = false
        end
        player.dir = "left"
    end

    if isMoving == true and love.timer.getTime() - stepDelay > .4 then
        stepidx = stepidx + 1
        if stepidx > 5 then
            stepidx = 1
        end
        love.audio.play(sound.footstep[stepidx])
        stepDelay = love.timer.getTime()
    end

    if love.keyboard.isDown("1") then --the key and item index are opposite and its YOUR FAULT EPIC -SpaceKiwi
        if inputFlag.i1 == false then
            if player.heldItem.item == player.inventory.contents[3].item then
                if player.heldItem.item ~= "empty" then
                    local temp = player.inventory.contents[3].amount
                    player.inventory.contents[3].amount = math.min(player.inventory.contents[3].amount + player.heldItem.amount, player.inventory.contents[3].item.max_stack_size)
                    player.heldItem.amount = math.max(player.heldItem.amount - (player.inventory.contents[3].amount - temp),0)
                    if player.heldItem.amount == 0 then
                        player.heldItem = {item="empty", amount=nil}
                    end
                    inputFlag.i1 = true
                end
            else
                local temp = player.heldItem
                player.heldItem = player.inventory.contents[3]
                player.inventory.contents[3] = temp
                inputFlag.i1 = true
            end
        end
    else
        inputFlag.i1 = false
    end
    if love.keyboard.isDown("2") then
        if inputFlag.i2 == false then
            if player.heldItem.item == player.inventory.contents[2].item then
                if player.heldItem.item ~= "empty" then
                    local temp = player.inventory.contents[2].amount
                    player.inventory.contents[2].amount = math.min(player.inventory.contents[2].amount + player.heldItem.amount, player.inventory.contents[2].item.max_stack_size)
                    player.heldItem.amount = math.max(player.heldItem.amount - (player.inventory.contents[2].amount - temp),0)
                    if player.heldItem.amount == 0 then
                        player.heldItem = {item="empty", amount=nil}
                    end
                    inputFlag.i2 = true
                end
            else
                local temp = player.heldItem
                player.heldItem = player.inventory.contents[2]
                player.inventory.contents[2] = temp
                inputFlag.i2 = true
            end
        end
    else
        inputFlag.i2 = false
    end
    if love.keyboard.isDown("3") then
        if inputFlag.i3 == false then
            if player.heldItem.item == player.inventory.contents[1].item then
                if player.heldItem.item ~= "empty" then
                    local temp = player.inventory.contents[1].amount
                    player.inventory.contents[1].amount = math.min(player.inventory.contents[1].amount + player.heldItem.amount, player.inventory.contents[1].item.max_stack_size)
                    player.heldItem.amount = math.max(player.heldItem.amount - (player.inventory.contents[1].amount - temp),0)
                    if player.heldItem.amount == 0 then
                        player.heldItem = {item="empty", amount=nil}
                    end
                    inputFlag.i3 = true
                end
            else
                local temp = player.heldItem
                player.heldItem = player.inventory.contents[1]
                player.inventory.contents[1] = temp
                inputFlag.i3 = true
            end
        end
    else
        inputFlag.i3 = false
    end
        if love.keyboard.isDown("q") then
        if inputFlag.iQ == false then
            if player.heldItem.item == floorItems[math.floor(player.y)][math.floor(player.x)] then
                if player.heldItem.item ~= "empty" then
                    local temp = floorItems[math.floor(player.y)][math.floor(player.x)]
                    floorItems[math.floor(player.y)][math.floor(player.x)].amount = math.min(floorItems[math.floor(player.y)][math.floor(player.x)].amount + player.heldItem.amount, floorItems[math.floor(player.y)][math.floor(player.x)].item.max_stack_size)
                    player.heldItem.amount = math.max(player.heldItem.amount - (floorItems[math.floor(player.y)][math.floor(player.x)].amount - temp),0)
                    love.audio.play(sound.itempickup)
                    if player.heldItem.amount == 0 then
                        player.heldItem = {item="empty", amount=nil}
                    end                        
                    inputFlag.iQ = true
                end
            else
                local temp = player.heldItem
                player.heldItem = floorItems[math.floor(player.y)][math.floor(player.x)]
                floorItems[math.floor(player.y)][math.floor(player.x)] = temp
                inputFlag.iQ = true
                love.audio.play(sound.itempickup)
            end
        end
    else
        inputFlag.iQ = false
    end

    if love.keyboard.isDown("e") then
        if inputFlag.use == false then
            inputFlag.use = true
            if player.heldItem.item == items.gun then
                if love.timer.getTime() - gunDelay > .6 then
                    gunDelay = love.timer.getTime()
                    for x = 1, #player.inventory.contents do
                        if player.inventory.contents[x].item == items.bullet then
                            player.inventory.contents[x].amount = player.inventory.contents[x].amount - 1
                            if player.inventory.contents[x].amount == 0 then
                                player.inventory.contents[x] = {item="empty", amount=nil}
                            end
                            table.insert(player.bullets, {direction=player.dir, x=player.x, y=player.y})
                            love.audio.play(sound.gunshot)
                            table.insert(lights,{player.x,player.y,1})
                            goto continue
                        end
                    end
                end
            end
            if player.heldItem.item == items.coal then
                player.torchLevel = 4
                player.heldItem.amount = player.heldItem.amount - 1
                if player.heldItem.amount == 0 then
                    player.heldItem = {item="empty", amount=nil}
                end
            end
            if player.heldItem.item == items.bread then
                player.health.current = player.health.current + 1
                player.heldItem.amount = player.heldItem.amount - 1
                if player.heldItem.amount == 0 then
                    player.heldItem = {item="empty", amount=nil}
                end
            end
            if player.heldItem.item == items.sword then
                if love.timer.getTime() - swordDelay > 1 then
                    love.audio.play(sound.swingsword)
                    swordswing = love.timer.getTime()
                    swordDelay = love.timer.getTime()
                    for y=1, #loaded_monsters do
                        local monster = loaded_monsters[y]
                        if math.abs(player.x - (monster.x + 0.5)) < 1.25 and math.abs(player.y - (monster.y + 0.5)) < 1.25 then
                            monster.health = monster.health - 1
                            love.audio.play(sound.hit)
                            local pushX = 0 - ((player.x - (monster.x + 0.5)) / math.sqrt((player.x - (monster.x + 0.5))^2 + (player.y - (monster.y + 0.5))^2))
                            if get_tile(monster.x + pushX + 0.25, monster.y + 0.25, mapData) == 0 and get_tile(monster.x + pushX + 0.75, monster.y + 0.75, mapData) == 0 then
                                monster.x = monster.x + pushX
                            end
                            local pushY = 0 - ((player.y - (monster.y + 0.5)) / math.sqrt((player.x - (monster.x + 0.5))^2 + (player.y - (monster.y + 0.5))^2))
                            if get_tile(monster.x + 0.25, monster.y + pushX + 0.25, mapData) == 0 and get_tile(monster.x + 0.75, monster.y + pushX + 0.75, mapData) == 0 then
                                monster.y = monster.y + pushY
                            end
                            goto continue
                        end 
                    end
                end
            end
        ::continue::
        end
    else
        inputFlag.use = false
    end

    -- vvvmove this code snippet to the bottom of the update functionvvv
    local state = isMoving and "move" or "idle"
    local playerAnimation = "empty"
    if player.heldItem.item ~= "empty" then
        playerAnimation = player.heldItem.item.playerAnim
    end
    player.anim = player.animations[playerAnimation]["torch"..math.ceil(player.torchLevel)][state][player.dir]
    state = nil
    player.anim:update(dt)
    player.attack.slash_animation:update(dt)
    
    monsters.zombie.animations.down:update(dt)
    monsters.zombie.animations.up:update(dt)
    monsters.zombie.animations.left:update(dt)
    monsters.zombie.animations.right:update(dt)
    -- ^^^move this code snippet to the bottom of the update function^^^

    -- monster ai

    local monsters_to_remove = {}--move this line to the top of update function

    for x=1, #loaded_monsters do --this is general monster ai but only works for zombies
        local monster = loaded_monsters[x]
        local dirX = player.x - 0.5 - monster.x
        local dirY = player.y - 0.5 - monster.y

        local length = math.sqrt(dirX * dirX + dirY * dirY) -- bro doesn't know ^2

        if math.abs((player.x+0.5) - (monster.x+0.5)) <= 0.5 and math.abs((player.y+0.5) - (monster.y+0.5)) <= 0.5 and (os.time() - monster.last_attack) >= 2 then
            player.health.current = player.health.current - monster.monster.damage
            monster.last_attack = os.time()
            damage_overlay = 5
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

            if dirX > 0 and dirY > 0 then
                if dirX > dirY then
                    monster.direction = "right"
                else
                    monster.direction = "down"
                end
            elseif dirX > 0 and dirY < 0 then
                if dirX > math.abs(dirY) then
                    monster.direction = "right"
                else
                    monster.direction = "up"
                end
            elseif dirX < 0 and dirY > 0 then
                if math.abs(dirX) > dirY then
                    monster.direction = "left"
                else
                    monster.direction = "down"
                end
            elseif dirX < 0 and dirY < 0 then
                if math.abs(dirX) > math.abs(dirY) then
                    monster.direction = "left"
                else
                    monster.direction = "up"
                end
            end
        end

        if monster.health <= 0 then
            table.insert(monsters_to_remove, x)
        end
    end

    table.sort(monsters_to_remove, function(a, b) return a > b end)
    for _, idx in ipairs(monsters_to_remove) do
        table.remove(loaded_monsters, idx)
        print("removing monster")
    end

    if player.health.current <= 0 then
        player.health.current = 0
        player.alive = false
        running = false
        death_time = os.time()
    end

    local indices_to_remove = {} -- move this line to the top of the update function
    --print(#player.bullets)
    for x=1, #player.bullets do
        local bullet = player.bullets[x]

        --print("x: "..bullet.x.." y: "..bullet.y)

        if bullet.direction == "up" then
            if get_tile(bullet.x, bullet.y-items.bullet.speed, mapData) == 0 then
                bullet.y = bullet.y - items.bullet.speed
            else
                table.insert(indices_to_remove, x)
            end
        elseif bullet.direction == "down" then
            if get_tile(bullet.x, bullet.y+items.bullet.speed, mapData) == 0 then
                bullet.y = bullet.y + items.bullet.speed
            else
                table.insert(indices_to_remove, x)
            end
        elseif bullet.direction == "left" then
            if get_tile(bullet.x-items.bullet.speed, bullet.y, mapData) == 0 then
                bullet.x = bullet.x - items.bullet.speed
            else
                table.insert(indices_to_remove, x)
            end
        elseif bullet.direction == "right" then
            if get_tile(bullet.x+items.bullet.speed, bullet.y, mapData) == 0 then
                bullet.x = bullet.x + items.bullet.speed
            else
                table.insert(indices_to_remove, x)
            end
        end
        table.insert(lights,{bullet.x,bullet.y,.5})

        for y=1, #loaded_monsters do
            local monster = loaded_monsters[y]

            if math.abs(bullet.x - (monster.x + 0.5)) < 0.5 and math.abs(bullet.y - (monster.y + 0.5)) < 0.5 then
                monster.health = monster.health - 20
                table.insert(indices_to_remove, x)
                love.audio.play(sound.hit)
                print("monster hit :O")
                goto exit
            end 
        end
    end
    ::exit::

    table.sort(indices_to_remove, function(a, b) return a > b end)
    for _, idx in ipairs(indices_to_remove) do
        table.remove(player.bullets, idx)
    end

    update_shadows()
    ::finish::
    if #monsters == 0 then
        running = false
        ending = 1
    end
end



function love.draw()
    -- updates cam position to not show outside of maze (but it should be in update no?)
    -- I put it near where it is used for clarity -SpaceKiwi
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
            if floorItems[math.floor(y+camY)][math.floor(x+camX)].item ~= "empty" then
                love.graphics.draw(floorItems[math.floor(y+camY)][math.floor(x+camX)].item.texture,tiles_to_pixels(x,"X"),tiles_to_pixels(y,"Y"),0,scaleX,scaleY)
            end
        end
    end

    for x = 1, #loaded_monsters do
        local monster = loaded_monsters[x]
        if math.abs(monster.x - player.x) < 10 and math.abs(monster.y - player.y) < 10 then
            -- print(monster.direction)
            --love.graphics.draw(monster.monster.texture, (monster.x - camX) * 16 * scaleX, (monster.y - camY) * 16 * scaleY, 0, scaleX, scaleY)
            if monster.direction == "up" then
                monster.monster.animations.up:draw(monster.monster.spritesheet, (monster.x-camX)*16*scaleX, (monster.y-camY)*16*scaleY, nil, scaleX, scaleY)
            elseif monster.direction == "down" then
                monster.monster.animations.down:draw(monster.monster.spritesheet, (monster.x-camX)*16*scaleX, (monster.y-camY)*16*scaleY, nil, scaleX, scaleY)
            elseif monster.direction == "left" then
                monster.monster.animations.left:draw(monster.monster.spritesheet, (monster.x-camX)*16*scaleX, (monster.y-camY)*16*scaleY, nil, scaleX, scaleY)
            elseif monster.direction == "right" then
                monster.monster.animations.right:draw(monster.monster.spritesheet, (monster.x-camX)*16*scaleX, (monster.y-camY)*16*scaleY, nil, scaleX, scaleY)
            end
        end
    end

    for _, bullet in ipairs(player.bullets) do
        love.graphics.draw(items.bullet.draw_texture, (bullet.x - camX) * 16 * scaleX, (bullet.y - camY) * 16 * scaleY, 0, scaleX, scaleY)
    end
    local currentSheet = player.spritesheets.empty
    if player.heldItem.item ~= "empty" then
        currentSheet = player.spritesheets[player.heldItem.item.playerAnim]
    end
    player.anim:draw(currentSheet, (player.x-camX)*16*scaleX-(6.5*scaleX), (player.y-camY)*16*scaleY-(8*scaleY),nil,scaleX,scaleY)
    local dir = 0
    local offsetX = 0
    local offsetY = 0
    
        if player.dir == "right" then
            dir = math.rad(0)
            offsetX = .5
            offsetY = 0
        elseif player.dir == "left" then
            dir = math.rad(180)
            offsetX = .5
            offsetY = 1
        elseif player.dir == "up" then
            dir = math.rad(-90)
            offsetX = 0
            offsetY = .5
        elseif player.dir == "down" then
            dir = math.rad(90)
            offsetX = 1
            offsetY = .5
        end
    
    if love.timer.getTime() - swordswing < .25 then
        player.attack.slash_animation:draw(player.attack.slash_spritesheet, (player.x-camX+offsetX)*16*scaleX - (6.5*scaleX), (player.y-camY+offsetY)*16*scaleY - (8*scaleY), dir, scaleX, scaleY)
    end
    -- drawing lighting that idk how it works and prob will be replaced soon
    for y=1, height*16/16 do
        for x=1, width*16/16 do
            love.graphics.setColor(0,0,0,shadowData[y][x])
            love.graphics.rectangle("fill",tiles_to_pixels(x-1,"X"),tiles_to_pixels(y-1,"Y"),scaleX*16,scaleY*16) 
        end
    end
    love.graphics.setColor(1,1,1,1)
    --love.graphics.print("camera: "..math.floor(camX).." "..math.floor(camY),0,0)
    --love.graphics.print("player: "..math.floor(player.x).." "..math.floor(player.y),0,10)
    --love.graphics.print("window size: "..width.." "..height,0,20)
    --love.graphics.print("Touch pressed: ID " .. Tid .. " at (" .. Tx .. ", " .. Ty .. ") pressure:" .. Tp,0,30)
    --love.graphics.print("FPS: "..love.timer.getFPS(),0,40)
    love.graphics.print(tostring(isMoving),0,50)
    love.graphics.print("Number of alive monsters: "..#loaded_monsters)


    love.graphics.setFont(big_font)
    -- Held item slot
    love.graphics.draw(player.inventory.slot_texture, love.graphics.getWidth()/2 - (player.inventory.slot_number*24*scaleX)/2 + 2*scaleX*24, love.graphics.getHeight()-160, 0, scaleX, scaleY)
    if player.heldItem.item ~= "empty" then
        love.graphics.draw(player.heldItem.item.texture, love.graphics.getWidth()/2 - (player.inventory.slot_number*24*scaleX)/2 + 2*scaleX*24+4*scaleX, love.graphics.getHeight()-160+4*scaleY, 0, scaleX, scaleY)
        if player.heldItem.amount > 1 then
            love.graphics.print(player.heldItem.amount, love.graphics.getWidth()/2 - (player.inventory.slot_number*24*scaleX)/2 + 2*scaleX*24+14*scaleX, love.graphics.getHeight()-160+12*scaleY)
        end
    end
        -- Inventory slots
    for x = 1, player.inventory.slot_number do
        love.graphics.draw(player.inventory.slot_texture, love.graphics.getWidth()/2 - (player.inventory.slot_number*24*scaleX)/2 + (3-x)*scaleX*24, love.graphics.getHeight()-90, 0, scaleX, scaleY)
        if player.inventory.contents[x].item ~= "empty" then
            love.graphics.draw(player.inventory.contents[x].item.texture, love.graphics.getWidth()/2 - (player.inventory.slot_number*24*scaleX)/2 + (3-x)*scaleX*24+4*scaleX, love.graphics.getHeight()-90+4*scaleY, 0, scaleX, scaleY)
            if player.inventory.contents[x].amount > 1 then
                love.graphics.print(player.inventory.contents[x].amount, love.graphics.getWidth()/2 - (player.inventory.slot_number*24*scaleX)/2 + (3-x)*scaleX*24+14*scaleX, love.graphics.getHeight()-90+12*scaleY)
            end
        end
    end
    love.graphics.setFont(font)

    local temp_health = player.health.current
    for x = 1, player.health.max/2 do
        if temp_health > 1 then -- changed (10 * 9 * scaleX) - (x * 9 * scaleX) to (10-x) * 9 * scaleX :skull: also increased * 9 to * 16 to account for bigger heart sprites - SpaceKiwi
            love.graphics.draw(player.health.full_heart_texture, love.graphics.getWidth() - ((5-x) * 16 * scaleX), 20, 0, scaleX, scaleY) 
            temp_health = temp_health - 2
        elseif temp_health == 1 then
            love.graphics.draw(player.health.half_heart_texture, love.graphics.getWidth() - ((5-x) * 16 * scaleX), 20, 0, scaleX, scaleY)
            temp_health = temp_health - 1
        elseif temp_health == 0 then
            love.graphics.draw(player.health.empty_heart_texture, love.graphics.getWidth() - ((5-x) * 16 * scaleX), 20, 0, scaleX, scaleY)
        end
    end

    if not player.alive then
        love.graphics.setFont(font_ultra_pro_max_5g_z_flip)
        local font_h = font_ultra_pro_max_5g_z_flip:getHeight() * scaleY
        love.graphics.printf("U ded :(\n" .. math.floor((death_time-start_time)/60*100)/100 .. "min", 0, (love.graphics.getHeight() - font_h*2) / 2, love.graphics.getWidth()/scaleX, "center", 0, scaleX, scaleY, 0, 0, 0, 0)
        love.graphics.setFont(font)
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
    if tile_y < 1 or tile_y > #maze or tile_x < 1 or tile_x > #maze[1] then
        return 1
    end
    local tile = maze[tile_y][tile_x]
    return tile
end


function create_cross_paths(amount)
    local idx = 0
    for i=1, amount do
        local x,y = 0,0
        repeat
            love.math.setRandomSeed(seed+idx)
            x = love.math.random(2,#mapData[1]-1)
            idx = idx + 1
            love.math.setRandomSeed(seed+idx)
            y = love.math.random(2,#mapData-1)
            idx = idx + 1
        until (mapData[y][x] == 1 and mapData[y+1][x] == 0 and mapData[y-1][x] == 0 and mapData[y][x+1] == 1 and mapData[y][x-1] == 1) or (mapData[y][x] == 1 and mapData[y+1][x] == 1 and mapData[y-1][x] == 1 and mapData[y][x+1] == 0 and mapData[y][x-1] == 0) or idx > 10000
        if idx < 10000 then
            mapData[y][x] = 0
            debugCounter = debugCounter + 1
        end
    end
end
