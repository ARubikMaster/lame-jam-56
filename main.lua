function love.load()
    mapData = {{1,1,1,1,1,1,1},{1,1,1,0,0,0,1},{1,1,1,0,1,0,1},{1,0,0,0,0,0,1},{1,0,1,0,1,1,1},{1,0,0,0,1,1,1},{1,1,1,1,1,1,1}}
    wallTextures = {love.graphics.newImage("wallTextures/MissingTexture.png")}
    playerX,playerY = 0,0
    scaleX,scaleY = 1,1
end







function love.draw()
    for y=1, #mapData do
        for x=1, #mapData do
            if mapData[y][x] == 1 then
                love.graphics.draw(wallTextures[1],16*x*scaleX,16*y*scaleY,0,scaleX,scaleY)
            end
        end
    end
end