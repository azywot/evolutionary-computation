using Plots
using CSV
using DataFrames
using Statistics

"""
# Generate
- `solution_path::String`: path to CSV file with the best solution
- `coords::Vector{Vector{Int64}}`: vector with all the coordinates
- `cost_vector::Vector{Int64}`: vector with all the costs
- `method::String`: method used to generate the solution
- `title::String`: title of the plot

returns: distance matrix, cost vector, coordinates
"""
function generate_solution_graph(solution_path, coords, cost_vector, method, title=nothing)

    if isnothing(title)
        title =
        uppercase(replace(method * " " * splitext(basename(solution_path))[1], "_" => " "))
    else
        title = uppercase(title)
    end

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


function generate_similarity_test_charts(df_path, title = nothing)
    
    correlation_coefficients = []
    if isnothing(title)
        title = uppercase(splitext(basename(df_path))[1])
    else
        title = uppercase(title)
    end

    df = CSV.read(df_path, DataFrame)
    title = uppercase(title)
    previous_filename = splitext(basename(df_path))[1]

    for column in names(df)
        if column == "cost"
            continue
        end
        parts = split(column, "_")
        y_label = join(parts[1:end-1], " ")
        y_label_full = y_label * " (" * parts[end] * ")"

        corr_coeff = cor(df.cost, df[!, column])
        push!(correlation_coefficients, (column, corr_coeff))

        fig = scatter(
                df.cost, 
                df[!, column], 
                xlabel="objective function", 
                ylabel=y_label, 
                title=title * " - " * y_label_full,
                legend=false,
                color=:green,
                )

        file_path = joinpath(dirname(df_path), previous_filename * "_$column" * ".png")
        savefig(fig, file_path)
    end

    corr_file_path = joinpath(dirname(df_path), previous_filename * "_correlation_coefficients.csv")
    corr_df = DataFrame(
        y = [x[1] for x in correlation_coefficients],
        cor = [x[2] for x in correlation_coefficients],
    )
    CSV.write(corr_file_path, corr_df)
end
