using CSV
using DataFrames

include("objective.jl")

function pathtime(x::Vector{Float64}, 
    p;
    verbose::Bool=false,
    log::Bool=true,
    getGradientToo::Bool=true)

    n = Int(length(x)/2)

    params = p[:params]
    m = params[:m]
    w = x[1:n]
    z = x[n+1:2n]

    v = params[:v]
    my, mx = size(v)
    A = params[:A] # A is a tuple (x_a, y_a)
    B = params[:B] # B is a tuple (x_b, y_b)

    s = collect(LinRange(0, 1, m))
    pi_array = collect(1:n)*π
    xx = (1 .- s)*A[1] + s*B[1] + sin.(s * pi_array') * w
    yy = (1 .- s)*A[2] + s*B[2] + sin.(s * pi_array') * z

    
    # From normalized trajectory, computing corresponding matrix element positions
    xxm = 1 .+ xx*(mx-1)
    yym = 1 .+ yy*(my-1) 
    xxm = (xxm[2:end]+xxm[1:end-1])/2
    yym = (yym[2:end]+yym[1:end-1])/2
    # ensuring that xxm, yym do not escape matrix bounds
    xxm = max.(min.(xxm, mx), 1)
    yym = max.(min.(yym, my), 1)

    dist = sqrt.(diff(xx).^2 + diff(yy).^2)
    vel = interpolate_velocity(v, xxm, yym)
    f = sum(dist./vel)

    if getGradientToo
        del = sqrt(eps())
        g = zeros(2*n)
        for j = 1:2*n
            y = x
            y[j] += del
            df = pathtime(y, p, getGradientToo=false)
            g[j] = (df-f)/del
        end
        return f, g
    else
        return f
    end

    @error "forbidden loc"

end

rawDataFolder = "rawData/"
filename = rawDataFolder * "SpeedData.csv"
df = CSV.File(filename, header=false) |> DataFrame

v = Matrix(df)
# rename!(df, [:x, :y])
n = 4
x0 = Float64.(0.1*randn(2*n))
m = 1000
A = (0.05, 0.05)
B = (0.95, 0.95)
params = Dict()
params = Dict(:v => v, :A=>A, :B=>B)

objective = pathtime;

pr = generate_pr(objective, x0, params=params)
# signalDenoise(pr.x0, pr.p)