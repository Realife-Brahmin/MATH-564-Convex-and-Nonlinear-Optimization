# module objective

using Base.Threads
using DataFrames
using Symbolics

include("helperFunctions.jl");

function dampedSHM(x::Vector{Float64}, 
    p::NamedTuple{(:df, :params), Tuple{DataFrame, Vector{Float64}}};
    getGradientToo::Bool=true)

    df = p.df
    y = df.y
    t = df.x
    n = length(x) # note that df's x (time) is different from function parameter x
    M = length(y)
    A₀, A, τ, ω, α, ϕ = x
    f = 0.0;
    g = zeros(Float64, n)
    for k = 1:M
        tₖ = t[k]
        yₖ = y[k]
        expₖ = exp(-tₖ/τ)
        Sₖ = expₖ*sin((ω+α*tₖ)tₖ + ϕ)
        Cₖ = expₖ*cos((ω+α*tₖ)tₖ + ϕ)

        # ŷₖ = A₀+ A*exp(-tₖ/τ)sin((ω+α*tₖ)tₖ + ϕ)
        ŷₖ = A₀ + A*Sₖ
        Δyₖ = ŷₖ - yₖ
        f += (1/M)*Δyₖ^2
        if getGradientToo
            g += (2/M)* Δyₖ * [1, Sₖ, A*tₖ*(τ^-2)*Sₖ, A*tₖ*Cₖ, A*tₖ^2*Cₖ, A*Cₖ]
        end
    end
    
    if getGradientToo
        return f, g
    else
        return f
    end
end

function dampedSHM_Parallel(x::Vector{Float64}, 
    p::NamedTuple{(:df, :params), Tuple{DataFrame, Vector{Float64}}};
    getGradientToo::Bool=true)

    df = p.df
    y = df.y
    t = df.x
    n = length(x)
    M = length(y)
    A₀, A, τ, ω, α, ϕ = x
    
    f_atomic = Threads.Atomic{Float64}(0.0)  # Make f atomic
    g_atomic = [Threads.Atomic{Float64}(0.0) for _ in 1:n]  # Make each component of g atomic

    @threads for k = 1:M
        tₖ = t[k]
        yₖ = y[k]
        expₖ = exp(-tₖ/τ)
        Sₖ = expₖ*sin((ω+α*tₖ)tₖ + ϕ)
        Cₖ = expₖ*cos((ω+α*tₖ)tₖ + ϕ)

        ŷₖ = A₀ + A*Sₖ
        Δyₖ = ŷₖ - yₖ
        
        Threads.atomic_add!(f_atomic, (1/M)*Δyₖ^2)  # Use atomic add for f
        if getGradientToo
            Δg = (2/M)* Δyₖ * [1, Sₖ, A*tₖ*(τ^-2)*Sₖ, A*tₖ*Cₖ, A*tₖ^2*Cₖ, A*Cₖ]
            for j = 1:n
                Threads.atomic_add!(g_atomic[j], Δg[j])  # Use atomic add for each component of g
            end
        end
    end

    f = f_atomic[]  # Extract the value from atomic
    g = [g_atomic[j][] for j = 1:n]  # Extract values from atomic array

    if getGradientToo
        return f, g
    else
        return f
    end
end

# end