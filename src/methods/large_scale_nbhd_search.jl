using Combinatorics

include("./local_greedy_search.jl")
include("./greedy_cycle.jl")

""" 
Perform a tournament selection to select n candidates from a solution.

- `n::Int`: number of candidates to select
- `solution::Vector{Int}`: solution
- `total_node_costs::Vector{Int}`: vector of total node costs
- `tournament_size::Int`: size of the tournament

returns: a vector of indices of the selected candidates
"""
function tournament_selection(n, solution, total_node_costs, tournament_size)
    selected_indices = Set{Int}()
    while length(selected_indices) < n
        tournament_candidates = sample(1:length(solution), tournament_size, replace = false)
        best_candidate = argmax(total_node_costs[tournament_candidates])
        push!(selected_indices, tournament_candidates[best_candidate])
    end
    return collect(selected_indices)
end


"""
Destroy a solution by removing a certain percentage of nodes.

- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `destroy_rate::Float64`: destroy rate
- `tournament_size::Int`: size of the tournament

returns: a destroyed solution
"""
function destroy(solution, distance_matrix, cost_vector, destroy_rate, tournament_size)
    n = length(solution)
    solution = deepcopy(solution)
    total_node_costs = []
    for node in solution
        total_node_cost = cost_vector[node] + distance_matrix[solution[mod(node-2, n) + 1], node] + distance_matrix[node, solution[mod(node, n) + 1]]
        push!(total_node_costs, total_node_cost)
    end

    destroy_number = round(Int, destroy_rate * length(solution))
    selected_indices = tournament_selection(destroy_number, solution, total_node_costs, tournament_size)
    deleteat!(solution, sort(selected_indices))
    return solution    
end


"""
Generate a large scale neighbourhood search solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `config::Dict`: configuration dictionary with keys:
    - `time_limit::Int`: time limit in seconds
    - `destroy_rate::Float64`: destroy rate
    - `use_local_search::Bool`: whether to use local search
    - `mode::String`: mode of the local search, either "node" or "edge"
    - `tournament_size::Int`: size of the tournament
returns: a local search solution and number of iterations
"""
function large_scale_neighbourhood_search(
    solution, 
    distance_matrix, 
    cost_vector, 
    config)

    solution = local_steepest_search(deepcopy(solution), distance_matrix, cost_vector, config["mode"])
    N, _ = size(distance_matrix)

    best_solution = solution
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    start_time = time()
    iterations = 0

    while time() - start_time < config["time_limit"]

        solution_destoryed = destroy(solution, distance_matrix, cost_vector, config["destroy_rate"], config["tournament_size"])
        solution_repaired = greedy_cycle(N, nothing, distance_matrix, cost_vector, solution_destoryed)

        if config["use_local_search"]
            solution = local_steepest_search(solution_repaired, distance_matrix, cost_vector, config["mode"])
        else
            solution = solution_repaired
        end
        cost = evaluate_solution(solution, distance_matrix, cost_vector)

        if cost < best_cost
            best_solution = solution
            best_cost = cost
        end
        iterations += 1
    end

    return best_solution, iterations
end