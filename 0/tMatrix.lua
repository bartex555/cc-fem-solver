--Module for solving a system of linear equations where the matrix is tridiagonal 
--(https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm)
--Provides 2 somewhat different methods, each with two representations of matrices

--Explanation for the optimized representation 
--(also seen on the wikipedia page of Thomas' algorithm)
--(...0,A[i],B[i],C[i],0,... is treated as the i row of the matrix, with B[i] being its diagonal element,
--additionally A[1] and C[N] are nil, as they are outside of the matrix)

local tMatrix = {_TYPE='module', _NAME='tMatrix', _VERSION='0.2'}


--Thomas's algorithm with a normal representation of a matrix
--NOT STABLE, ESPECIALLY WITH HEAVY FLOAT IMPRECISION
--Doesn't change the original matrix
function tMatrix.thomasMat(mat,vect, N)
    local C = {}
    local D = {}
    local X = {}


    C[1] = mat[1][2]/mat[1][1]
    D[1] = vect[1]/mat[1][1]

    for i=2,N-1 do
        local a = mat[i][i-1]
        local b = mat[i][i]
        local c = mat[i][i+1]
        local d = vect[i]

        C[i] = c/(b - a * C[i-1])
        D[i] = (d - a * D[i-1])/(b - a*C[i-1])
    end
    D[N] = (vect[N] - mat[N][N-1] * D[N-1])/(mat[N][N] - mat[N][N-1]*C[N-1])


    X[N] = D[N]

    for i=N-1,1,-1 do
        X[i] = D[i] - C[i]*X[i+1]
    end

    return X
end


--Thomas's algorithm with an optimized representation of a tridiagonal matrix
--NOT STABLE, ESPECIALLY WITH HEAVY FLOAT IMPRECISION
--Doesn't change the original matrix
function tMatrix.thomasOpt(a,b,c,d,N)
    local C = {}
    local D = {}
    local X = {}


    C[1] = c[1]/b[1]
    D[1] = d[1]/b[1]

    for i=2,N-1 do
        C[i] = c[i]/(b[i] - a[i] * C[i-1])
        D[i] = (d[i] - a[i] * D[i-1])/(b[i] - a[i]*C[i-1])
    end
    D[N] = (d[N] - a[N] * D[N-1])/(b[N] - a[N]*C[N-1])


    X[N] = D[N]

    for i=N-1,1,-1 do
        X[i] = D[i] - C[i]*X[i+1]
    end

    return X
end



--A cut-down version of Gaussian elimination, optimized for tridiagonal matrices
--Should be mostly stable, but float imprecision still applies
--Uses the normal matrix representation (but still only works on tridiagonal matrices)
--Changes the original matrix
function tMatrix.gaussMat(mat,vect,N)

    if N == 1 then
        return {vect[1]/mat[1][1]}
    end

    local X = {}

    --gaussian elimination
    for i=1,N-1 do
        --partial pivoting, also eliminates risks with 0s on the diagonal
        if math.abs(mat[i][i]) < math.abs(mat[i+1][i]) then 
            mat[i+1][i],mat[i][i] = mat[i][i],mat[i+1][i]
            mat[i+1][i+1],mat[i][i+1] = mat[i][i+1],mat[i+1][i+1]
            mat[i+1][i+2],mat[i][i+2] = mat[i][i+2],mat[i+1][i+2]
            vect[i],vect[i+1] = vect[i+1],vect[i]
        end

        local multiplier = mat[i+1][i]/mat[i][i]
        mat[i+1][i] = 0
        mat[i+1][i+1] = mat[i+1][i+1] - mat[i][i+1] * multiplier
        if i < N-1 then
            mat[i+1][i+2] = mat[i+1][i+2] - mat[i][i+2] * multiplier
        end

        vect[i+1] = vect[i+1] - vect[i] * multiplier
    end

    --back substitution
    X[N] = vect[N]/mat[N][N]
    X[N-1] = (vect[N-1] - X[N] * mat[N-1][N])/mat[N-1][N-1]
    for i=N-2,1,-1 do
        local curr = vect[i] - X[i+1] * mat[i][i+1] - X[i+2] * mat[i][i+2]

        X[i] = curr/mat[i][i]
    end


    return X

end


--A cut-down version of Gaussian elimination, optimized for tridiagonal matrices
--Should be mostly stable, but float imprecision still applies
--Uses the optimized representation of a tridiagonal matrix
--Changes the original matrix
function tMatrix.gaussOpt(a,b,c,d,N)

    if N == 1 then
        return {d[1]/b[1]}
    end

    local X = {}

    --forth diagonal, used if a swap is needed
    local e = {}


    --gaussian elimination
    for i=1,N-1 do
        --partial pivoting, also eliminates risks with 0s on the diagonal
        if math.abs(b[i]) < math.abs(a[i+1]) then 
            a[i+1],b[i] = b[i],a[i+1]
            b[i+1],c[i] = c[i],b[i+1]
            c[i+1],e[i] = 0,c[i+1]
            d[i],d[i+1] = d[i+1],d[i]
        end
        c[N] = nil --safeguard

        local multiplier = a[i+1]/b[i]
        a[i+1] = 0
        b[i+1] = b[i+1] - c[i] * multiplier
        if e[i] ~= nil then
            c[i+1] = c[i+1] - e[i] * multiplier
        end
        d[i+1] = d[i+1] - d[i] * multiplier
    end


    --back substitution
    for i=N,1,-1 do
        local curr = d[i]
        if c[i] ~= nil then
            curr = curr - c[i]*X[i+1]
        end
        if e[i] ~= nil then
            curr = curr - e[i]*X[i+2]
        end
        X[i] = curr/b[i]
    end


    return X
end






return tMatrix