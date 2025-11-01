function love.load()
    mapData = {{1,1,1,1,1,1,1},{1,1,1,0,0,0,1},{1,1,1,0,1,0,1},{1,0,0,0,0,0,1},{1,0,1,0,1,1,1},{1,0,0,0,1,1,1},{1,1,1,1,1,1,1}}
    wallTextures = {love.graphics.newImage("wallTextures/MissingTexture.png")}
    playerX,playerY = 0,0
    scaleX,scaleY = 1,1
end



function love.update()
    if love.keyboard.isDown("right") then
    playerX = playerX + 1
    end
end



function love.draw()
    local TileOffsetX = playerX % 16
    local TileOffsetY = playerY % 16
    for y=1, #mapData do
        for x=1, #mapData do
            if mapData[y + math.floor(playerY/16)][x + math.floor(playerX/16)] == 1 then
                love.graphics.draw(wallTextures[1],16*x*scaleX-TileOffsetX,16*y*scaleY-TileOffsetY,0,scaleX,scaleY)
            end
        end
    end
end