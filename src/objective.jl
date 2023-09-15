# module objective

using DataFrames
using Symbolics

include("helperFunctions.jl");

# export objFun
"""
    objFun(df::DataFrame; getGradientToo=true, getFunctionsToo=true,
        getVariables=true, verbose=false)

Compute the objective function for a decaying sinusoidal model.

# Arguments

- `df::DataFrame`: A DataFrame with columns `t` and `V` where `t` represents time in seconds and `V` represents voltage in millivolts.

# Keyword Arguments

- `getGradientToo::Bool=true`: If true, the function will also compute and return the gradient of the objective function.

- `getFunctionsToo::Bool=true`: If true, the function will also return the numerical (compiled) versions of the symbolic objective function (and its gradient if `getGradientToo` is true).

- `getVariables::Bool=true`: Not used in the provided function code.

- `verbose::Bool=false`: If true, will print out detailed information during the computation. Not implemented in the provided function code.

# Returns

- `fobj`: The symbolic representation of the objective function.

- `∇fobj` (optional): The symbolic gradient of the objective function. Only returned if `getGradientToo=true`.

- `fnum` (optional): The compiled numerical function of the objective function. Only returned if `getFunctionsToo=true`.

- `∇fnum` (optional): The compiled numerical function of the gradient. Only returned if `getGradientToo=true` and `getFunctionsToo=true`.

- `x`: The symbolic vector of parameters used in the model.

# Example

```julia
df = DataFrame(t=[0.1, 0.2, 0.3], V=[0.5, 0.4, 0.3])
fobj, ∇fobj, x = objFun(df)
"""
function objFun(df::DataFrame;
    getGradientToo::Bool=true, 
    getFunctionsToo::Bool=true,
    getVariables::Bool=true, 
    verbose::Bool=false)

    N = size(df, 1)
    @variables t, A₀, A, τ, ω, α, ϕ
    x = [A₀, A, τ, ω, α, ϕ] 

    fsig = A₀ + A*exp(-t/τ)sin((ω+α*t)t + ϕ)
    fobj = mean([(df.V[i] - substitute(fsig, t => df.t[i]))^2 for i in 1:N])

    if getGradientToo
        # Calculate the gradient for each squared difference
        gradients = [Symbolics.gradient(fobj[i], x) 
        for i ∈ eachindex(fobj)]   
        # Sum up the gradients to get the overall gradient
        ∇fobj = sum(gradients)
        if getFunctionsToo
            fnum = build_function(fobj, x, expression=Val{false})
            ∇fnum = build_function(∇fobj, x, expression=Val{false})
            return fobj, ∇fobj, fnum, ∇fnum, x
        else
            return fobj, ∇fobj, x
        end
    else
        if getFunctionsToo
            fnum = build_function(fobj, x, expression=Val{false})
            return fobj, fnum, x
        else
            return fobj, x
        end
    end
end

function buildFunctions_DampedSHM(;
    getGradientToo::Bool=true,
    printSymbolicEquations::Bool=false,
    verbose::Bool=false)

    @variables t, A₀, A, τ, ω, α, ϕ
    x = [A₀, A, τ, ω, α, ϕ] 
    f = A₀ + A*exp(-t/τ)sin((ω+α*t)t + ϕ)
    fnum = build_function(f, x, t, expression=Val{false})
    
    # ∇fnum = nothing
    if getGradientToo
        myprintln(verbose, "I'm getting the gradient as asked.")
        ∇f = Symbolics.gradient(f, x)
        ∇fnum = build_function(∇f, x, t, expression=Val{false})
        ∇fnum = ∇fnum[1] # Only taking the first function from the tuple, no idea why there's a tuple being generated
    else
        ∇fnum = nothing
    end

    if printSymbolicEquations
        println("Function: ", f)
        if getGradientToo
            println("Gradient: ", ∇f)
        end
    end

    return (fnum=fnum, ∇fnum=∇fnum)
end


function dampedSHM(x::Vector{Float64}, t::Float64;
    getGradientToo::Bool=true,
    printSymbolicEquations::Bool=false,
    verbose::Bool=false)

    fnum, ∇fnum = buildFunctions_DampedSHM(printSymbolicEquations=printSymbolicEquations, verbose=verbose)

    fval = fnum(x, t)
    if getGradientToo 
        ∇fval = ∇fnum(x, t)
        return fval, ∇fval
    else
        return fval
    end
end

function findDirection(pr::NamedTuple, ∇fnow::Vector{Float64};
    verbose::Bool=false)::Vector{Float64}
    method = pr.alg.method
    n = length(∇fnow)
    if method == "GradientDescent"
        Bₖ = I(n)
        pₖ = -Bₖ*∇fnow
    else 
        @error "Currently not formulated for this method"
    end

    return pₖ
end

function linesearch(pr::NamedTuple, xnow::Vector{Float64}, 
    t::Float64, pₖ::Vector{Float64};
    verbose::Bool=false)::Float64
    f = Symbol(pr.objective)
    
    linesearch = pr.alg.linesearch
    c₁ = pr.alg.c1
    α = 1e-8
    β = 1
    armijoSatisfied = false
    if linesearch == "StrongWolfe"
        # sufficient decrease condition
    elseif linesearch == "Armijo"
        fnow, ∇fₖ = evaluateFunction(pr, xnow, t)
        while !armijoSatisfied
            diff = β*pₖ
            xnext = xnow+diff
            fnext = evaluateFunction(pr, xnext, t, getGradientToo=false)
            # println(c₁*β*∇fₖ'*pₖ)
            if fnext ≤ fnow + c₁*β*∇fₖ'*pₖ
                myprintln(verbose, "Armijo condition satisfied for β = $(β)")
                armijoSatisfied = true
            else
                β /= 2
                myprintln(verbose, "Armijo condition NOT satisfied for β = $(β)")
            end 
        end
    else 
        @error "Unknown linesearch condition"
    end
    
    α = β
    return α
end

function evaluateFunction(pr, x::Vector{Float64}, t::Float64; kwargs...)
    # Convert the string name to a function symbol
    func_sym = Symbol(pr.objective)
    
    # Dynamically call the function with the provided arguments and keyword arguments
    value = eval(:($func_sym($x, $t; $kwargs...)))
    
    return value
end

# end