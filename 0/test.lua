
--Test program

--to start the program type "test N" in the terminal
--where N is the number of sections
--N is positive
--In this case works with any N (probably)


local args = {...}

local display = require("display")

local solver = require("solver")

local N = tonumber(args[1])


--for visualizing changes between different N values 
--sleep(1)

--for i=3,N do
--    local alphas = solver.solveTest(i)
--    display.drawFunctionNew(-1,1,i,0,alphas)
--    sleep(0.5)
--end

local alphas = solver.solveTest(N)
display.drawFunctionNew(-1,1,N,0,alphas)

--exporting to file
--local fileExporter = require("fileExporter")
--fileExporter.write(-1,1,N,0,alphas)
