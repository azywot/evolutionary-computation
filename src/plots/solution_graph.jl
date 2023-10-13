using Plots
using CSV
using DataFrames

"""
# Generate
- `solution_path::String`: path to CSV file with the best solution
- `coords::Vector{Vector{Int64}}`: vector with all the coordinates
- `title::String`: title of the plot

returns: distance matrix, cost vector, coordinates
"""
function generate_solution_graph(solution_path, coords, title = nothing)

    if isnothing(title)
        title = replace(splitext(basename(solution_path))[1], "_" => " ")
    end

    df = CSV.read(solution_path, DataFrame)
    coords = reduce(vcat, transpose.(coords))

    fig = scatter(
        coords[:, 1],
        coords[:, 2],
        marker = :circle,
        legend = false,
        markersize = 4,
        markercolor = :grey,
        title = title,
        size = (800, 500),
    )

    plot!(
        df.x,
        df.y,
        marker = :circle,
        legend = false,
        colorbar = true,
        colorbar_title = "Node cost",
        markersize = 6,
        linecolor = :black,
        zcolor = df.cost,
    )

    xlabel!("x")
    ylabel!("y")
    plot!([df.x[end], df.x[1]], [df.y[end], df.y[1]], linecolor = :black)

    file_path = joinpath(
        dirname(solution_path),
        "plots/" * splitext(basename(solution_path))[1] * ".png",
    )
    savefig(fig, file_path)
end
