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

-- Just for testing :P

maze = generate_maze(30, 30, 4124)

for y in pairs(maze) do
    line = ""
    for x in pairs(maze[y]) do
        line = line..maze[y][x]..","
    end
    print(line)
end