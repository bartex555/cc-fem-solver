--Module for exporting points to a csv file, to be later displayed
--as a function in an external program
--Only supports evenly spaced out sets of points (called later alphas)
--WARNING - N is the number of sections the function is divided into, 
--not the number of points (N = numberOfPoints - 1)
--Has the same interface as the display module
------EXAMPLE------
-- fileExporter.write( 0, 4, 4, 0, {0,1,0,3,2} )
-- would create a new file "alphas.csv" that would look like this:
-- y,x
-- 0,0
-- 1,1
-- 0,2
-- 3,3
-- 2,4
-------------------
--Here it is used for exporting FEM results (the reason why N is not the number of points)

local fileExporter = {_TYPE='module', _NAME='fileExporter', _VERSION='0.2'}


function fileExporter.write(fStart , fEnd, N, offset, alphas)
    local file = fs.open("alphas.csv","w")
    local step = (fEnd - fStart) / N
    file.writeLine("y,x")
    for i=1,N+1 do
        local line = (alphas[i] + offset) .. "," .. (fStart + step*(i-1))
        file.writeLine(line)
    end
    file.close();

end

return fileExporter

