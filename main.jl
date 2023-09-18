# main.jl
using Base.Threads
using BenchmarkTools
using CSV
using DataFrames
using Latexify
using LaTeXStrings
using LinearAlgebra
using Plots
using Profile
using ProfileView
using Revise
using Symbolics

# include("src/initializer.jl");
include("src/helperFunctions.jl");
include("src/objective.jl");
include("src/optimize.jl");
include("src/display.jl");
include("src/utilities.jl");

global const JULIA_NUM_THREADS = 16

rawDataFolder = "rawData/";
filename = rawDataFolder*"FFD.csv";
df = CSV.File(filename) |> DataFrame;
rename!(df, [:t, :V]);

verbose = false
logging = true

if logging
        if !isdir("./logging")
                println("Creating logging directory since it doesn't exist.")
                mkdir("./logging")
        else 
                println("No need to create logging directory, it already exists.")
                initialize_logging(overwrite=true)
        end
end
scatter_voltage_vs_time(df)

alg = (method = "GradientDescent",
        maxiter = Int(1e3),
        ngtol = 1e-10,
        dftol = 1e-12,
        dxtol = 1e-10,
        lambda = 1,
        lambdaMax = 100,
        # linesearch = "Armijo",
        linesearch = "StrongWolfe",
        c1 = 1e-4, # Pg 33 (3.1 Step Length)
        c2 = 0.9,
        progress = 50);

functionName = "dampedSHM"

if isdefined(Main, :obj)
        println("The obj function of name $(nameof(obj)) is already defined.")
else
        const obj = eval(Symbol(functionName))
        println("We'll be working with the $(nameof(obj)) function.")
end
        

x0 = [13.8, 8.3, 0.022, 1800, 900, 4.2];

pr = (objective=obj, x0=x0, alg=alg, df=df);

# @profile begin
        global res = optimize(pr, verbose=verbose, itrStart=7)
# end
showresults(res)

# For testing linesearch
# fₖ, ∇fₖ = computeCost(pr, x0);
# pₖ = findDirection(pr, ∇fₖ);
# linesearch(pr, x0, pₖ, verbose=true, itrStart=7);

ProfileView.view();
# pₖ = findDirection(pr, g)
# α = linesearch(pr, x0, pₖ, verbose=true)