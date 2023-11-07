include("./local_greedy_search.jl")


"""
Get nearest (in terms of optimized function) n vertices to the provided node
- `node::Int`: node of interect
- `total_cost_matrix::Matrix{Int}`: matrix of distances+costs between nodes
- `n::Int`: number of nearest vertices to find

returns: n nearest vertices
"""
function get_nearest_n_vertices(node, total_cost_matrix, n = 10)
    # should we consider only unvisited? (yes?)
    neighbours = total_cost_matrix[node, :]
    return partialsortperm(neighbours, 1:n)
end


"""
Generate a local search steepest solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_search_candidate_moves(
    solution,
    distance_matrix,
    cost_vector,
    mode = "edge",
)
    n = length(solution)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    # println("Initial cost: ", best_cost)

    best_delta = -1
    while best_delta < 0
        best_delta = 0
        best_solution_found = nothing

        for idx in eachindex(best_solution)
            candidates = get_nearest_n_vertices(best_solution[idx], distance_matrix)
            for candidate in candidates
                if candidate in best_solution
                    candidate_idx = findfirst(item -> item == candidate, best_solution)
                    if idx < candidate_idx
                        indices = [idx, candidate_idx]
                    else
                        indices = [candidate_idx, idx]
                    end
                    new_solution1, delta1 = generate_intra_route_move(best_solution, distance_matrix, indices, mode)
                    new_solution2, delta2 = generate_intra_route_move(best_solution, distance_matrix, indices, mode, true) # reverse_search
                    new_solution, delta = (delta1 < delta2) ? (new_solution1, delta1) : (new_solution2, delta2)
                else
                    # swap with idx-1 with a candidate
                    new_solution1, delta1 = generate_inter_route_move(
                        best_solution,
                        distance_matrix,
                        cost_vector,
                        candidate,
                        mod(idx-2, n) + 1,
                    )

                    # swap with idx+1 with a candidate
                    new_solution2, delta2 = generate_inter_route_move(
                        best_solution,
                        distance_matrix,
                        cost_vector,
                        candidate,
                        mod(idx, n) + 1,
                    )

                    new_solution, delta = (delta1 < delta2) ? (new_solution1, delta1) : (new_solution2, delta2)
                end

                if delta < best_delta
                    best_solution_found = deepcopy(new_solution)
                    best_delta = delta
                end
            end
        end

        if best_delta < 0
            best_solution = deepcopy(best_solution_found)
            best_cost += best_delta
        end
    end
    # println("Local minimum reached with cost ", best_cost)
    return best_solution
end
