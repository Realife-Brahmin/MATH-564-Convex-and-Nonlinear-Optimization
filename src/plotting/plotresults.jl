include("plot_fval_vs_iterations.jl")
include("plotDragCurve.jl")
include("plotDenoisedSignal.jl")
include("plotReceiverLocationPlot.jl")
include("plotNeuralNetworkEvaluation.jl")
include("plotMinPathTimeTrajectory.jl")

function plotresults(res;
    savePlot::Bool=true)
    
    plot_fval_vs_iterations(res, savePlot=savePlot)

    pr = res.pr
    functionName = string(pr.objective)
    if functionName == "drag"
        plotDragCurve(res, savePlot=savePlot)
    # elseif functionName == "receiverLocation"
    #     plotReceiverLocationPlot(res, savePlot=savePlot)
    elseif functionName == "signalDenoise"
        plotDenoisedSignal(res, savePlot=savePlot)
    elseif functionName == "nnloss"
        check_training_accuracy(res, savePlot=savePlot)
        check_test_accuracy(res, savePlot=savePlot)
    elseif functionName == "pathtime"
        plotMinPathTimeTrajectory(res, savePlot=savePlot,
        plotTrajectory=false)

    else
        println("Nothing to plot.")
    end
end