using Parameters

"""
    SolStateType

A mutable struct used to maintain the state of the solution in an optimization solver.

# Fields
- `k::Int`: The current iteration number.
- `xkm1::Vector{Float64}`: The solution vector from the previous iteration.
- `xk::Vector{Float64}`: The current solution vector.
- `fkm1::Float64`: The objective function value at the previous iteration.
- `fk::Float64`: The current objective function value.
- `gkm1::Vector{Float64}`: The gradient of the objective function at the previous iteration.
- `gk::Vector{Float64}`: The current gradient of the objective function.
- `gmagkm1::Float64`: The magnitude of the gradient at the previous iteration.
- `gmagk::Float64`: The current magnitude of the gradient.
- `pkm1::Vector{Float64}`: The search direction used in the previous iteration.
- `pk::Vector{Float64}`: The current search direction.
- `Hkm1::Matrix{Float64}`: The inverse approximate Hessian from the previous iteration.
- `Hk::Matrix{Float64}`: The current approximate inverse Hessian.
- `alphak::Float64`: The step size used in the current iteration.

# Constructor
The constructor for `SolStateType` can be called with keyword arguments corresponding to each field. If a field is not specified, it defaults to a pre-defined value such as `1` for `k`, `0.0` for scalar values, an empty `Float64` array for vector fields, or an undefined `0x0` `Float64` matrix for matrix fields.

# Example Usage
```julia
    solState = SolStateType(k=5, xkm1=[1.0, 2.0], xk=[1.5, 2.5])
```
This will create a `SolStateType` instance with the iteration number set to `5`, previous solution vector as `[1.0, 2.0]`, and current solution vector as `[1.5, 2.5]`. All other fields will be set to their default values.

Please note that the fields `Hkm1` and `Hk` are initialized with undefined matrices. It is expected that the user will provide properly sized and initialized matrices if these fields are to be used.

"""
mutable struct SolStateType
    k::Int
    xkm1::Vector{Float64}
    xk::Vector{Float64}
    fkm1::Float64
    fk::Float64
    gkm1::Vector{Float64}
    gk::Vector{Float64}
    gmagkm1::Float64
    gmagk::Float64
    pkm1::Vector{Float64}
    pk::Vector{Float64}
    Hkm1::Matrix{Float64}
    Hk::Matrix{Float64}
    alphak::Float64
    

    function SolStateType(;
        k=1, 
        xkm1=Float64[], xk=Float64[],
        fkm1=0.0, fk=0.0,
        gkm1=Float64[], gk=Float64[],
        gmagkm1=0.0, gmagk=0.0, 
        pkm1=Float64[], pk=Float64[], 
        Hkm1=Matrix{Float64}(undef, 0, 0), Hk=Matrix{Float64}(undef, 0, 0), 
        alphak=0.0)

        new(k, xkm1, xk, fkm1, fk, gkm1, gk, gmagkm1, gmagk, pkm1, pk, Hkm1, Hk, alphak)
    end

end

"""
    SolverStateType

A mutable struct that holds the state of the optimization solver. It tracks the iteration count and the number of function, gradient, and Hessian evaluations, as well as the success of the line search.

Fields:

- `k`: The current iteration number.
- `fevals`: The cumulative number of function evaluations performed.
- `gevals`: The cumulative number of gradient evaluations performed.
- `Hevals`: The cumulative number of Hessian evaluations performed.
- `alpha_evals`: The number of evaluations for the current step size.
- `success_ls`: A Boolean flag indicating whether the last line search was successful.

Constructor:

The constructor accepts keyword arguments for each of the fields. Default values are provided for all fields.
Example Usage:

Create a new instance by specifying any of the fields. For example:
```julia
solverState = SolverStateType(k=10, fevals=50, gevals=50)
```
"""
mutable struct SolverStateType
    k::Int
    fevals::Int
    gevals::Int
    Hevals::Int
    alpha_evals::Int # only current evals
    success_ls::Bool

    function SolverStateType(;
        k=1, 
        fevals=0, 
        gevals=0, 
        Hevals=0, 
        success_ls=false)
        new(k, fevals, gevals, Hevals, success_ls)
    end
end

"""
    InterpolParams

A mutable struct used within the line search algorithm to manage interpolation parameters, specifically focused on determining an acceptable step size, alphaj.

Fields:

- `j`: The current interpolation iteration.
- `alphaj`: The trial step size being evaluated.
- `alphaLo`: The current lower bound on the step size.
- `alphaHi`: The current upper bound on the step size.
- `alphatol`: The tolerance within which the step size is considered acceptable.
- `alphatolBreached`: A Boolean flag indicating whether the tolerance criterion has been breached.
- `change`: A string indicating if the next step size should be increased, decreased, or remain unchanged.

Constructor:

The constructor for InterpolParams accepts keyword arguments for each of the fields. Default values are assumed for all fields except change, which should be explicitly specified.
Example Usage:

An instance of InterpolParams can be created and used to control the bisection process within a line search method. For example:
```julia
interpolParams = InterpolParams(j=2, alphaj=50.0, change="decrease")
```
Ensure to correctly initialize and update all fields within these structures as per the requirements of your optimization algorithm.

"""
mutable struct InterpolParams
    j::Int
    alphaj::Float64
    alphaLo::Float64
    alphaHi::Float64
    alphatol::Float64
    alphatolBreached::Bool
    change::String

    function InterpolParams(;j=1, alphaj=100.0, alphaLo=0.0, alphaHi=100.0, alphatol=1e-10, alphatolBreached=false, change="noChange")
        new(j, alphaj, alphaLo, alphaHi, alphatol, alphatolBreached, change)
    end

end

"""
    CGStateType

A mutable struct designed to encapsulate the state and parameters pertinent to the Conjugate Gradient (CG) optimization method.

Fields:
- `k`: The global iteration counter across all optimization methods.
- `kCGD`: The iteration counter specific to the CG method.
- `gkm1`: The gradient vector at the previous CG iteration (`kCGD-1`).
- `gk`: The gradient vector at the current CG iteration (`kCGD`).
- `pkm1`: The search direction used in the previous CG iteration (`kCGD-1`).
- `pk`: The search direction for the current CG iteration (`kCGD`).
- `betakm1`: The β parameter value from the previous CG iteration used to compute `pkm1`.
- `betak`: The β parameter for the current CG iteration used to compute `pk`.
- `justRestarted`: A Boolean flag to indicate whether the CG method was restarted in the last CG iteration.

Constructor:
- The `CGStateType` constructor initializes the struct with the provided values or with default values if none are given. Default values are 1 for `k` and `kCGD`, zero vectors for `gkm1` and `gk`, zero vectors for `pkm1` and `pk`, and 0.0 for `betakm1` and `betak`. The `justRestarted` flag defaults to `false`.

Example Usage:
- To instantiate a `CGStateType` with default values:
    ```julia
    cgState = CGStateType()
    ```
- To set up with specific initial values for the CG method:
    ```julia
    cgState = CGStateType(k=3, kCGD=2, gkm1=[-1.0, -1.0], gk=[-0.5, -0.5], betakm1=0.5, betak=0.3, justRestarted=true)
    ```

This struct is utilized in each step of the CG method to maintain the necessary data for computing new search directions and for deciding when to restart the algorithm based on the `justRestarted` flag.
"""
mutable struct CGStateType
    k::Int
    kCGD::Int
    gkm1::Vector{Float64}
    gk::Vector{Float64}
    pkm1::Vector{Float64}
    pk::Vector{Float64}
    betakm1::Float64
    betak::Float64
    justRestarted::Bool

    function CGStateType(;
        k=1, kCGD=1,
        gkm1=Float64[], gk=Float64[],
        pkm1=Float64[], pk=Float64[], 
        betakm1=0.0, betak=0.0,
        justRestarted=false)

        new(k, kCGD, gkm1, gk, pkm1, pk, betakm1, betak, justRestarted)

    end

end

"""
    QNStateType

A mutable struct that holds the state of a Quasi-Newton (QN) optimization algorithm at each iteration.

Fields:
- `k`: The current iteration number.
- `xkm1`: The vector representing the solution at the previous iteration (`k-1`).
- `xk`: The vector representing the current solution at iteration `k`.
- `fkm1`: The value of the objective function at the previous iteration (`k-1`).
- `fk`: The value of the objective function at the current iteration (`k`).
- `gkm1`: The gradient vector of the objective function at the previous iteration (`k-1`).
- `gk`: The gradient vector of the objective function at the current iteration (`k`).
- `pkm1`: The search direction used in the previous iteration (`k-1`).
- `pk`: The search direction used in the current iteration (`k`).
- `Hkm1`: The approximation to the Hessian matrix or its inverse at the previous iteration (`k-1`).
- `Hk`: The approximation to the Hessian matrix or its inverse at the current iteration (`k`).

Constructor:
- The constructor for `QNStateType` can be called with keyword arguments for each field. If a field is not specified, it defaults to initial values such as `1` for `k`, `0.0` for scalar fields, empty arrays for vector fields, and an undefined `0x0` matrix for matrix fields.

Example Usage:
- To create a new instance of `QNStateType` with default initial values, you can simply call:
    ```julia
    qnState = QNStateType()
    ```
- To initialize with custom values for the current iteration, you could use:
    ```julia
    qnState = QNStateType(k=2, xkm1=[1.0, 1.0], xk=[1.5, 1.5], fkm1=10.0, fk=5.0)
    ```

This struct is instrumental in carrying forward information from one iteration to the next in a QN optimization routine, allowing for efficient updates of the solution vector and the approximation of the Hessian matrix.
"""
mutable struct QNStateType
    k::Int
    xkm1::Vector{Float64}
    xk::Vector{Float64}
    fkm1::Float64
    fk::Float64
    gkm1::Vector{Float64}
    gk::Vector{Float64}
    pkm1::Vector{Float64}
    pk::Vector{Float64}
    Hkm1::Matrix{Float64}
    Hk::Matrix{Float64}

    function QNStateType(;
        k=1, 
        xkm1=Float64[], xk=Float64[],
        fkm1=0.0, fk=0.0,
        gkm1=Float64[], gk=Float64[],
        pkm1=Float64[], pk=Float64[], 
        Hkm1=Matrix{Float64}(undef, 0, 0), Hk=Matrix{Float64}(undef, 0, 0))

        new(k, xkm1, xk, fkm1, fk, gkm1, gk, pkm1, pk, Hkm1, Hk)
    end

end

function TRparamsType(;
    Delta = 50.0,
    Delta_min = 1e-3,
    Delta_max = 100.0,
    etta_1 = 0.01,
    etta_2 = 0.25,
    etta_3 = 0.75,
    delta_1 = 0.25,
    delta_2 = 2.0,
    updateRadius = "uninitialized",
    accept = false
    )

    TRparams = Dict(
        :Delta => Delta,
        :Delta_min => Delta_min,
        :Delta_max => Delta_max,
        :etta_1 => etta_1,
        :etta_2 => etta_2,
        :etta_3 => etta_3,
        :delta_1 => delta_1,
        :delta_2 => delta_2,
        :updateRadius => updateRadius,
        :accept => accept
    )

    return TRparams
end

function SR1paramsType(;
    xkm1 = Vector{Float64}(undef, 0),
    gkm1 = Vector{Float64}(undef, 0),
    Bkm1 = Matrix{Float64}(undef, 0, 0)
    )

    SR1params = Dict(
        :xkm1 => xkm1,
        :gkm1 => gkm1,
        :Bkm1 => Bkm1
    )

    return SR1params
end

# SR1params = SR1paramsType()
# TRparams = TRparamsType()
# solState = SolStateType()
# solverState = SolverStateType()
# interpolParams = InterpolParams(alphatol=33)
# CGState = CGStateType()
# QNState = QNStateType()