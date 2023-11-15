using DataStructures

include("./local_greedy_search.jl")

""" 
Check whether the order of the nodes is preserved in the solution.
- `nodes::Vector{Int}`: nodes
- `solution::Vector{Int}`: solution

returns: true if edge exists, false otherwise
returns: true if order is preserved, false otherwise
"""
function edge_exists_order_preserved(nodes, solution)
    if !(nodes[1] in solution) || !(nodes[2] in solution)
        return false, false
    end
    pos_1 = findfirst(==(nodes[1]), solution)
    pos_2 = findfirst(==(nodes[2]), solution)

    edge_exists = pos_1 + 1 == pos_2 || pos_2 + 1 == pos_1
    order_preserved = pos_1 + 1 == pos_2
    return edge_exists, order_preserved
end


"""
State whether the solution is applicable to the move.
- `solution::Vector{Int}`: solution
- `move_tuple::Tuple`: move tuple

returns: true if applicable, false otherwise
returns: true if is to be stored, false otherwise
"""
function is_applicable_is_stored(solution, move_tuple)
    nodes, nodes_intra, move = move_tuple

    # inter move
    if move == "inter"
        if !(nodes[1] in solution) && nodes[2] in solution
            return true, false 
        end
        return false, false
    end

    # intra move
    edge1, edge2 = [], []
    if move == "intra_forward"
        edge1 = [nodes[1], nodes_intra[1]]
        edge2 = [nodes[2], nodes_intra[2]]
    else move == "intra_backward"
        edge1 = [nodes_intra[1], nodes[1]]
        edge2 = [nodes_intra[2], nodes[2]]
    end

    edge_exists1, order_preserved1 = edge_exists_order_preserved(edge1, solution)
    edge_exists2, order_preserved2 = edge_exists_order_preserved(edge2, solution)
    if edge_exists1 && edge_exists2
        if order_preserved1 && order_preserved2
            return true, false
        else
            return false, true
        end
    end
    return false, false
end


"""
Apply the move to the solution.
- `solution::Vector{Int}`: solution
- `move_tuple::Tuple`: move tuple
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a new solution
"""
function apply_move(solution, move_tuple, distance_matrix, cost_vector, mode)
    nodes, _, move = move_tuple

    if move == "intra_forward"
        node1_index = findfirst(==(nodes[1]), solution)
        node2_index = findfirst(==(nodes[2]), solution)
        new_solution, _ = generate_intra_route_move(
            solution,
            distance_matrix,
            [node1_index, node2_index],
            mode,
        )
        return new_solution

    elseif move == "intra_backward"
        node1_index = findfirst(==(nodes[1]), solution)
        node2_index = findfirst(==(nodes[2]), solution)
        new_solution, _ = generate_intra_route_move(
            solution,
            distance_matrix,
            [node1_index, node2_index],
            mode,
            true,
        )
        return new_solution

    else # inter move
        node_index = findfirst(==(nodes[2]), solution)
        new_solution, _ = generate_inter_route_move(
            solution,
            distance_matrix,
            cost_vector,
            nodes[1],
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

    N, _ = size(distance_matrix)
    n = length(solution)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    LM_dict = Dict{Tuple{Vector{Int64}, Vector{Int64}, String}, Float64}()
    # LM = SortedSet{Tuple{Float64, Vector{Int64}, Vector{Int64}, String}}() 
    # (delta, nodes, nodes_intra, move)) it is auto sorted by first element
    # nodes - the nodes that are moved
    # nodes_intra - nodes in the intra mode 
    #       eg. for node1: nodes[1] -> nodes_intra[1] in forward search
    #               nodes[1] -> nodes_intra[1] in backward search 
    # move - intra_forward/intra_backward/inter

    move_found = true

    while move_found

        move_found = false
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))
        node_pairs = collect(Combinatorics.combinations(1:length(solution), 2))

        # intra moves
        for indices in node_pairs
            # forward search
            move = "intra_forward"
            nodes = [best_solution[indices[1]], best_solution[indices[2]]]
            nodes_intra = [best_solution[mod(indices[1], n)+1], best_solution[mod(indices[2], n)+1]]

            if !haskey(LM_dict, (nodes, nodes_intra, move))
            # exists_pattern = any(x -> x[2:end] == (nodes, nodes_intra, move), LM)
            # if !exists_pattern
                _, delta = generate_intra_route_move(best_solution, distance_matrix, indices, mode)
                if delta < 0 # brings improvement
                    LM_dict[(nodes, nodes_intra, move)] = delta
                    # push!(LM, (delta, nodes, nodes_intra, move)) # operate on nodes
                end
            end

            # backward search
            move = "intra_backward"
            nodes = [best_solution[indices[1]], best_solution[indices[2]]]
            nodes_intra = [best_solution[mod(indices[1]-2, n)+1], best_solution[mod(indices[2]-2, n)+1]]
            if !haskey(LM_dict, (nodes, nodes_intra, move))
            # exists_pattern = any(x -> x[2:end] == (nodes, nodes_intra, move), LM)
            # if !exists_pattern
                _, delta = generate_intra_route_move(best_solution, distance_matrix, indices, mode, true)
                if delta < 0 # brings improvement
                    LM_dict[(nodes, nodes_intra, move)] = delta
                    # push!(LM, (delta, nodes, nodes_intra, move)) # operate on nodes
                end
            end

        end

        # inter moves
        candidate_idx_pairs = vec(collect(Iterators.product(unvisited, 1:length(best_solution))))
        for pair in candidate_idx_pairs
            move = "inter"
            nodes = [pair[1], best_solution[pair[2]]]
            if !haskey(LM_dict, (nodes, [], move))
            # exists_pattern = any(x -> x[2:end] == (nodes, [], move), LM)
            # if !exists_pattern
                _, delta = generate_inter_route_move(
                    best_solution,
                    distance_matrix,
                    cost_vector,
                    pair[1],
                    pair[2],
                )
                if delta < 0 # brings improvement
                    LM_dict[(nodes, [], move)] = delta
                    # push!(LM, (delta, nodes, [], move)) # operate on nodes
                end
            end
        end

        sorted_keys = sort(collect(keys(LM_dict)), by = x -> LM_dict[x])
        for key in sorted_keys
            applicable, stored = is_applicable_is_stored(best_solution, key)

            if applicable
                move_found = true
                best_solution = apply_move(best_solution, key, distance_matrix, cost_vector, mode)
            end

            if !stored
                delete!(LM_dict, key)
                # splice!(LM_array, i) # remove move if is not to be stored
            end

            if move_found
                break
            end
        end
        # LM = SortedSet(LM_array)
        println("best cost:", evaluate_solution(best_solution, distance_matrix, cost_vector))
    end
    println("LOCAL MINIMUM REACHED")
    return best_solution
end