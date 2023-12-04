using Combinatorics

include("./local_greedy_search.jl")


function destroy(solution, distance_matrix, cost_vector)
    solution = deepcopy(solution)
    # TODO
    return solution    
end

function repair(solution, distance_matrix, cost_vector)
    solution = deepcopy(solution)
    # TODO
    return solution 
end

"""
Generate a large scale neighbourhood search solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution
"""
function large_scale_neighbourhood_search(solution, distance_matrix, cost_vector, mode)

    solution = solution = local_steepest_search(deepcopy(solution), distance_matrix, cost_vector, mode)
    N, _ = size(distance_matrix)

    best_solution = solution
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    iterations = 10 # TODO: clarify stopping conditions
    destroy_rate = 0.3 # TODO: clarify destroy rate

    for i = 1:iterations
        solution_destoryed = destroy(solution, distance_matrix, cost_vector)
        solution_repaired = repair(solution_destoryed, distance_matrix, cost_vector)
        solution = local_steepest_search(solution_repaired, distance_matrix, cost_vector, mode)
        cost = evaluate_solution(solution, distance_matrix, cost_vector)

        if cost < best_cost
            best_solution = solution
            best_cost = cost
        end
    end

    return best_solution
end