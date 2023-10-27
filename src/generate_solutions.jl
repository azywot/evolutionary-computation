using CSV
using Base.Filesystem
using Statistics
using Tables


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
    times = []
    permutation = []

    best_solution = nothing
    best_cost = Inf

    for i = 1:iter
        time = @elapsed begin
            permutation = method(N, i, distance_matrix, cost_vector)
        end
        push!(times, time)
        cost = evaluate_solution(permutation, distance_matrix, cost_vector)
        push!(values, cost)

        if cost < best_cost
            best_solution = permutation
            best_cost = cost
        end

    end

    filename = splitext(basename(file_path))[1] * "_"
    results_dir = joinpath(dirname(dirname(file_path)), "results")
    dir_path = joinpath(results_dir, "$method")

    stats_file_path = joinpath(dir_path, "$filename" * "stats.csv")

    stats = DataFrame(
        stat = ["mean", "min", "max", "time_mean", "time_min", "time_max"],
        value = [
            mean(values),
            minimum(values),
            maximum(values),
            mean(times),
            minimum(times),
            maximum(times),
        ],
    )

    if !isdir(dir_path)
        mkpath(dir_path)
    end
    CSV.write(stats_file_path, stats)
    # CSV.write("data/$filename" * "solution.csv", Tables.table(permutation), writeheader=false)

    best_solution_file_path = joinpath(dir_path, "$filename" * "best.csv")
    CSV.write(
        best_solution_file_path,
        DataFrame(
            x = [coords[i][1] for i in best_solution],
            y = [coords[i][2] for i in best_solution],
            cost = [cost_vector[i] for i in best_solution],
        ),
    )

end


"""
# Evaluate Statistics for a problem instance given a particaular method.
- `distance_matrix::Matrix{Int64}` : matrix of distances between nodes
- `cost_vector::Vector{Int64}` : vector of costs of nodes
- `coords::Vector{Vector{Int64}}` : coordinates of nodes
- `method::Function`: method to be used to solve the problem
- `start_method::Function`: method to generate initial solution
- `mode::String`: edge or node
- `iter::Int`: number of times to run the method default 200
 #nodes >= iter as it itetates over the nodes while choosing the starting point
"""
function evaluate_local_search(
    distance_matrix,
    cost_vector,
    coords,
    method,
    start_method,
    mode,
    iter,
    file_path,
)
    filename = splitext(basename(file_path))[1] * "_" * "$start_method" * "_" * "$mode"
    results_dir = joinpath(dirname(dirname(file_path)), "results")
    dir_path = joinpath(results_dir, "$method")
    stats_file_path = joinpath(dir_path, "$filename" * "_stats.csv")
    instance = split(filename, "_")[1]

    N = length(cost_vector)
    values = []
    times = []

    best_solution = nothing
    best_cost = Inf

    for i = 1:iter
        if start_method == "greedy_2regret_heuristics"
            start_solution =
                CSV.read("data/$instance" * "_solution.csv", DataFrame, header = false)[
                    !,
                    "Column1",
                ]
        else
            start_solution = start_method(N, i, distance_matrix, cost_vector)
        end
        time = @elapsed begin
            permutation = method(start_solution, distance_matrix, cost_vector, mode)
        end
        push!(times, time)
        cost = evaluate_solution(permutation, distance_matrix, cost_vector)
        push!(values, cost)

        if cost < best_cost
            best_solution = permutation
            best_cost = cost
        end

    end

    stats = DataFrame(
        stat = ["mean", "min", "max", "time_mean", "time_min", "time_max"],
        value = [
            mean(values),
            minimum(values),
            maximum(values),
            mean(times),
            minimum(times),
            maximum(times),
        ],
    )

    if !isdir(dir_path)
        mkpath(dir_path)
    end
    CSV.write(stats_file_path, stats)

    best_solution_file_path = joinpath(dir_path, "$filename" * "_best.csv")
    CSV.write(
        best_solution_file_path,
        DataFrame(
            x = [coords[i][1] for i in best_solution],
            y = [coords[i][2] for i in best_solution],
            cost = [cost_vector[i] for i in best_solution],
        ),
    )
end
