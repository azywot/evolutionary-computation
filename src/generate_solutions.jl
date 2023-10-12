include("./parse_data.jl")

using Statistics
using CSV

"""
# Evaluate Statistics for a problem instance given a particaular method.
- `distance_matrix::Matrix{Int64}` : matrix of distances between nodes
- `cost_vector::Vector{Int64}` : vector of costs of nodes
- `coords::Vector{Vector{Int64}}` : coordinates of nodes
- `method::Function`: method to be used to solve the problem
- `iter::Int`: number of times to run the method default 200
 #nodes >= iter as it itetates over the nodes while choosing the starting point
"""
function evaluate_statistics(distance_matrix, cost_vector, coords, method, iter, file_path)

    N = length(cost_vector)
    values = []

    best_solution = nothing
    best_cost = 1000000

    for i = 1:iter
        permutation = method(N, i, distance_matrix, cost_vector)
        cost = evaluate_solution(permutation, distance_matrix, cost_vector)
        push!(values, cost)

        if cost < best_cost
            best_solution = permutation
            best_cost = cost
        end

    end

    filename = splitext(basename(file_path))[1] * "_"

    stats_file_path =
        joinpath(dirname(dirname(file_path)), "results", "$filename$method" * "_stats.csv")
    stats = DataFrame(
        stat = ["mean", "min", "max"],
        value = [mean(values), minimum(values), maximum(values)],
    )
    CSV.write(stats_file_path, stats)

    best_solution_file_path =
        joinpath(dirname(dirname(file_path)), "results", "$filename$method" * "_best.csv")
    CSV.write(
        best_solution_file_path,
        DataFrame(
            x = [coords[i][1] for i in best_solution],
            y = [coords[i][2] for i in best_solution],
            cost = [cost_vector[i] for i in best_solution],
        ),
    )

end
