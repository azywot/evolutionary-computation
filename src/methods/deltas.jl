using DataStructures

include("./local_greedy_search.jl")


function is_applicable(move)
    # TODO
    return true
end


"""
Generate a local search steepest solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_search_previous_deltas(solution, distance_matrix, cost_vector, mode = "edge")
    n = length(solution)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    LM = SortedSet{Tuple}() # (delta, i, j) it is auto sorted by first element, i,j = move i->j
    # add also type: inter/intra?

    best_delta = -1
    while move_found
        move_found = false
        best_delta = 0
        best_solution_found = nothing
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))

        for indices in node_pairs
            new_solution, delta =
                generate_intra_route_move(best_solution, distance_matrix, indices, mode)
            if delta < 0 # brings improvement
                push!(LM, (delta, best_solution[indices[1]], best_solution[indices[2]])) # operate on nodes
            end
        end

        candidate_idx_pairs =
            vec(collect(Iterators.product(unvisited, 1:length(best_solution))))
        for pair in candidate_idx_pairs
            new_solution, delta = generate_inter_route_move(
                best_solution,
                distance_matrix,
                cost_vector,
                pair[1],
                pair[2],
            )
            if delta < 0 # brings improvement
                push!(LM, (delta, best_solution[pair[2]], pair[1])) # operate on nodes
            end
        end

        for i = 1:length(LM)
            if is_applicable(LM[i])
                # accept - perform the move TODO
                move_found = true
                break
            else
                splice!(LM, i) # remove move if not applicable
            end
        end
    end
    return best_solution
end
