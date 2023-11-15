using DataStructures

include("./local_greedy_search.jl")

"""
State whether the solution is applicable to the move.
- `solution::Vector{Int}`: solution
- `move::Dict`: move

returns: true if applicable, false otherwise
returns: true if valid, false otherwise
"""
function is_applicable_is_valid(solution, move)
    if move["move"] == "intra_forward"
        return true, true # TODO
    elseif move["move"] == "intra_backward"
        return true, true # TODO
    elseif move["move"] == "inter"
        return true, true # TODO
    end
end

"""
Apply the move to the solution.
- `solution::Vector{Int}`: solution
- `move::Dict`: move

returns: a new solution
"""
function apply_move(solution, move)

    node1, node2 = move["nodes"][1], move["nodes"][2]

    if move["move"] == "intra_forward"
        node1_index = findfirst(==(node1), solution)
        node2_index = findfirst(==(node2), solution)
        new_solution, _ = generate_intra_route_move(
            solution,
            distance_matrix,
            [node1_index, node2_index],
            mode,
        )
        return new_solution

    elseif move["move"] == "intra_backward"
        node1_index = findfirst(==(node1), solution)
        node2_index = findfirst(==(node2), solution)
        new_solution, _ = generate_intra_route_move(
            solution,
            distance_matrix,
            [node1_index, node2_index],
            mode,
            true,
        )
        return new_solution

    else # inter move
        node_index = findfirst(==(node2), solution)
        new_solution, _ = generate_inter_route_move(
            solution,
            distance_matrix,
            cost_vector,
            node1,
            node_index,
        )
        return new_solution
    end
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

    N = length(solution)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    LM = SortedSet{Tuple{Float64, Dict}}() 
    # (delta, Dict("node1", "node2", "move", "direction)) it is auto sorted by first element
    # "nodes" are the nodes that are moved, "move" - intra_forward/intra_backward/inter

    move_found = true

    while length(LM) > 0

        move_found = false
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))
        node_pairs = collect(Combinatorics.combinations(1:length(solution), 2))

        # intra moves
        for indices in node_pairs
            # forward search
            _, delta = generate_intra_route_move(best_solution, distance_matrix, indices, mode)
            if delta < 0 # brings improvement
                dict = Dict("nodes" => [best_solution[indices[1]], best_solution[indices[2]]], 
                            "move"  => "intra_forward") 
                push!(LM, (delta, dict)) # operate on nodes
            end

            # backward search
            _, delta = generate_intra_route_move(best_solution, distance_matrix, indices, mode, true)
            if delta < 0 # brings improvement
                dict = Dict("nodes" => [best_solution[indices[1]], best_solution[indices[2]]], 
                            "move"  => "intra_backward")
                push!(LM, (delta, dict)) # operate on nodes
            end
        end

        # inter moves
        candidate_idx_pairs = vec(collect(Iterators.product(unvisited, 1:length(best_solution))))
        for pair in candidate_idx_pairs
            _, delta = generate_inter_route_move(
                best_solution,
                distance_matrix,
                cost_vector,
                pair[1],
                pair[2],
            )
            if delta < 0 # brings improvement
                dict = Dict("nodes" => [pair[1], best_solution[pair[2]]], 
                            "move"  => "inter")
                push!(LM, (delta, dict)) # operate on nodes
            end
        end

        for i = eachindex(LM)
            applicable, valid = is_applicable_is_valid(best_solution, LM[i][2])
            if applicable
                move_found = true
                best_solution = apply_move(best_solution, LM[i][2])
                splice!(LM, i) # remove move as it is performed
                break
            elseif !valid
                splice!(LM, i) # remove move if not valid
            end
        end
    end
    return best_solution
end
