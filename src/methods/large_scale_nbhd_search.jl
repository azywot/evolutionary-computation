using Combinatorics

include("./local_greedy_search.jl")
include("./greedy_cycle.jl")

"""
Destroy a solution by removing a certain percentage of nodes.

- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `destroy_rate::Float64`: destroy rate

returns: a destroyed solution
"""
function destroy(solution, distance_matrix, cost_vector, destroy_rate)
    solution = deepcopy(solution)
    # TODO: use  distance_matrix, cost_vector while selecting the nodes to destroy
    destroy_number = round(Int, destroy_rate * length(solution))
    destroy_indices = sample(1:length(solution), destroy_number, replace = false)
    deleteat!(solution, sort(destroy_indices))
    return solution    
end


"""
Generate a large scale neighbourhood search solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `time_limit::Int`: time limit in seconds
- `destroy_rate::Float64`: destroy rate
- `use_local_search::Bool`: whether to use local search
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and number of iterations
"""
function large_scale_neighbourhood_search(
    solution, 
    distance_matrix, 
    cost_vector, 
    time_limit, 
    destroy_rate = 0.25, 
    use_local_search = false,
    mode = "edge")

    solution = local_steepest_search(deepcopy(solution), distance_matrix, cost_vector, mode)
    N, _ = size(distance_matrix)

    best_solution = solution
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    start_time = time()
    iterations = 0

    while time() - start_time < time_limit

        solution_destoryed = destroy(solution, distance_matrix, cost_vector, destroy_rate)
        solution_repaired = greedy_cycle(N, nothing, distance_matrix, cost_vector, solution_destoryed)

        if use_local_search
            solution = local_steepest_search(solution_repaired, distance_matrix, cost_vector, mode)
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



"""
Generate a large scale neighbourhood search solution WITH LOCAL SEARCH given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `time_limit::Int`: time limit in seconds
- `destroy_rate::Float64`: destroy rate
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and number of iterations
"""
function large_scale_neighbourhood_search_with_ls(    
    solution, 
    distance_matrix, 
    cost_vector, 
    time_limit, 
    destroy_rate = 0.25, 
    mode = "edge")
    return large_scale_neighbourhood_search(solution, distance_matrix, cost_vector, time_limit, destroy_rate, true, mode)
end