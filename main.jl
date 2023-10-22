include("setup.jl")

println("You are currently using $(Threads.nthreads()) threads.")
println("Your machine has a total of $(Sys.CPU_THREADS) available threads.")

# functionName = "dampedSHM";
functionName = "drag"
# functionName = "Rastrigin2d";
# functionName = "rosenbrock";
# functionName = "rosenbrock2d_oscillatory"
# functionName = "sphere"
# functionName = "TestFunction1";
# functionName = "TestFunction2";
# functionName = "TestFunction3";
if functionName != "drag"
    pr = generate_pr(functionName);
end

# verbose = false
verbose = true;
logging = true;
profiling = false;
benchmarking = false;

@time res = optimize(pr, verbose=verbose)

showresults(res)