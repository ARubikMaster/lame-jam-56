function love.load()
    mapData = {{1,1,1,1,1,1,1},{1,1,1,0,0,0,1},{1,1,1,0,1,0,1},{1,0,0,0,0,0,1},{1,0,1,0,1,1,1},{1,0,0,0,1,1,1},{1,1,1,1,1,1,1}}
    wallTextures = {love.graphics.newImage("wallTextures/MissingTexture.png")}
    playerX,playerY = 0,0
end







function love.draw()
    for y=0, math.sqrt(#mapData), math.sqrt(#mapData) do
        for x=1, math.sqrt(#mapData) do
            if mapData[x+y] == 1 then
                love.graphics.draw(wallTextures[1],16*x,16*y)
            end
        end
    end
end