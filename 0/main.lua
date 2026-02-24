
--to start the program type "main N" in the terminal
--where N is the number of sections
--N is positive
--In this case breaks with N = 1

local args = {...}

local display = require("display")

local solver = require("solver")

local export = require("fileExporter")

local N = tonumber(args[1])



local alphas = solver.solveHeat(N)
display.drawFunctionNew(0,2,N,-20,alphas)



export.write(0,2,N,-20,alphas)







