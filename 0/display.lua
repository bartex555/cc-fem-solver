
--Module for drawing functions from points on a CC monitor
--Works with monitors of all shapes and sizes 
--(but bigger is better in this case)
--Only supports evenly spaced out sets of points (later called alphas)
--WARNING - N is the number of sections the function is divided into, not
--the number of points (N = numberOfPoints - 1)
------EXAMPLE------
-- display.drawFunctionNew( 0, 4, 4, 0, {0,1,0,3,2} )
-- would draw a function connecting points (in this order)
-- (0,0), (1,1), (2,0), (3,3), (4,2)
-------------------
--Here it is used for drawing FEM results (the reason why N is not the number of points)

local display = {_TYPE='module', _NAME='display', _VERSION='0.2'}


--values to customize
local monitor = peripheral.wrap("left")

monitor.setTextScale(0.5)

monitor.setTextColor(colors.white)

local tolerance = 4

local backgroundColor = colors.black

local gridColor = colors.gray

local lineColor = colors.blue



--The old implementation of drawing a function from alpha points
--Includes only the zero and the max point on the y axis, but
--fills the whole screen with the function every time
function display.drawFunctionOld(fStart , fEnd, N, offset, alphas)
    --redirecting
    monitor.setBackgroundColor(backgroundColor)
    monitor.clear()
    term.redirect(monitor)


    --getting the size and setting the stage
    local xSize, ySize = term.getSize()

    local xStep = (fEnd - fStart) / xSize

    local maxVal = math.max(table.unpack(alphas)) + offset
    local minVal = math.min(table.unpack(alphas)) + offset

    local yMultiplier = (ySize - tolerance) / (maxVal - minVal)

    local zeroPoint = math.floor(ySize/2 - yMultiplier * (maxVal + minVal) * 0.5 + 0.5)

    for i=1,xSize do
        paintutils.drawPixel(i,ySize - zeroPoint,gridColor)
        paintutils.drawPixel(i,ySize - (zeroPoint + math.floor(maxVal*yMultiplier + 0.5)),gridColor)
    end

    term.setCursorPos(1,ySize-zeroPoint)
    term.write(0)
    term.setCursorPos(1,ySize - (zeroPoint + math.floor(maxVal*yMultiplier + 0.5)))
    term.write(maxVal)


    --drawing the alpha function
    local aStep = (fEnd - fStart) / N
    local a = 1/aStep
    local aFunction = function (x)
        return -a * x + 1
    end

    --black magic
    local currentPart = 1
    for i=0,xSize-1 do
        local x = i*xStep - (aStep * (currentPart-1))
        while x > aStep do
            x = x - aStep;
            currentPart = currentPart + 1;
        end

        local y = alphas[N+1]

        if currentPart <= N then
            y = math.floor(yMultiplier * (alphas[currentPart] * aFunction(x) + alphas[currentPart+1] * (1-aFunction(x)) + offset) + 0.5)
        elseif currentPart == N+1 then
            y = math.floor(yMultiplier * (alphas[currentPart] * aFunction(x) + offset) + 0.5)
        end

        y = y + zeroPoint
        paintutils.drawPixel(i+1,ySize - y,lineColor)
    end

    term.redirect(term.native())
end


--A list with possible scales of a function 
--(1px on the monitor is equal to possibleRes[i])
--as well as a list of best spacing of the grid lines for a given scale
local possibleRes = {0.001, 0.00125, 0.002, 0.004, 0.005, 0.008,
                     0.01, 0.0125, 0.02, 0.04, 0.05, 0.08, 
                     0.1, 0.125, 0.2, 0.4, 0.5, 0.8, 
                     1, 2, 4, 5, 8, 10}
local bestInterval = {10,8,10,10,10,10,
                      10,8,10,10,10,10,
                      10,8,10,10,10,10,
                      10, 10, 10, 10, 10, 10}
--The new implementation of drawing a function from alpha points
--Includes "fancy" grid lines and a working, readable scale
function display.drawFunctionNew(fStart , fEnd, N, offset, alphas)
    --redirecting
    monitor.setBackgroundColor(backgroundColor)
    monitor.clear()
    term.redirect(monitor)


    --getting the size and setting the stage
    local xSize, ySize = term.getSize()

    local maxVal = math.max(table.unpack(alphas)) + offset
    local minVal = math.min(table.unpack(alphas)) + offset

    local xStep = 1
    local yStep = 1

    --choosing the right scale
    for i=24,1,-1 do
        if (fEnd - fStart) / xSize < possibleRes[i] then
            xStep = i
        end
        if (maxVal - minVal) / (ySize-tolerance) < possibleRes[i] then
            yStep = i
        end
    end

    local yMultiplier = 1/possibleRes[yStep]

    local realXSize = math.floor((fEnd - fStart) / possibleRes[xStep] + 0.5)

    local zeroPoint = math.floor(ySize/2 - yMultiplier * (maxVal + minVal) * 0.5 + 0.5)

    local spacer = xSize - realXSize - 1


    --xAxis labels A
    for i=spacer,xSize,bestInterval[xStep] do
        for y=1,ySize do
            paintutils.drawPixel(i,y,gridColor)
        end
    end

     --yAxis labels (wildly inefficient)
     for i=0,math.max(math.abs(maxVal),math.abs(minVal))/(bestInterval[yStep]*possibleRes[yStep]) + 2 do
        for x=1,xSize do
            paintutils.drawPixel(x,ySize -(zeroPoint + bestInterval[yStep]*i),gridColor)
            paintutils.drawPixel(x,ySize -(zeroPoint - bestInterval[yStep]*i),gridColor)
        end
        term.write(bestInterval[yStep])
        term.setCursorPos(1,ySize - (zeroPoint - bestInterval[yStep]*i))
        term.write(possibleRes[yStep] * bestInterval[yStep] * -i)
        term.setCursorPos(1,ySize - (zeroPoint + bestInterval[yStep]*i))
        term.write(possibleRes[yStep] * bestInterval[yStep] * i)
    end

    --xAxis labels B (to prevent overlap with yAxis)
    for i=spacer,xSize,bestInterval[xStep] do
        term.setCursorPos(i-1,ySize)
        term.write(possibleRes[xStep] * bestInterval[xStep] * math.floor((i-spacer)/bestInterval[xStep]+0.5) + fStart)
    end

    --drawing the alpha function
    local aStep = (fEnd - fStart) / N
    local a = 1/aStep
    local aFunction = function (x)
        return -a * x + 1
    end

    --black magic
    local currentPart = 1
    for i=0,realXSize do
        local x = i*possibleRes[xStep] - (aStep * (currentPart-1))
        while x > aStep do
            x = x - aStep;
            currentPart = currentPart + 1;
        end

        local y = alphas[N+1]

        if currentPart <= N then
            y = math.floor(yMultiplier * (alphas[currentPart] * aFunction(x) + alphas[currentPart+1] * (1-aFunction(x)) + offset) + 0.5)
        elseif currentPart == N+1 then
            y = math.floor(yMultiplier * (alphas[currentPart] * aFunction(x) + offset) + 0.5)
        end

        y = y + zeroPoint

        paintutils.drawPixel(i+spacer,ySize - y,lineColor)
    end

    term.redirect(term.native())
end



--for debugging
--draws matrices to the CURRENT terminal
function display.matrixSquare(mat,N)
    term.clear()
    for y=1,N do 
        term.setCursorPos(1,y)   
        for x=1,N do
            term.write(mat[y][x])
            term.write("  ")
        end
    end
    term.setCursorPos(1,N+1)
end
--same but for tridiagonal matrices
function display.matrixTri(A,B,C,N)
    term.clear()
    for y=1,N do 
        term.setCursorPos(1,y)   
        for x=1,N do
            if x == y then
                term.write(B[x])
            elseif y - x == 1 then
                term.write(A[x+1])
            elseif y - x == -1 then
                term.write(C[y])
            else
                term.write(0)
            end
            term.write("  ")
        end
    end
    term.setCursorPos(1,N+1)
end



return display
