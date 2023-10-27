using Plots
using CSV
using DataFrames

"""
# Generate
- `solution_path::String`: path to CSV file with the best solution
- `coords::Vector{Vector{Int64}}`: vector with all the coordinates
- `cost_vector::Vector{Int64}`: vector with all the costs
- `method::String`: method used to generate the solution

returns: distance matrix, cost vector, coordinates
"""
function generate_solution_graph(solution_path, coords, cost_vector, method)

    title =
        uppercase(replace(method * " " * splitext(basename(solution_path))[1], "_" => " "))

    df = CSV.read(solution_path, DataFrame)
    coords = reduce(vcat, transpose.(coords))

    fig = scatter(
        coords[:, 1],
        coords[:, 2],
        marker = :x,
        legend = false,
        markersize = 4,
        zcolor = cost_vector,
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


    previous_filename = splitext(basename(solution_path))[1]

    file_path = joinpath(dirname(solution_path), previous_filename * ".png")
    savefig(fig, file_path)
end
