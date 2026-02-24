
--Solver for the FEM problem 

local solver = {_TYPE='module', _NAME='solver', _VERSION='0.1'}

local tMatrix = require("tMatrix")

--get the ascending side of the basis function
local function getSideA(point,step)
    local a = 1/step
    local b = 1 - a*point

    return function (x)
        return a*x + b
    end
end

--get the descending side of the basis function
local function getSideB(point,step)
    local a = -1/step
    local b = 1 - a*point

    return function (x)
        return a*x + b
    end
end

--gaussian quadrature for numerically calculating integrals
--https://en.wikipedia.org/wiki/Gaussian_quadrature
local point = 1/math.sqrt(3)
local function gaussQuad(f,a,b)
    local bMa = (b-a)/2
    local bPa = (b+a)/2
    return bMa * (f(-point * bMa + bPa) + f(point * bMa + bPa))
end

-- test solver for a known function
-- u = 3x^3 + 2x^2 - x
-- 
-- u" = 18x + 4
-- u(-1) = 0
-- u'(1) = 12
function solver.solveTest(N)
    --square matrix
    local aStep = 2/N
    local a = 1/aStep

    local Baa = -a*a*aStep*2

    local Bab = a*a*aStep

    local mat = {}
    for y=1,N do
        mat[y] = {}
        for x=1,N do
            mat[y][x] = 0
            if math.abs(x-y) < 2 then
                mat[y][x] = Bab
                if (x == y) then
                    mat[y][x] = Baa
                end
            end
        end
    end
    mat[N][N] = Baa/2


    --vector
    local vect = {}
    for i=1,N-1 do
        local f1 = getSideA(aStep*(i)-1,aStep)
        local f2 = getSideB(aStep*(i)-1,aStep)
        local l1 = gaussQuad(function (x) return 18 * x * f1(x) end,aStep*(i-1)-1,aStep*(i)-1)
                    + gaussQuad(function (x) return 18 * x * f2(x) end,aStep*(i)-1,aStep*(i+1)-1)
        local l2 = 4 * (gaussQuad(f1,aStep*(i-1)-1,aStep*(i)-1) + gaussQuad(f2,aStep*(i)-1,aStep*(i+1)-1))
        vect[i] = l1 + l2
    end
    local fLast = getSideA(1,aStep)
    vect[N] = gaussQuad(function (x) return 18 * x * fLast(x) end,1-aStep,1) + 4*gaussQuad(fLast,1-aStep,1) - 12

    --solving the equation
    local alphas = tMatrix.gaussMat(mat,vect,N)

    --adding a 0 as the first alpha
    local alphasCleaned = {0}
    for i=1,N do
        alphasCleaned[i+1] = alphas[i]
    end

    return alphasCleaned
end

--the B(w,v) portion of the equation
local function doubleHeatIntegral(wP,vP,a,b)
    local answer = 0;

    local f1 = function (x)
        return wP(x) * vP(x)
    end

    local f2 = function (x)
        return 2 * x * wP(x) * vP(x)
    end

    if a < 1 and b > 1 then
        answer = gaussQuad(f1,a,1) + gaussQuad(f2,1,b)
    elseif b <= 1 then
        answer = gaussQuad(f1,a,b)
    else
        answer = gaussQuad(f2,a,b)
    end

    return answer
end

-- solver for a heat transfer equation
-- domain = [0,2]
function solver.solveHeat(N)

    local aStep = 2/N
    local a = 1/aStep

    --derivatives of the basis function
    --made this way for modularity (for easier swapping to a different basis function)
    local f1P = function (x)
        return a
    end

    local f2P = function (x)
        return -a
    end

    --optimized tridiagonal matrix representation
    --(...0,A[i],B[i],C[i],0,... is treated as the i row of the matrix, with B[i] being its diagonal element,
    --additionally A[1] and C[N] are nil, as they are outside the matrix)
    local A = {}
    local B = {}
    local C = {}

    local D = {}

    --mat
    for i=1,N-1 do
        B[i+1] = doubleHeatIntegral(f1P,f1P,aStep*(i-1),aStep*(i)) +  doubleHeatIntegral(f2P,f2P,aStep*(i),aStep*(i+1)) 
        A[i+1] = doubleHeatIntegral(f2P,f1P,aStep*(i-1),aStep*(i))
        C[i] = doubleHeatIntegral(f1P,f2P,aStep*(i-1),aStep*(i))
    end
    B[1] = doubleHeatIntegral(f2P,f2P,0,aStep) - 1

    --vect
    for i=1,N-1 do
        local fL1 = function (x)
            return 100 * x^2 * getSideA(aStep*i,aStep)(x)
        end
        local fL2 = function (x)
            return 100 * x^2 * getSideB(aStep*i,aStep)(x)
        end
        D[i+1] = gaussQuad(fL1,aStep*(i-1),aStep*(i)) + gaussQuad(fL2,aStep*(i),aStep*(i+1))
    end

    local fL = function (x)
        return 100 * x^2 * getSideB(0,aStep)(x)
    end
    D[1] = gaussQuad(fL,0,aStep) - 40


    --solving the linear equation
    local alphas = tMatrix.gaussOpt(A,B,C,D,N)

    --used to debug the matrix
    --local display = require("display")
    --display.matrixTri(A,B,C,N)

    --adding a zero as the last alpha
    alphas[N+1] = 0

    return alphas

end


return solver