include("linesearches.jl")
include("findDirection.jl")
include("types.jl")

function optimize(pr; 
    verbose::Bool=false, 
    verbose_ls::Bool=false,
    log::Bool=true,
    log_path::String="./logging/",
    itrStart::Int64=1)

    log_txt = log_path*"log_"*string(pr.objective)*"_"*pr.alg.method*"_"*pr.alg.linesearch*"_"*string(pr.alg.maxiter)*".txt"

    if isfile(log_txt)
        rm(log_txt)
    end # remove logfile if present for the run

    solverState = SolverStateType()
    solState = SolStateType(xk=pr.x0)

    # Initial settings
    fevals = 0
    gevals = 0
    dftol = pr.alg.dftol
    gtol = pr.alg.gtol
    progress = pr.alg.progress
    maxiter = pr.alg.maxiter
    linesearchMethod = pr.alg.linesearch
    x0 = pr.x0
    xk = x0

    myprintln(verbose, "Starting with initial point x = $(xk).", log_path=log_txt)
    obj = pr.objective
    p = pr.p
    M = max(size(p.data, 1), 1)

    fk = obj(x0, p, getGradientToo=false)
    myprintln(verbose, "which has fval = $(fk)", log_path=log_txt)
    @pack! solState = fk

    if pr.alg.method == "QuasiNewton"
        # QNargs = constructorQNargs(pr, fk=fk)
        @show QNState = QNStateType()
    elseif pr.alg.method == "ConjugateGradientDescent"
        # CGargs = constructorCGargs(pr)
        CGState = CGStateType()
    end
    
    fevals += 1
    @pack! solverState = fevals

    n = length(xk)

    fvals, αvals, gmagvals = [zeros(Float64, maxiter) for _ in 1:3]
    backtrackVals = zeros(Int64, maxiter)
    xvals, gvals = [zeros(Float64, n, maxiter) for _ in 1:2]
    
    myprintln(true, "Begin with the solver:", log=log, log_path=log_txt)
    keepIterationsGoing = true
    causeForStopping = []

    justRestarted = false # automatically false if not doing CGD, and if doing CGD and latest β was not zero.

    # CGDRestartFlag = false # automatically false if not doing CGD, and if doing CGD and latest β was not zero.

    while keepIterationsGoing

        @unpack k = solverState

        printOrNot = verbose && ( (k - 1) % progress == 0)
        printOrNot_ls = printOrNot & verbose_ls


        myprintln(printOrNot, "Iteration $(k):", log_path=log_txt)

        fk, gk = obj(xk, p)
        @checkForNaN fk
        @checkForNaN gk

        gmagk = sum(abs.(gk))
        
        fevals += 1
        gevals += 1

        @pack! solState = fk, gk, gmagk
        @pack! solverState = fevals, gevals

        if pr.alg.method == "QuasiNewton"
            # QNargs.k = k
            # QNargs.xkp1 = xk
            # QNargs.fk = fk
            # QNargs.gkp1 = gk
            @pack! QNState = k, xk, fk, gk
            # pk, QNargs = findDirection(pr, gk, QNargs=QNargs)
            pk, QNState = findDirection(pr, gk, QNState=QNState)

        elseif pr.alg.method == "ConjugateGradientDescent"
            @pack! CGState = k, xk, fk, gk, gmagk
            # CGargs.k = k
            # pk, CGargs = findDirection(pr, gk, CGargs=CGargs)
            pk, CGState = findDirection(pr, gk, CGState=CGState)
            @unpack justRestarted = CGState 
            # CGDRestartFlag = CGargs.justRestarted
            # CGDRestartFlag = false # temporary until new types are inserted
        else
            pk = findDirection(pr, gk)

        end
        
        @pack! solState = pk 

        if linesearchMethod == "StrongWolfe"

            solState, solverState = StrongWolfe(pr, solState, solverState,
            verbose=printOrNot_ls)


        elseif linesearchMethod == "Armijo"
            @error "Armijo no longer supported."
        
        else
            @error "Unknown linesearch method"
        end

        @unpack success_ls = solverState
        if ~success_ls
            myprintln(true, "Line search failed... Bad direction or optimal point?")
            push!(causeForStopping, "LineSearch failed.")
            keepIterationsGoing = false
        end

        @unpack xkm1, xk, fkm1, fk, gkm1, gk, gmagkm1, gmagk = solState

        myprintln(printOrNot, "Iteration $(k): x = $(xk) is a better point with new fval = $(fk).", log_path=log_txt)

        if !justRestarted && abs(fk - fkm1) < dftol
            push!(causeForStopping, "Barely changing fval")
            keepIterationsGoing = false
        end
        if !justRestarted && gmagkm1 < gtol
            push!(causeForStopping, "Too small gradient at previous step.")
            keepIterationsGoing = false
        end
        if !justRestarted && gmagk < gtol
            push!(causeForStopping, "Too small gradient at latest step.")
            keepIterationsGoing = false
        end
        if k == maxiter
            push!(causeForStopping, "Too many iterations")
            keepIterationsGoing = false
        end

        @unpack Hk, alphak = solState
        @unpack alpha_evals = solverState

        fvals[k] = fk
        αvals[k] = alphak
        gvals[:, k] = gk
        gmagvals[k] = gmagk
        backtrackVals[k] = alpha_evals
        xvals[:, k] = xk

        k += 1

        @pack! solverState = k
        @pack! solState = k

    end
    
    @unpack k = solverState

    if k ≥ maxiter
        converged = false
        statusMessage = "Failed to converge despite $(maxiter) iterations! 😢"
        myprintln(true, statusMessage, log=log,  log_path=log_txt)
        @warn statusMessage
    else
        converged = true
        statusMessage = "Convergence achieved in $(k) iterations 😄"
        myprintln(true, statusMessage, log=log, log_path=log_txt)
    end
    
    res = (converged=converged, statusMessage=statusMessage, fvals=fvals, αvals=αvals, backtrackVals=backtrackVals, xvals=xvals, gmagvals=gmagvals, gvals=gvals, M=M, fevals=fevals, gevals=gevals, cause=causeForStopping, pr=pr)

    res = trim_array(res, k-1)
    return res
end

