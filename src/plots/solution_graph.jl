using Plots
using CSV
using DataFrames

"""
# Generate
- `solution_path::String`: path to CSV file with the best solution
- `title::String`: title of the plot

returns: distance matrix, cost vector, coordinates
"""
function generate_solution_graph(solution_path, title = nothing)

    if isnothing(title)
        title = replace(splitext(basename(solution_path))[1], "_" => " ")
    end

    df = CSV.read(solution_path, DataFrame)
    cost_scaled = 1 .+ 9 .* (df.cost .- minimum(df.cost)) / (maximum(df.cost) - minimum(df.cost))
    fig = plot(df.x, df.y, 
            marker = :circle, 
            line = :dash, 
            legend = false, 
            markersize = cost_scaled,
            linecolor = :green, 
            markercolor = :green,
            title = title,
            size=(800, 500)
        )
    
    xlabel!("x")
    ylabel!("y")
    plot!([df.x[end], df.x[1]], [df.y[end], df.y[1]], line = :dash, linecolor = :green)

    file_path = joinpath(dirname(solution_path), "plots/" * splitext(basename(solution_path))[1] * ".png")
    savefig(fig, file_path)
end