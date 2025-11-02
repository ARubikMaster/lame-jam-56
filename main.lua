function love.load()
    mapData = {{1,1,1,1,1,1,1},{1,1,1,0,0,0,1},{1,1,1,0,1,0,1},{1,0,0,0,0,0,1},{1,0,1,0,1,1,1},{1,0,0,0,1,1,1},{1,1,1,1,1,1,1}} -- Temporary values for the map
    wallTextures = {love.graphics.newImage("wallTextures/MissingTexture.png"),love.graphics.newImage("wallTextures/Test1.png")} -- add wall textures here
    playerX,playerY = 0,0 -- player variables
    scaleX,scaleY = 1,1 -- universal scale values
end



function love.update()
    if love.keyboard.isDown("right") then -- not player movement just temporary for testing
    playerX = playerX + 1
    end
end



function love.draw()
    local TileOffsetX = (playerX % 16) * scaleX -- tile offsets so the map moves smoothly as player moves
    local TileOffsetY = (playerY % 16) * scaleY
    for y=1, math.min(love.graphics.getHeight() / (16 * scaleX) + 1,#mapData) do -- math.min and ,#mapData are just there to allow small map sizes and can be removed later
        for x=1, math.min(love.graphics.getWidth() / (16 * scaleY)  + 1,#mapData) do
            if mapData[math.min(math.max(y + math.floor(playerY/16),1),#mapData)][x + math.floor(playerX/16)] == 1 then -- actually draws the map
                love.math.setRandomSeed((x+math.floor(playerX/16)) .. math.abs(y+math.floor(playerY/16)))
                love.graphics.draw(wallTextures[love.math.random(1,#wallTextures)],((16 * x * scaleX) - TileOffsetX) - (16 * scaleX),(16 * y * scaleY) - TileOffsetY - (16 * scaleY),0,scaleX,scaleY)
            end
        end
    end
end