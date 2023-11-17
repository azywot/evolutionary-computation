using DataStructures

include("./local_greedy_search.jl")


"""
Evaluate an intra cross EDGE move.
- `solution::Vector{Int}`: solution
- `dm::Matrix{Int}`: matrix of distances between nodes
- `indices::Vector{Int}`: indices of nodes to be swapped (either the nodes or its edges)

returns: delta of the move
"""
function evaluate_intra_cross_move(solution, dm, indices)
    n = length(solution)
    sol = deepcopy(solution)
    i, j = indices[1], indices[2]

    # if nodes are already connected by edge
    if mod(i + 1, n) == mod(j, n) || mod(j + 1, n) == mod(i, n)
        return 0
    end

    plus = dm[sol[i], sol[mod(j, n)+1]] + dm[sol[j], sol[mod(i, n)+1]]
    minus = dm[sol[i], sol[mod(i, n)+1]] + dm[sol[j], sol[mod(j, n)+1]]

    return plus - minus # delta
end



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

    order_preserved = pos_1 + 1 == pos_2
    edge_exists = order_preserved || pos_2 + 1 == pos_1
    return edge_exists, order_preserved
end

function applicable_stored(edge1, edge2, order1, order2)
    if edge1 && edge2
        if !xor(order1, order2)
            return true, false # applicable, not stored
        else
            return false, true # not applicable, stored
        end
    end
    return false, false # not applicable, not stored
end


"""
State whether the solution is applicable to the move.
- `solution::Vector{Int}`: solution
- `move_tuple::Tuple`: move tuple

returns: true if applicable, false otherwise
returns: true if is to be stored, false otherwise
"""
function is_applicable_is_stored(solution, move_tuple)
    nodes, temp, move = move_tuple

    # inter move
    if move == "inter"
        new_node, old_node = nodes
        if !(new_node in solution) && old_node in solution
            node_from, node_to = temp
            edge1 = [node_from, old_node]
            edge2 = [old_node, node_to]
            edge_exists1, order_preserved1 = edge_exists_order_preserved(edge1, solution)
            edge_exists2, order_preserved2 = edge_exists_order_preserved(edge2, solution)
            return applicable_stored(
                edge_exists1,
                edge_exists2,
                order_preserved1,
                order_preserved2,
            )
        end
        return false, false # not applicable, not stored
    end

    # intra move
    edge1, edge2 = [], []
    nodes_intra = temp
    if move == "intra_forward"
        edge1 = [nodes[1], nodes_intra[1]]
        edge2 = [nodes[2], nodes_intra[2]]
    # elseif move == "intra_backward"
    #     edge1 = [nodes_intra[1], nodes[1]]
    #     edge2 = [nodes_intra[2], nodes[2]]
    end

    edge_exists1, order_preserved1 = edge_exists_order_preserved(edge1, solution)
    edge_exists2, order_preserved2 = edge_exists_order_preserved(edge2, solution)
    return applicable_stored(edge_exists1, edge_exists2, order_preserved1, order_preserved2)
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

    # elseif move == "intra_backward"
    #     node1_index = findfirst(==(nodes[1]), solution)
    #     node2_index = findfirst(==(nodes[2]), solution)
    #     new_solution, _ = generate_intra_route_move(
    #         solution,
    #         distance_matrix,
    #         [node1_index, node2_index],
    #         mode,
    #         true, # backward
    #     )
    #     return new_solution

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
    LM_pq = PriorityQueue{Tuple{Vector{Int64},Vector{Int64},String},Float64}()
    # Priority Queue{(nodes, nodes_intra, move) delta} it is auto sorted by delta
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
            nodes_succ =
                [best_solution[mod(indices[1], n)+1], best_solution[mod(indices[2], n)+1]]

            if !((nodes, nodes_succ, move) in keys(LM_pq))
                _, delta =
                    generate_intra_route_move(best_solution, distance_matrix, indices, mode)
                if delta < 0 # brings improvement
                    enqueue!(LM_pq, (nodes, nodes_succ, move), delta)
                end
            end

            # cross move
            # NOTE: we leave "intra_move" to somehow perform the move once applicable
            nodes = [best_solution[indices[1]], best_solution[indices[2]]]
            nodes_succ =
                [best_solution[mod(indices[2], n)+1], best_solution[mod(indices[1], n)+1]]
            if !((nodes, nodes_succ, move) in keys(LM_pq))
                delta = evaluate_intra_cross_move(best_solution, distance_matrix, indices)
                if delta < 0 # brings improvement
                    enqueue!(LM_pq, (nodes, nodes_succ, move), delta)
                end
            end
        end

        # inter moves
        candidate_idx_pairs =
            vec(collect(Iterators.product(unvisited, 1:length(best_solution))))
        for pair in candidate_idx_pairs
            move = "inter"
            nodes = [pair[1], best_solution[pair[2]]]
            nodes_from_to =
                [best_solution[mod(pair[2] - 2, n)+1], best_solution[mod(pair[2], n)+1]]
            if !((nodes, nodes_from_to, move) in keys(LM_pq))
                _, delta = generate_inter_route_move(
                    best_solution,
                    distance_matrix,
                    cost_vector,
                    pair[1],
                    pair[2],
                )
                if delta < 0 # brings improvement
                    enqueue!(LM_pq, (nodes, nodes_from_to, move), delta)
                end
            end
        end

        for move_tuple in keys(LM_pq)
            applicable, stored = is_applicable_is_stored(best_solution, move_tuple)

            if applicable
                move_found = true
                best_solution = apply_move(
                    best_solution,
                    move_tuple,
                    distance_matrix,
                    cost_vector,
                    mode,
                )
            end

            if !stored
                delete!(LM_pq, move_tuple)
            end

            if move_found
                break
            end
        end
        println("best cost:", evaluate_solution(best_solution, distance_matrix, cost_vector))
        println("LM size: ", length(LM_pq))
    end
    println("LOCAL MINIMUM REACHED")
    return best_solution
end
