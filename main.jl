# main.jl
using BenchmarkTools
using CSV
using DataFrames
using Latexify
using LaTeXStrings
using LinearAlgebra
using Plots
using Revise
using Symbolics

include("src/utilities.jl");
include("src/initializer.jl");
include("src/objective.jl");
include("src/plotter.jl");

rawDataFolder = "rawData/";
filename = rawDataFolder*"FFD.csv";
df = CSV.File(filename) |> DataFrame;
rename!(df, [:t, :V]);

scatter_voltage_vs_time(df)

alg = (method = "GradientDescent",
        maxiter = 200,
        ngtol = 1e-8,
        dxtol = 1e-8,
        lambda = 1,
        lambdaMax = 100,
        linesearch = "Armijo",
        c1 = 0.0001,
        c2 = 0.9,
        progress = 10);


f, ∇f, fnum, ∇fnum, x = objFun(df);

x0 = estimate_x0(df, x)
x01 = [13.8, 8.3, 0.022, 1800, 900, 4.2]
# fnum([x0[1], 1, 1, 1, 1, 1])
fnum(x0) # should be close to A₀ ≈ 13.76
fnum(x01)
# lol it got worse after I inserted a more sensible value of A?






