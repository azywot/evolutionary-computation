using CSV
using Base.Filesystem
using Statistics
using Tables


"""
Parse values and times into dataframe with statistics
- `values::Vector{Int64}` : obtained values
- `times::Vector{Int64}` : obtained times
returns: dataframe with stats
"""
function get_stats_df(
    values,
    times,
    columns = ["mean", "min", "max", "time_mean", "time_min", "time_max"],
)
    stats = DataFrame(
        stat = columns,
        value = [
            mean(values),
            minimum(values),
            maximum(values),
            mean(times),
            minimum(times),
            maximum(times),
        ],
    )
    return stats
end


"""
Save best solution to file
- `filepath::String` : filepath to save results
- `coords::Vector{Vector{Int64}}` : coordinates of nodes
- `solution::Vector{Int64}` : solution
- `cost_vector::Vector{Int64}` : vector of costs of nodes
returns: dataframe with stats
"""
function save_solution(filepath, coords, solution, cost_vector)
    CSV.write(
        filepath,
        DataFrame(
            x = [coords[i][1] for i in solution],
            y = [coords[i][2] for i in solution],
            cost = [cost_vector[i] for i in solution],
        ),
    )
end


"""
 Evaluate Statistics for a problem instance given a particaular method.
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
    stats = get_stats_df(values, times)

    if !isdir(dir_path)
        mkpath(dir_path)
    end
    CSV.write(stats_file_path, stats)
    # CSV.write("data/$filename" * "solution.csv", Tables.table(permutation), writeheader=false)

    best_solution_file_path = joinpath(dir_path, "$filename" * "best.csv")
    save_solution(best_solution_file_path, coords, best_solution, cost_vector)
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
        if start_method == "greedy_cycle"
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

    stats = get_stats_df(values, times)
    if !isdir(dir_path)
        mkpath(dir_path)
    end
    CSV.write(stats_file_path, stats)

    best_solution_file_path = joinpath(dir_path, "$filename" * "_best.csv")
    save_solution(best_solution_file_path, coords, best_solution, cost_vector)
end


"""
# Evaluate Statistics for Multiple start local search (MSLS) and iterated local search (ILS)
- `distance_matrix::Matrix{Int64}` : matrix of distances between nodes
- `cost_vector::Vector{Int64}` : vector of costs of nodes
- `coords::Vector{Vector{Int64}}` : coordinates of nodes
- `msls_iterations::Int`: number of iterations for MSLS
- `methods_iterations::Int`: number of iterations for both MSLS and ILS
- `file_path::String`: path to the file
- `verbose::Bool`: verbose mode
- `mode::String`: edge or node
"""
function evaluate_msls_ils(
    distance_matrix,
    cost_vector,
    coords,
    msls_iterations,
    methods_iterations,
    file_path,
    verbose = false,
    mode = "edge",
)
    results_dir = joinpath(dirname(dirname(file_path)), "results")
    filename = splitext(basename(file_path))[1]

    msls_dir_path = joinpath(results_dir, "msls")
    msls_stats_file_path = joinpath(msls_dir_path, "$filename" * "_stats.csv")

    ils_dir_path = joinpath(results_dir, "ils")
    ils_stats_file_path = joinpath(ils_dir_path, "$filename" * "_stats.csv")

    msls_times = []
    msls_values = []
    msls_best_solution = nothing
    msls_best_cost = Inf
    for i = 1:methods_iterations
        time = @elapsed begin
            msls_solution = multiple_start_local_search(
                distance_matrix,
                cost_vector,
                msls_iterations,
                mode,
            )
        end
        msls_cost = evaluate_solution(msls_solution, distance_matrix, cost_vector)
        if msls_cost < msls_best_cost
            msls_best_solution = msls_solution
            msls_best_cost = msls_cost
        end

        push!(msls_times, time)
        push!(msls_values, msls_cost)
    end

    time_limit = mean(msls_times)
    if verbose
        println(
            "MSLS time stats: ",
            time_limit,
            " (",
            minimum(msls_times),
            " - ",
            maximum(msls_times),
            ")",
        )
        println(
            "MSLS cost stats: ",
            mean(msls_values),
            " (",
            minimum(msls_values),
            " - ",
            maximum(msls_values),
            ")",
        )
    end

    ls_runs = []
    ils_values = []
    ils_best_solution = nothing
    ils_best_cost = Inf
    for i = 1:methods_iterations
        ils_solution, runs =
            iterated_local_search(distance_matrix, cost_vector, time_limit, mode)
        ils_cost = evaluate_solution(ils_solution, distance_matrix, cost_vector)
        if ils_cost < ils_best_cost
            ils_best_solution = ils_solution
            ils_best_cost = ils_cost
        end
        push!(ls_runs, runs)
        push!(ils_values, ils_cost)
    end

    if verbose
        println(
            "ILS steepest counter stats: ",
            mean(ls_runs),
            " (",
            minimum(ls_runs),
            " - ",
            maximum(ls_runs),
            ")",
        )
        println(
            "ILS cost stats: ",
            mean(ils_values),
            " (",
            minimum(ils_values),
            " - ",
            maximum(ils_values),
            ")",
        )
    end

    msls_stats = get_stats_df(msls_values, msls_times)
    if !isdir(msls_dir_path)
        mkpath(msls_dir_path)
    end
    CSV.write(msls_stats_file_path, msls_stats)
    best_solution_file_path = joinpath(msls_dir_path, "$filename" * "_best.csv")
    save_solution(best_solution_file_path, coords, msls_best_solution, cost_vector)

    ils_stats = get_stats_df(
        ils_values,
        ls_runs,
        ["mean", "min", "max", "ls_runs_mean", "ls_runs_min", "ls_runs_max"],
    )
    if !isdir(ils_dir_path)
        mkpath(ils_dir_path)
    end
    CSV.write(ils_stats_file_path, ils_stats)
    best_solution_file_path = joinpath(ils_dir_path, "$filename" * "_best.csv")
    save_solution(best_solution_file_path, coords, ils_best_solution, cost_vector)
end
